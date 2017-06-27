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
    
    // todo - this should be private once we have all controllers correctly using public methods
    var ldsOrgUnit: Org? = nil
    var appDataOrg: Org? = nil
    private(set) var memberList: [Member] = []
    var appConfig: AppConfig? = nil
    var positionMetadataMap : [Int:PositionMetadata] = [:]
    
    // implied ldscdApi  comes from LdscdApiInjected
    // implied ldsOrgApi  comes from LdsOrgApiInjected
    // implied dataSource  comes from DataSourceInjected
    
    /// These are orgs that are in the app data store (goodrive) but not in lds.org. They likely need to be deleted, but may contain changes that the user will need to discard or merge to another org
    private var extraAppOrgs: [Org] = []
    
    /// Map of root level orgs in the current unit by their ID
    private var ldsUnitOrgsMap: [Int64: Org] = [:]
    
    /// Map of callings by member
    private var memberCallingsMap = MultiValueDictionary<Int64, Calling>()
    private var memberPotentialCallingsMap = MultiValueDictionary<Int64, Calling>()
    
    private var unitLevelOrgsForSubOrgs: [Int64: Int64] = [:]
    
    private let jsonFileReader = JSONFileReader()
    
    private let permissionMgr : PermissionManager
    
    private var userRoles : [UnitRole] = []
    
    
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
        
        ldscdApi.getAppConfig() { (appConfig, error) in
            
            guard appConfig != nil else {
                // todo - change this to just use default app config
                print("No app config")
                let errorMsg = "Error: No Application Config"
                completionHandler(nil, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
                return
            }
            self.ldsOrgApi.setAppConfig(appConfig: appConfig!)
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
                            self.memberList = memberList.filter() {$0.individualId > 0}
        self.ldsOrgUnit = org.updatedWith(positionMetadata: positionMetadata)
        // need to put in dictionary by root level org for updating
        self.ldsUnitOrgsMap.removeAll()
        self.ldsUnitOrgsMap = org.children.toDictionaryById() { $0.id }
    }
    
    /** Authenticate with the application's data source (currently google drive). We need to pass in the current view controller because if the user isn't already authenticated the google API will display a login screen for the user to authenticate. This should always be called before calling loadAppData() */
    public func hasDataSourceCredentials( forUnit unitNum: Int64, completionHandler: @escaping (Bool, Error?) -> Void ) {
        dataSource.hasValidCredentials(forUnit: unitNum, completionHandler: completionHandler)
    }
    
    /** Reads all the unit data from the application data store (currently google drive), and also reconciles any difference between data previously retrieved from lds.org. This method should only be called after loadLDSData() & authorizeDataSource() have successfully completed. The data is not returned in the callback, it is just maintained within this service. The callback just indicates to the calling function when this method has succesfully completed.
     The parameters for the callback indicate if all the data was loaded successfully, and whether there were extra orgs in the application data that were not in the lds.org data that potentially need to be removed or merged. This would be rare, but in cases where there were multiple EQ or RS groups, and then one gets removed in LCR we would still have the extra in our application data store*/
    public func loadAppData( ldsUnit: Org, completionHandler: @escaping(Bool, Bool, Error?) -> Void) {
        
        var org = Org(id: ldsUnit.id, orgTypeId: ldsUnit.orgTypeId, orgName: ldsUnit.orgName, displayOrder: ldsUnit.displayOrder, children: [], callings: [])
        dataSource.initializeDrive(forOrgs: ldsOrgUnit!.children) { extraAppOrgs, error in
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
                    let mergedOrg = self.reconcileOrg(appOrg: org!, ldsOrg: ldsOrg)
                    mergedOrgs.append(mergedOrg)
                    // todo - need to write the org back to goodrive if org.hasUnsavedChanges
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
            let subOrgsMap = childOrg.allSubOrgs.toDictionary({ subOrg in
                return (subOrg.id, childOrg.id)
            })
            self.unitLevelOrgsForSubOrgs = self.unitLevelOrgsForSubOrgs.merged(withDictionary: subOrgsMap)
        }

        // this is only actual callings.
        self.memberCallingsMap = self.multiValueDictionaryFromArray(array: org.allOrgCallings) { $0.existingIndId }
        // Now proposed callings
        self.memberPotentialCallingsMap = self.multiValueDictionaryFromArray(array: org.allOrgCallings) { $0.proposedIndId }
        self.extraAppOrgs = extraOrgs
        
    }
    
    /** Reads the given Org from google drive and calls the callback with the org converted from JSON */
    public func getOrgData(forOrgId orgId: Int64, completionHandler: @escaping (Org?, Error?) -> Void) {
        if let ldsOrg = self.ldsUnitOrgsMap[orgId], let orgType = UnitLevelOrgType(rawValue: ldsOrg.orgTypeId) {
            let orgAuth = AuthorizableOrg(unitNum: self.ldsOrgUnit!.id, unitLevelOrgId:ldsOrg.id , unitLevelOrgType: orgType, orgTypeId: ldsOrg.orgTypeId)
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
        
        // we've addressed any differences between callings that exist in LCR but weren't in the app. Now we need to look for any that are still in the app but aren't in LCR. For this step we only care about callings with actual ID's (that means they were at one point in LCR, but are no longer). Any callings in the app without an ID are just proposed callings that shouldn't exist in LCR yet, so we ignore those
        let callingIDsToRemove = Set(appCallingIds).subtracting(Set(ldsOrgCallingIds))
        for callingId in callingIDsToRemove {
            if var calling = appCallingsById[callingId] {
                calling.conflict = .LdsEquivalentDeleted
                updatedOrg = updatedOrg.updatedWith(changedCalling: calling) ?? updatedOrg
            }
        }
        
        return updatedOrg
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
    
    func getCallings(forMember member: Member) -> [Calling] {
        return self.memberCallingsMap.getValues(forKey: member.individualId)
    }
    
    func getPotentialCallings( forMember member: Member ) -> [Calling] {
        return self.memberPotentialCallingsMap.getValues(forKey: member.individualId)
    }
    
    public func addCalling(calling: Calling, completionHandler: @escaping(Bool, Error?) -> Void) {
        self.storeCallingChange(changedCalling: calling, operation: .Create, completionHandler: completionHandler)
    }
    
    public func deleteCalling(calling: Calling, completionHandler: @escaping(Bool, Error?) -> Void) {
        self.storeCallingChange(changedCalling: calling, operation: .Delete, completionHandler: completionHandler)
    }
    
    public func updateCalling(updatedCalling: Calling, completionHandler: @escaping (Bool, Error?) -> Void) {
        self.storeCallingChange(changedCalling: updatedCalling, operation: .Update, completionHandler: completionHandler)
    }
    
    /** Performs the actual CRUD operations by reading the file for the org that the calling is in from google drive, performing the update, writing the entire org back to google drive, then updating the copy of the data that is cached locally. When this is all done we call the completion handler with the results */
    private func storeCallingChange(changedCalling: Calling, operation: Org.CRUDOperation, completionHandler: @escaping (Bool, Error?) -> Void) {
        // todo - this needs to check for root level org ID (probably include them in the map)
        if let orgId = changedCalling.parentOrg?.id, let unitLevelOrgId = self.unitLevelOrgsForSubOrgs[orgId], let rootOrgType = unitLevelOrgType( forOrg: unitLevelOrgId ) {

            let orgAuth = AuthorizableOrg(unitNum: ldsOrgUnit!.id, unitLevelOrgId: unitLevelOrgId, unitLevelOrgType: rootOrgType, orgTypeId: changedCalling.parentOrg!.orgTypeId)
            let perm = getPermission(forCRUDOperation: operation)
            guard permissionMgr.isAuthorized(unitRoles: userRoles, domain: .PotentialCalling, permission: perm, targetData: orgAuth) else {
                let errorMsg = "Error: No Permission to make changes in : \(rootOrgType)"
                completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notAuthorized, userInfo: ["error": errorMsg]))
                return
            }
            
            let originalCalling = appDataOrg?.getCalling( changedCalling )
            // read the org file fresh from google drive (to make sure we have the latest data before performing the change). This reduces the chance of clobbering another change in the org recorded by another user
            self.getOrgData(forOrgId: unitLevelOrgId) { org, error in
                guard error == nil else {
                    completionHandler(false, error)
                    return
                }
                guard let validOrg = org else {
                    let errorMsg = "Error: No Org data found for ID: \(orgId)"
                    completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
                    return
                }
                // todo - eventually we'll need to make this a queueing mechanism to handle the case where multiple updates may be called before earlier ones return. For now we're keeping it simple
                if let updatedOrg = validOrg.updatedWithCallingChange(updatedCalling: changedCalling, operation: operation) {
                    self.dataSource.updateOrg(org: updatedOrg) { success, error in
                        
                        if success {
                            // update the cached copy of the org, as well as the calling maps where we keep track of the callings that individuals hold
                            self.updateCachedCallingData(unitLevelOrg: updatedOrg, originalCalling: originalCalling, changedCalling: changedCalling, operation: operation)
                        }
                        // if it wasn't a success we just propogate the result and any errors on to the callback
                        completionHandler(success, error)
                    }
                } else {
                    // updatedOrg came back nil (either the calling wasn't really in the org, or originalCalling was nil on an update, Shouldn't ever happen).
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
    
    /** Currently this method just updates the org for the unit with the updated root level org (Primary, EQ, etc.). We don't change the map of actual callings because this is currently just for potential calling changes. The update of actual callings would only be after we've made a change in LCR */
    func updateCachedCallingData(unitLevelOrg: Org, originalCalling: Calling?, changedCalling: Calling, operation: Org.CRUDOperation) {
        if self.appDataOrg != nil {
            self.appDataOrg!.updateDirectChildOrg(org: unitLevelOrg)
        }
        // update potential Callings map - will need to switch on operation
        if let indId = changedCalling.proposedIndId {
            
            switch operation {
            case .Create:
                self.memberPotentialCallingsMap.addValue(forKey: indId, value: changedCalling)
            case .Delete:
                self.memberPotentialCallingsMap.removeValue(forKey: indId, value: changedCalling)
            case .Update:
                if let oldIndId = originalCalling?.proposedIndId {
                    // if originalCalling is nil, there's no way to get here, so safe to ! it
                    self.memberPotentialCallingsMap.removeValue(forKey: oldIndId, value: originalCalling!)
                }
                self.memberPotentialCallingsMap.addValue(forKey: indId, value: changedCalling)
            }
        }
        
        // no need to update existing callings - that should only be after we've saved a change in LCR
    }
    
    /** converts a CRUD operation into a permission of the same type */
    private func getPermission( forCRUDOperation crudOp : Org.CRUDOperation ) -> Permission {
        switch crudOp {
        case .Create:
            return .Create
        case .Update:
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
    func updateExistingCallingsData(originalCalling: Calling, updatedCalling: Calling) {
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

