//
//  CWFDataSource.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/5/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation
import UIKit

class CWFCallingManagerService: DataSourceInjected, LdsOrgApiInjected, LdscdApiInjected {
    
    var ldsOrgUnit: Org? = nil
    var appDataOrg: Org? = nil
    private(set) var memberList: [Member] = []
    var appConfig: AppConfig = AppConfig() {
        didSet {
            self.ldsOrgApi.setAppConfig(appConfig: self.appConfig )
        }
    }
    var positionMetadataMap : [Int:PositionMetadata] = [:]
    
    // implied ldscdApi  comes from LdscdApiInjected
    // implied ldsOrgApi  comes from LdsOrgApiInjected
    // implied dataSource  comes from DataSourceInjected
    
    var memberCallings : [MemberCallings] {
        get {
            return memberList.map() {
                 MemberCallings(member: $0, callings: memberCallingsMap.getValues(forKey: $0.individualId), proposedCallings: memberPotentialCallingsMap.getValues(forKey: $0.individualId))
            }
        }
    }
    
    /// These are orgs that are in the app data store (goodrive) but not in lds.org. They likely need to be deleted, but may contain changes that the user will need to discard or merge to another org
    private var extraAppOrgs: [Org] = []
    
    /// Map of root level orgs in the current unit by their ID
    private var ldsUnitOrgsMap: [Int64: Org] = [:]
    
    /// Map of callings by member
    private var memberCallingsMap = MultiValueDictionary<Int64, Calling>()
    private var memberPotentialCallingsMap = MultiValueDictionary<Int64, Calling>()
    
    private var unitLevelOrgsForSubOrgs: [Int64: Int64] = [:]
    
    private let jsonFileReader = JSONFileReader()
    
    let permissionMgr : PermissionManager
    
    public private(set) var userRoles : [UnitRole] = []
    
    var statusToExcludeForUnit : [CallingStatus] = []
    
    
    init() {
        permissionMgr = PermissionManager()
    }
    
    init(org: Org?, iMemberArray: [Member], permissionMgr: PermissionManager) {
        self.ldsOrgUnit = org
        self.memberList = iMemberArray
        self.permissionMgr = permissionMgr
    }
    
    /** Loads metadata about the different positions from the local filesystem. Eventually we'll want to enhance this so there is a companion method to load it remotely as well (at a time interval). We don't want to slow down startup, so we just read locally and after startup we can periodically check for any updates */
    private func loadLocalPositionMetadata() {
        let positionsMD = PositionMetadata.positionArrays(fromJSONArray: jsonFileReader.getJSONArray( fromFile: "position-metadata" ) )
        positionMetadataMap = positionsMD.toDictionaryById( {$0.positionTypeId} )
    }
    
    public func getLdsUser( username: String, password: String, completionHandler: @escaping (LdsUser?, Error?) -> Void ) {
        
        
            let ldsApi = self.ldsOrgApi
            ldsApi.ldsSignin(username: username, password: password, { (error) -> Void in
                if error != nil {
                    print(error!)
                } else {
                    ldsApi.getCurrentUser() { (ldsUser, error) -> Void in
                        
                        guard error == nil, let _ = ldsUser else {
                            let errorMsg = "Error getting LDS User details: " + error.debugDescription
                            print( errorMsg )
                            completionHandler(nil, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
                            return
                        }
                        completionHandler( ldsUser, nil )
                    }
                }
            })
    }
    
    public func getUnits( forUser user: LdsUser ) -> [Int64] {
        return permissionMgr.authorizedUnits(forUser: user)
    }
    

    
    /** Performs the calls that need to be made to lds.org at startup, or unit transition. First it gets the application config from our servers (which contains the lds.org endpoints to use). Next it logs in to lds.org, then it retrieves user data which includes their callings (to verify unit permissions), the unit member list and callings. Once all those have completed then we call the callback. If any one of them fails we will return an error via the callback. The data is not returned via the callback, it is just maintained internally in this class. The callback just lets the calling function know that this method has successfully completed.
     
     This method needs to be called prior to calling the authenticate() or loadAppData() methods */
    public func loadLdsData(forUnit unitNum: Int64, ldsUser: LdsUser, completionHandler: @escaping (Bool, Error?) -> Void) {
        var members : [Member] = []
        var ldsOrg : Org? = nil
        loadLocalPositionMetadata()

        self.userRoles = self.permissionMgr.createUserRoles(forPositions: ldsUser.positions, inUnit: unitNum)
        
        if self.permissionMgr.hasPermission(unitRoles: self.userRoles, domain: .OrgInfo, permission: .View) {
            let ldsApi = self.ldsOrgApi
            var ldsApiError: Error? = nil
            let restCallsGroup = DispatchGroup()
            
            restCallsGroup.enter()
            ldsApi.getMemberList(unitNum: unitNum) { (memberList, error) -> Void in
                if memberList != nil && !memberList!.isEmpty {
                    members = memberList!
                } else {
                    if error != nil {
                        ldsApiError = error
                    }
                }
                restCallsGroup.leave()
            }
            
            restCallsGroup.enter()
            ldsApi.getOrgWithCallings(unitNum: unitNum) { (org, error) -> Void in
                if let validOrg = org, !validOrg.children.isEmpty {
                    ldsOrg = validOrg
                } else {
                    print("no org")
                    if error != nil {
                        ldsApiError = error
                    }
                }
                restCallsGroup.leave()
            }
            
            restCallsGroup.notify(queue: DispatchQueue.main) {
                if let validOrg = ldsOrg {
                    self.initLdsOrgData(memberList: members, org: validOrg, positionMetadata: self.positionMetadataMap)
                }
                // once all the calls have returned then call the callback
                completionHandler(ldsApiError == nil, ldsApiError)
            }
        } else {
            let errorMsg = "No app permissions for user: " + ldsUser.description
            print( errorMsg )
            completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notAuthorized, userInfo: ["error": errorMsg]))
        }
    }
    
    func initLdsOrgData( memberList : [Member], org : Org, positionMetadata : [Int:PositionMetadata] ) {
        var org = org
        org = org.updatedWith(positionMetadata: positionMetadata)
        // remove any orgs that we don't recognize (i.e. Full Time Missionaries - orgTypeId = -5)
        org.children = org.children.filter() { UnitLevelOrgType( rawValue:  $0.orgTypeId ) != nil }
        // need to put in dictionary by root level org for updating
        self.ldsUnitOrgsMap.removeAll()
        self.ldsUnitOrgsMap = org.children.toDictionaryById() { $0.id }
        self.ldsOrgUnit = org
        let includeChildren = false // for now we always exclude children. If we ever want to make that optional behavior we just need to push this up and expose it as a param
        self.memberList = memberList
            .filter() {
                // filter out any that are not valid members, or if we're limiting by age if they have an age then it must be greater than the min allowed. If there's not an age we include them (err on the side of caution)
                $0.individualId > 0 && (includeChildren || $0.age == nil || $0.age! >= MemberConstants.minimumAge)
        }
    }
    
    /** Authenticate with the application's data source (currently google drive). We need to pass in the current view controller because if the user isn't already authenticated the google API will display a login screen for the user to authenticate. This should always be called before calling loadAppData() */
    public func hasDataSourceCredentials( forUnit unitNum: Int64, completionHandler: @escaping (Bool, Error?) -> Void ) {
        dataSource.hasValidCredentials(forUnit: unitNum, completionHandler: completionHandler)
    }
    
    /** Reads all the unit data from the application data store (currently google drive), and also reconciles any difference between data previously retrieved from lds.org. This method should only be called after loadLDSData() & authorizeDataSource() have successfully completed. The data is not returned in the callback, it is just maintained within this service. The callback just indicates to the calling function when this method has succesfully completed.
     The parameters for the callback indicate if all the data was loaded successfully, and whether there were extra orgs in the application data that were not in the lds.org data that potentially need to be removed or merged. This would be rare, but in cases where there were multiple EQ or RS groups, and then one gets removed in LCR we would still have the extra in our application data store*/
    public func loadAppData( ldsUnit: Org, completionHandler: @escaping(_ success: Bool, _ hasExtraOrgs: Bool, _ error : Error?) -> Void) {
        
        var org = Org(id: ldsUnit.id, unitNum: ldsUnit.unitNum, orgTypeId: ldsUnit.orgTypeId, orgName: ldsUnit.orgName, displayOrder: ldsUnit.displayOrder, children: [], callings: [])
        dataSource.initializeDrive(forOrgs: ldsOrgUnit!.children) { orgsToCreate, extraAppOrgs, error in
            
            if orgsToCreate.isNotEmpty {
                self.dataSource.createFiles( forOrgs: orgsToCreate ) { success, errors in
                    if success {
                        self.loadAppData(ldsUnit: ldsUnit, completionHandler: { success, extraOrgs, error in
                            completionHandler( success, extraOrgs, error )
                        })
                    } else {
                        let error : Error? = errors.isNotEmpty ? errors[0] : nil
                        completionHandler( false, false, error )
                    }                    
                }
            }
            
            let dataSourceGroup = DispatchGroup()
            
            var mergedOrgs: [Org] = []
            for ldsOrg in ldsUnit.children {
                dataSourceGroup.enter()
                self.getOrgData(forOrgId: ldsOrg.id) { org, error in
                    dataSourceGroup.leave()
                    
                    guard org != nil else {
                        print( error.debugDescription )
                        return // exits the callback, not loadAppData
                    }
                    var mergedOrg = self.reconcileOrg(appOrg: org!, ldsOrg: ldsOrg)
                    // if there have been changes write them back to google drive
                    if mergedOrg.hasUnsavedChanges {
                        self.dataSource.updateOrg(org: mergedOrg, completionHandler: { _,_ in
                            /* do nothing - for now.
                             Eventually we probably want to prompt the user to retry - but how????
                             */
                        })
                    }
                    mergedOrg.hasUnsavedChanges = false
                    mergedOrgs.append(mergedOrg)
                }
            }
            
            dataSourceGroup.notify(queue: DispatchQueue.main) {
                // sort all the unit level orgs by their display order
                org.children = mergedOrgs
                self.initDatasourceData(fromOrg: org, extraOrgs: extraAppOrgs)
                completionHandler(error == nil, extraAppOrgs.isNotEmpty, error)
            }
        }
    }
    
    func initDatasourceData( fromOrg org: Org, extraOrgs: [Org] ) {
        self.appDataOrg = org
        self.appDataOrg!.children = org.children.sorted(by: Org.sortByDisplayOrder)
        // add all the child suborgs to a dictionary for lookup by ID
        for childOrg in org.children {
            var subOrgsMap = childOrg.allSubOrgs.toDictionary({ subOrg in
                return (subOrg.id, childOrg.id)
            })
            // need to add the actual owning org as well, just so we don't have to do special case handling later if the calling is directly on a root org (i.e. bishopric calling)
            subOrgsMap[childOrg.id] = childOrg.id
            self.unitLevelOrgsForSubOrgs = self.unitLevelOrgsForSubOrgs.merged(withDictionary: subOrgsMap)
        }

        // this is only actual callings.
        self.memberCallingsMap = self.multiValueDictionaryFromArray(array: org.allOrgCallings) { $0.existingIndId }
        // Now proposed callings
        self.memberPotentialCallingsMap = self.multiValueDictionaryFromArray(array: org.allOrgCallings) { $0.proposedIndId }
        self.extraAppOrgs = extraOrgs
        
    }
    
    func loadUnitSettings( forUnitNum unitNum: Int64, completionHandler: @escaping( UnitSettings?, Error?) -> Void ) {
        dataSource.getUnitSettings(forUnitNum: unitNum) { unitSettings, error in
            if let settings = unitSettings {
                self.statusToExcludeForUnit = settings.disabledStatuses
            }
            completionHandler( unitSettings, error )
        }
    }
    
    func updateUnitSettings( unitSettings: UnitSettings, completionHandler: @escaping( Bool, Error? ) -> Void ) {
        self.statusToExcludeForUnit = unitSettings.disabledStatuses
        dataSource.updateUnitSettings(unitSettings, completionHandler: completionHandler)
    }
    
    /** Reads the given Org from google drive and calls the callback with the org converted from JSON */
    public func getOrgData(forOrgId orgId: Int64, completionHandler: @escaping (Org?, Error?) -> Void) {
        if let ldsOrg = self.ldsUnitOrgsMap[orgId], let orgType = UnitLevelOrgType(rawValue: ldsOrg.orgTypeId) {
            let orgAuth = AuthorizableOrg(unitNum: ldsOrg.unitNum, unitLevelOrgId:ldsOrg.id , unitLevelOrgType: orgType, orgTypeId: ldsOrg.orgTypeId)
            guard permissionMgr.isAuthorized(unitRoles: userRoles, domain: .OrgInfo, permission: .View, targetData: orgAuth ) else  {
                completionHandler(ldsOrg, nil)
                return
            }
            
            dataSource.getData(forOrg: ldsOrg) { org, error in
                if error != nil {
                    completionHandler(nil, error)
                } else if org == nil {
                    let errorMsg = "Error: No Org data found for ID: \(orgId)"
                    completionHandler(nil, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
                } else {
                    // todo - need to strip out any org exceptions
                    let mergedOrg = self.reconcileOrg(appOrg: org!, ldsOrg: ldsOrg).updatedWith(positionMetadata: self.positionMetadataMap)
                    completionHandler(mergedOrg, nil)
                }
            }
            
        } else {
            let errorMsg = "Error: No Org with ID: \(orgId)"
            completionHandler(nil, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
        }
    }
    
    /** Takes an org from the application data source (currently google drive) and compares it to an org coming from lds.org (currently LCR) and reconciles any differences between the two. The lds.org version is authoritative, so we generally modify the application version to match that. But we try to be smart about it so if we have an actual calling from LCR for a CTR7 teacher without a match in google drive, we would check to see if we have a potential calling in google drive for that same calling and individual (basically it was started in the app, but then recorded officially directly in LCR). If there's a match we update the potential with the actual.
     
     As a general rule if there is an outstanding change that appears to be finalized in the LDS version, we don't delete, we mark it so the user can confirm deletion. The one pseudo-exception is a case where a calling had a potential change in the app, and then the LDS version has that change finalized. In that case we had an existing ID from LCR so we know it is a match and we don't really delete a record, we just remove the potential details. In other cases where there was a potential being considered (but didn't have an ID from LCR), and then in the LDS version it has been finalized we just mark the potential for the user to confirm.
     
     We follow a similar pattern with orgs, if the org is in the app but no loner in the LDS data we mark it for the user to confirm. If an org is in the LDS data and not in the app, we just add it.   */
    func reconcileOrg(appOrg: Org, ldsOrg: Org) -> Org {
        var updatedOrg = appOrg
        
        let appOrgIds = Set<Int64>(appOrg.children.map( { $0.id } ))
        let ldsOrgIds = Set<Int64>(ldsOrg.children.map( { $0.id } ))
        
        // get the IDs that are only in the app, no longer in LCR. These need to be marked for deletion
        let appUniqueIds = appOrgIds.subtracting( ldsOrgIds )
        // get the IDs that are only in LCR, these will need to be added to the app data
        let ldsUniqueIds = ldsOrgIds.subtracting( appOrgIds )
        var updatedChildren : [Org] = []
        for appOrgChild in appOrg.children {
            // if the child org is in the list of app only children, then it no longer exists in LCR, so we need to mark it as a conflict that should be removed
            if appUniqueIds.contains( appOrgChild.id ) {
                var updatedChild = appOrgChild
                updatedChild.conflict = .LdsEquivalentDeleted
                updatedChildren.append( updatedChild )
                updatedOrg.hasUnsavedChanges = true
            } else {
                // otherwise, it exists in both places, so we recursively call to reconcile the child orgs
                let reconciledChildOrg = reconcileOrg(appOrg: appOrgChild, ldsOrg: ldsOrg.getChildOrg(id: appOrgChild.id)! )
                updatedChildren.append( reconciledChildOrg )
                
                // if we've already marked that there are changes to this org then we don't want to overwrite that with false from a child that didn't change, so if it's already marked for this org we use that, if not we'll look to the child to see if it's changed
                updatedOrg.hasUnsavedChanges = updatedOrg.hasUnsavedChanges || reconciledChildOrg.hasUnsavedChanges
            }
        }
        
        // if it's only in the lds org structure it's a new org that needs to be added to the app
        for ldsOrgChildId in ldsUniqueIds {
            if let ldsOrgChild = ldsOrg.getChildOrg(id: ldsOrgChildId) {
                updatedChildren.append( ldsOrgChild )
                updatedOrg.hasUnsavedChanges = true
            }
        }
        // sort the child orgs by display order
        updatedOrg.children = updatedChildren.sorted(by: Org.sortByDisplayOrder)
        
        // now reconcile the callings in the current org
        updatedOrg = reconcileCallings(inSubOrg: updatedOrg, ldsOrgVersion: ldsOrg)
        
        // sort any callings in the org by display order
        updatedOrg.callings = updatedOrg.callings.sorted(by: Calling.sortByDisplayOrder)
        
        return updatedOrg
        
    }
    
    /**Takes an org from the app data source (currently google drive) and compares the callings in it to the callings in an org from LCR to look for any differences. LCR is the authoritative source so we're mostly looking to make the app data match it, but we try to do it smartly where we looking for corresponding proposed changes that might match actual changes, and either automatically update the proposed data, or if we're not sure if something in the app data should be removed we mark it as being in conflict so it can be displayed to the user and resolved by them */
    private func reconcileCallings(inSubOrg appOrg: Org, ldsOrgVersion ldsOrg: Org) -> Org {
        // we could take and return [Calling] as params and return objects, but we also need to indicate if there were any changes that were made (currently stored in org.hasUnsavedChanges). That would require we return a tuple of (Bool, [Calling]), so rather than do that we'll stick with the Org object as the params & return type
        var updatedOrg = appOrg
        let appCallingsById = updatedOrg.callings.toDictionaryById() { $0.id }
        let appCallingIds = appCallingsById.keys
        
        let ldsOrgCallingsById = ldsOrg.callings.toDictionaryById() { $0.id }
        let ldsOrgCallingIds = ldsOrgCallingsById.keys
        
        
        for (ldsCallingId, ldsCalling) in ldsOrgCallingsById {
            
            // If the ID from lcr is already in our DB then there's nothing that's changed about it (you can't change the person holding the calling without getting a new calling ID). We could have changes from the app (with proposed or notes) but there are no changes on the LDS.org side that would need to be merged in.
            if !appCallingIds.contains(ldsCallingId) {
                // it's not in the app org db so it needs to be added.
                // first check to see if there's a potential calling in the org with same position
                
                // get any callings of the same position type - we already know it's in the same parent org so only thing to check is if the position is the same.
                let matchingPotentialCallings = appOrg.callings.filter() {
                    $0.position == ldsCalling.position
                }
                var mergedProposedIndId : Int64? = nil
                var mergedProposedStatus : CallingStatus? = nil
                var mergedNotes : String? = nil
                
                // xcode warning says this should be a let constant since it never gets changed, but if you make it a let then it won't compile with a "let pattern can't appear nested in already immutable context"
                for var potentialCalling in matchingPotentialCallings {
                    // if we have an exact match - based on position w/o multiples then delete the potential (the actual will be added below when we add new callings from LCR)
                    // todo - review this - may be a better way - detect that nothing has changed so don't delete the google drive version and add the LCR version
                    if potentialCalling == ldsCalling  {
                        // if it's a different person that holds the actual calling, we'll merge the proposed individual into the actual, before we remove the proposed calling. If they do match then we just want to remove the proposed without merging any details
                        if potentialCalling.proposedIndId != ldsCalling.existingIndId {
                            // it's a different person that was proposed, so we'll merge them into the actual
                            mergedProposedIndId = potentialCalling.proposedIndId
                            mergedProposedStatus = potentialCalling.proposedStatus
                            mergedNotes = potentialCalling.notes
                        }
                        updatedOrg = updatedOrg.updatedWith(callingToDelete: potentialCalling) ?? updatedOrg
                        updatedOrg.hasUnsavedChanges = true
                    } else {
                        // we don't have an exact match (probably a case where multiples are allowed)
                        // if any potentials have an indId that matches the new actual then mark it as changed - eventually may delete, but for now we'll leave it for the user to confirm before deleting
                        if potentialCalling.proposedIndId == ldsCalling.existingIndId {
                            var updatedCalling = potentialCalling
                            updatedCalling.conflict = .EquivalentPotentialAndActual
                            updatedOrg = updatedOrg.updatedWith(changedCalling: updatedCalling) ?? updatedOrg
                            updatedOrg.hasUnsavedChanges = true
                        }
                    }
                }
                
                // Now need to add the existing calling from LCR
                if let ldsCallingOrg = ldsCalling.parentOrg, let appCallingOrg = appOrg.id == ldsCallingOrg.id ? appOrg : appOrg.getChildOrg(id: ldsCallingOrg.id) {
                    let callingFromLcr = Calling(id: ldsCalling.id, cwfId: nil, existingIndId: ldsCalling.existingIndId, existingStatus: .Active, activeDate: ldsCalling.activeDate, proposedIndId: mergedProposedIndId, status: mergedProposedStatus, position: ldsCalling.position, notes: mergedNotes, parentOrg: appCallingOrg)
                    updatedOrg = updatedOrg.updatedWith(newCalling: callingFromLcr) ?? updatedOrg
                    updatedOrg.hasUnsavedChanges = true
                }
            }
        }
        
        // we've addressed any differences between callings that exist in LCR but weren't up to date in the app. Now we need to look for any that are still in the app but aren't in LCR. For this step we only care about callings with actual ID's (that means they were at one point in LCR, but are no longer). Any callings in the app without an ID are just proposed callings that shouldn't exist in LCR yet, so we ignore those
        let callingIDsToRemove = Set(appCallingIds).subtracting(Set(ldsOrgCallingIds))
        for callingId in callingIDsToRemove {
            if var appCallingNotInLcr = appCallingsById[callingId] {
                if let mergedCalling = updatedOrg.getCalling( appCallingNotInLcr ) {
                    // if multiples allowed, then mark for deletion (it used to be in LCR, but no longer is there). We'll let the user confirm that the position should be removed
                    if mergedCalling.position.multiplesAllowed  {
                        appCallingNotInLcr.conflict = .LdsEquivalentDeleted
                        updatedOrg = updatedOrg.updatedWith(changedCalling: appCallingNotInLcr) ?? updatedOrg
                        updatedOrg.hasUnsavedChanges = true
                    } else {
                        // The calling is no longer in LCR (but the position likely is, could be empty because it was released outside the app, or could have a new ID if there was a change recorded in LCR outside the app). If the LCR version of the calling has an ID, then we've already merged it above, we don't want to do anything else. But if there is no id that means we haven't processed it yet, we need to update what's in the app data (google drive) with the released calling in LCR, while maintaining any proposed data
                        if let lcrOriginalCalling = ldsOrg.getCalling( appCallingNotInLcr ), lcrOriginalCalling.id == nil {
                            let releasedLcrCalling = mergeCallingData(fromActualCalling: lcrOriginalCalling, andProposedCalling: appCallingNotInLcr)
                            updatedOrg = updatedOrg.updatedWith(changedCalling: releasedLcrCalling) ?? updatedOrg
                            updatedOrg.hasUnsavedChanges = true
                        }
                    }
                }
                // if it's not in the updatedOrg, then nothing to worry about, nothing to remove
            }
        }
        // We're currently not handling (very well) empty callings. Adam and I discussed and agreed on we're going to add another flag to a calling "cwfOnly" or similar that indicates if a calling was created in the app vs. in LCR. Then we just match up numbers of empty callings between LCR and the app. This still needs to be coded for here
        
        return updatedOrg
    }
    
    /** 
     utility method to combine existing calling data and proposed calling data into a single calling object
     */
    private func mergeCallingData( fromActualCalling existingCalling: Calling, andProposedCalling proposedCalling: Calling ) -> Calling {
        return Calling(id: existingCalling.id, cwfId: nil, existingIndId: existingCalling.existingIndId, existingStatus: .Active, activeDate: existingCalling.activeDate, proposedIndId: proposedCalling.proposedIndId, status: proposedCalling.proposedStatus, position: existingCalling.position, notes: proposedCalling.notes, parentOrg: existingCalling.parentOrg)
        
    }
    
    /** Creates a MultiValueDictionary (a dictionary where each key maps to an array of values, rather than a single element) from an array. It takes a transforming function that returns what the key for the element should be. It puts all the elements in the dictionary, if there are duplicate entries for a given key they will all be added to the array value for the key */
    func multiValueDictionaryFromArray<T, K>(array: [T], transformer: (_: T) -> K?)
        -> MultiValueDictionary<K, T> {
            var map = MultiValueDictionary<K, T>()
            for element in array {
                if let key = transformer(element) {
                    map.addValue(forKey: key, value: element)
                }
            }
            return map
    }
    
    // MARK: - Get Callings/Member data
    // Used to get a member from the memberlist by memberId
    func getMemberWithId(memberId: Int64) -> Member? {
        var member: Member? = nil
        for currentMember in memberList {
            if currentMember.individualId == memberId {
                member = currentMember
            }
        }
        return member
    }
    
    func getMemberCallings( forMemberId memberId: Int64 ) -> MemberCallings? {
        var memberCallings : MemberCallings? = nil
        if let member = getMemberWithId(memberId: memberId) {
            memberCallings = MemberCallings(member: member, callings: getCallings(forMember: member), proposedCallings: getPotentialCallings(forMember: member))
        }
        return memberCallings
    }
    
    func getCallings(forMember member: Member) -> [Calling] {
        return self.memberCallingsMap.getValues(forKey: member.individualId)
    }
    
    func getPotentialCallings( forMember member: Member ) -> [Calling] {
        return self.memberPotentialCallingsMap.getValues(forKey: member.individualId)
    }
    
    //MARK: - Update/Add Calling in app data store
    
    /** Adds a potential calling in the app's data store */
    public func addCalling(calling: Calling, completionHandler: @escaping(Bool, Error?) -> Void) {
        self.storeCallingChange(changedCalling: calling, operation: .Create, completionHandler: completionHandler)
    }
    
    /** deletes a potential calling in the app's data store */
    public func deleteCalling(calling: Calling, completionHandler: @escaping(Bool, Error?) -> Void) {
        self.storeCallingChange(changedCalling: calling, operation: .Delete, completionHandler: completionHandler)
    }
    
    /** updates a potential calling in the app's data store */
    public func updateCalling(updatedCalling: Calling, completionHandler: @escaping (Bool, Error?) -> Void) {
        self.storeCallingChange(changedCalling: updatedCalling, operation: .Update, completionHandler: completionHandler)
    }
    
    public func releaseCalling(updatedCalling: Calling, completionHandler: @escaping (Bool, Error?) -> Void) {
        // this should be the calling before it's released (still contains the positionId and the existing ind id so we can successfully identify it in the org structure)
        self.storeCallingChange(changedCalling: updatedCalling, operation: .Release, completionHandler: completionHandler)
    }
    
    //MARK: - LCR API Calls
    
    public func updateLCRCalling( updatedCalling: Calling, completionHandler: @escaping(Calling?, Error?) -> Void ) {
        guard let unitNum = updatedCalling.parentOrg?.unitNum, let newIndId = updatedCalling.proposedIndId else {
            let errorMsg = "Error: calling didn't have a parent org, or there was not proposed calling"
            print( errorMsg )
            completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        
        self.ldsOrgApi.updateCalling(unitNum: unitNum, calling: updatedCalling, newMemberIndId: newIndId) { callingFromLcr, error in
            // this can return errors based on the individual (if they don't meet requirements) - check for it here. May need to handle it deeper down - there's explanation in the JSON, can we make sense of that here?
            guard error == nil, let validCallingFromLcr = callingFromLcr else {
                completionHandler( callingFromLcr, error )
                return
            }
            
            // If it's a position where duplicates are not allowed (i.e. Primary Pres.) then they will evaluate as == regardless of the ID's being different, so we can just do an update.
            if updatedCalling == validCallingFromLcr {
                self.updateCalling(updatedCalling: validCallingFromLcr) { success, error in
                    completionHandler( validCallingFromLcr, nil )
                }
            } else {
                // this is a situation where we have duplicates allowed (i.e. a primary teacher) so we need to release/add
                // todo - would be better to eventually combine this into a single update operation, but would need an update method that takes original & updated calling to be able to support changing in one operation
                self.deleteCalling(calling: updatedCalling) { success, error in
                    // todo - what if we get an error at this point?? Can't really roll back
                    self.addCalling(calling: validCallingFromLcr) { success, error in
                        completionHandler( validCallingFromLcr, nil )
                        
                    }
                    
                }
            }
            
        }
    }

    public func releaseLCRCalling( callingToRelease: Calling, completionHandler: @escaping(Bool, Error?) -> Void ) {
        guard let unitNum = callingToRelease.parentOrg?.unitNum else {
            let errorMsg = "Error: calling didn't have a parent org"
            print( errorMsg )
            completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        
        self.ldsOrgApi.releaseCalling(unitNum: unitNum, calling: callingToRelease ) { success, error in
            guard error == nil, success == true else {
                print( "Error trying to release calling in LCR: " + error.debugDescription )
                completionHandler( success, error )
                return
            }
            
            self.releaseCalling(updatedCalling: callingToRelease ) { success, error in
                print( "Successfully released: " + (callingToRelease.position.name?.description ?? "" ))
                completionHandler( success, error )
            }
        }
    }

    public func deleteLCRCalling( callingToDelete: Calling, completionHandler: @escaping(Bool, Error?) -> Void ) {
        guard let unitNum = callingToDelete.parentOrg?.unitNum else {
            let errorMsg = "Error: calling didn't have a parent org"
            print( errorMsg )
            completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        
        self.ldsOrgApi.deleteCalling(unitNum: unitNum, calling: callingToDelete) { success, error in
            guard error == nil, success == true else {
                print( "Error trying to delete calling in LCR: " + error.debugDescription )
                completionHandler( success, error )
                return
            }
            
            self.deleteCalling(calling: callingToDelete ) { success, error in
                print( "Successfully deleted: " + (callingToDelete.position.name?.description ?? "" ))
                completionHandler( success, error )
            }
        }
    }

    //MARK: - Cached Data
    
    /** Performs the actual CRUD operations by reading the file for the org that the calling is in from google drive, performing the update, writing the entire org back to google drive, then updating the copy of the data that is cached locally. When this is all done we call the completion handler with the results */
    private func storeCallingChange(changedCalling: Calling, operation: Calling.ChangeOperation, completionHandler: @escaping (Bool, Error?) -> Void) {
        if let callingOrg = changedCalling.parentOrg, let unitLevelOrgId = self.unitLevelOrgsForSubOrgs[callingOrg.id], let unitLevelOrg = appDataOrg?.getChildOrg(id: unitLevelOrgId), let rootOrgType = UnitLevelOrgType(rawValue: unitLevelOrg.orgTypeId) {

            let orgAuth = AuthorizableOrg(fromSubOrg: callingOrg, inUnitLevelOrg: unitLevelOrg)
            
            let perm = getPermission(forCRUDOperation: operation)
            guard permissionMgr.isAuthorized(unitRoles: userRoles, domain: .PotentialCalling, permission: perm, targetData: orgAuth) else {
                let errorMsg = "Error: No Permission to make changes in : \(rootOrgType)"
                completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notAuthorized, userInfo: ["error": errorMsg]))
                return
            }
            
            let originalCalling = appDataOrg?.getCalling( changedCalling )
            // need to update appDataOrg with changes before we make asynch call - so whatever view gets drawn will have the changes

            var shouldRevert = false
            // update the cached copy of the org, as well as the calling maps where we keep track of the callings that individuals hold. We do this before going to google drive because we need the data to be updated in the UI. If we get an error we'll revert
            if let updatedRootOrg = unitLevelOrg.updatedWithCallingChange(updatedCalling: changedCalling, operation: operation) {
                self.appDataOrg!.updateDirectChildOrg(org: updatedRootOrg)
                self.updateProposedCachedCallingData(originalCalling: originalCalling, changedCalling: changedCalling, operation: operation)
                if let originalCalling = originalCalling {
                    self.updateExistingCallingsData(originalCalling: originalCalling, updatedCalling: changedCalling, operation: operation )
                }
                shouldRevert = true
            }
            
            // read the org file fresh from google drive (to make sure we have the latest data before performing the change). This reduces the chance of clobbering another change in the org recorded by another user
            self.getOrgData(forOrgId: unitLevelOrgId) { org, error in
                guard error == nil else {
                    if shouldRevert {
                        self.revertCachedCallingData(unitLevelOrg: unitLevelOrg, originalCalling: originalCalling, changedCalling: changedCalling, originalOperation: operation)
                    }
                    completionHandler(false, error)
                    return
                }
                guard let validOrg = org else {
                    if shouldRevert {
                        self.revertCachedCallingData(unitLevelOrg: unitLevelOrg, originalCalling: originalCalling, changedCalling: changedCalling, originalOperation: operation)
                    }
                    let errorMsg = "Error: No Org data found for ID: \(callingOrg.id)"
                    completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
                    return
                }
                // todo - eventually we'll need to make this a queueing mechanism to handle the case where multiple updates may be called before earlier ones return. For now we're keeping it simple
                if let updatedOrg = validOrg.updatedWithCallingChange(updatedCalling: changedCalling, operation: operation) {
                    self.dataSource.updateOrg(org: updatedOrg) { success, error in
                        
                        // we've already updated with the user change, but this will integrate any changes that have happened by other users outside the app. Not critical, but we have the data so might as well update. This won't change anything in the user's current view, but will show up next time they change a view
                        if success {
                            self.appDataOrg!.updateDirectChildOrg(org: updatedOrg)
                        } else {
                            if shouldRevert {
                                self.revertCachedCallingData(unitLevelOrg: updatedOrg, originalCalling: originalCalling, changedCalling: changedCalling, originalOperation: operation)
                            }

                        }
                        // if it wasn't a success we just propogate the result and any errors on to the callback
                        completionHandler(success, error)
                    }
                } else {
                    // updatedOrg came back nil (either the calling wasn't really in the org, or originalCalling was nil on an update, Shouldn't ever happen).
                    if shouldRevert {
                        self.revertCachedCallingData(unitLevelOrg: unitLevelOrg, originalCalling: originalCalling, changedCalling: changedCalling, originalOperation: operation)
                    }
                    let errorMsg = "Error: Calling data incomplete, unable to update. Calling was not found in org."
                    completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: ["error": errorMsg]))
                }
            }
            

        } else {
            // either there was an error with the calling object (didn't have a parent), or the org data is wrong (i.e. the root org isn't in the dictionary) - shouldn't really happen outside of testing env.
            let errorMsg = "Error: Calling data incomplete, unable to update. Problem with containing org: " + (changedCalling.parentOrg?.id.description ?? " no org")
            completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: ["error": errorMsg]))

        }
    }
    
    func revertCachedCallingData(unitLevelOrg: Org, originalCalling: Calling?, changedCalling: Calling, originalOperation: Calling.ChangeOperation) {
        if self.appDataOrg != nil {
            self.appDataOrg!.updateDirectChildOrg(org: unitLevelOrg)
        }
        // update potential Callings map -  switch on operation. Although we could have a copy of this same calling object in the memberCallingsMap, the only thing we display from that map is the name of the calling and duration, so doesn't matter if any actual details are stale, we never read any potentially stale data from the callings in member callings map.
        
        switch originalOperation {
        case .Create:
            // if it was a create then we need to remove the added calling
            if let newProposedIndId = changedCalling.proposedIndId {
                self.memberPotentialCallingsMap.removeValue(forKey: newProposedIndId, value: changedCalling)
            }
        case .Delete:
            // if it was a delete then need to add the calling back in
            if let newProposedIndId = changedCalling.proposedIndId {
                self.memberPotentialCallingsMap.addValue(forKey: newProposedIndId, value: changedCalling)
            }
        case .Update:
            // the existing ID can't change on any proposed calling changes - we just need to update the cache of the propsed callings with the changes
            if let newProposedIndId = changedCalling.proposedIndId {
                self.memberPotentialCallingsMap.removeValue(forKey: newProposedIndId, value: changedCalling)
            }
            if let oldProposedIndId = originalCalling?.proposedIndId {
                self.memberPotentialCallingsMap.addValue(forKey: oldProposedIndId, value: originalCalling!)
            }
        case .Release:
            // do nothing
            break
        }
        
    }
    
    /** Currently this method just updates the org for the unit with the updated root level org (Primary, EQ, etc.). We don't change the map of actual callings because this is currently just for potential calling changes. The update of actual callings would only be after we've made a change in LCR */
    func updateProposedCachedCallingData(originalCalling: Calling?, changedCalling: Calling, operation: Calling.ChangeOperation) {
        // update potential Callings map -  switch on operation. Although we could have a copy of this same calling object in the memberCallingsMap, the only thing we display from that map is the name of the calling and duration, so doesn't matter if any proposed details are stale, we never read any potentially stale data from the callings in member callings map.
        
        switch operation {
        case .Create:
            // if it's a create there is no existing calling to potetially update, or any old callings that need to be removed, just add it if it has a proposed person
            if let newProposedIndId = changedCalling.proposedIndId {
                self.memberPotentialCallingsMap.addValue(forKey: newProposedIndId, value: changedCalling)
            }
        case .Delete:
            // if it's a delete there is no existing calling to potetially update (if there's an existing calling you have to delete via LCR options, so it will go a different code path),  just remove it from the map if it had a proposed person
            if let newProposedIndId = changedCalling.proposedIndId {
                self.memberPotentialCallingsMap.removeValue(forKey: newProposedIndId, value: changedCalling)
            }
        case .Update:
            // the existing ID can't change on any proposed calling changes - we just need to update the cache of the propsed callings with the changes
            if let oldProposedIndId = originalCalling?.proposedIndId {
                self.memberPotentialCallingsMap.removeValue(forKey: oldProposedIndId, value: originalCalling!)
            }
            if let newProposedIndId = changedCalling.proposedIndId {
                self.memberPotentialCallingsMap.addValue(forKey: newProposedIndId, value: changedCalling)
            }
        case .Release:
            // do nothing - release has no effect on potential callings
            break
        }
        
        // no need to update existing callings - that should only be after we've saved a change in LCR
    }
    
    /** converts a CRUD operation into a permission of the same type */
    private func getPermission( forCRUDOperation crudOp : Calling.ChangeOperation ) -> Permission {
        switch crudOp {
        case .Create:
            return .Create
        case .Update, .Release:
            return .Update
        case .Delete:
            return .Delete
        }
    }
    
    /** Looks up a unit level org by its' ID and returns the type of the org. Returns nil if the org id is not in the list of unit level orgs */
     func unitLevelOrgType( forOrg rootOrgId: Int64 ) -> UnitLevelOrgType? {
        var orgType : UnitLevelOrgType? = nil
        if let rootOrgTypeId = self.ldsUnitOrgsMap[rootOrgId]?.orgTypeId {
            orgType = UnitLevelOrgType(rawValue: rootOrgTypeId)
        }
        return orgType
    }
    
    /** After we've finalized a calling in LCR, we need to update our cached copy of the data */
    func updateExistingCallingsData(originalCalling: Calling, updatedCalling: Calling, operation: Calling.ChangeOperation) {
        switch operation {
        case .Release, .Delete:
            // In case of release/delete we only look at the original - need to remove existing member
            // For release and delete the updatedCalling doesn't have the actual desired changes made to it. In reality for a release or delete the "updated" from the UI would have the member removed and the ID removed, but then we can't successfully match it in the original org. So we leave the updated calling unmodified and just pass in the operation that needs to happen. So that's why we need to process these operations separately from other updates
            if let originalIndId = originalCalling.existingIndId, let originalCallingId = originalCalling.id {
                let memberCallings = self.memberCallingsMap.getValues(forKey: originalIndId)
                self.memberCallingsMap.setValues(forKey: originalIndId, values: memberCallings.filter({ $0.id != originalCallingId }))
            }
        default:
            if originalCalling.existingIndId != updatedCalling.existingIndId {
                
                // remove the calling from the list of callings held by the original member that had the calling
                if let originalIndId = originalCalling.existingIndId, let originalCallingId = originalCalling.id {
                    let memberCallings = self.memberCallingsMap.getValues(forKey: originalIndId)
                    self.memberCallingsMap.setValues(forKey: originalIndId, values: memberCallings.filter({ $0.id != originalCallingId }))
                }
                
                // if someone got a new calling then we need to add the calling to their list
                if let updatedIndId = updatedCalling.existingIndId, let _ = updatedCalling.id {
                    var memberCallings = self.memberCallingsMap.getValues(forKey: updatedIndId)
                    memberCallings.append(updatedCalling)
                    self.memberCallingsMap.setValues(forKey: updatedIndId, values: memberCallings)
                }
            }
        }
    }
    
    func unitLevelOrg( forSubOrg subOrgId: Int64) -> Org? {
        var org : Org? = nil
        if let orgId = unitLevelOrgsForSubOrgs[subOrgId], let rootOrg = ldsUnitOrgsMap[orgId] {
            org = rootOrg
        }
        
        return org
    }
}

