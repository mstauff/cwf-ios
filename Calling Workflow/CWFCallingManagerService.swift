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

    // implied ldscdApi  comes from LdscdApiInjected
    // implied ldsOrgApi  comes from LdsOrgApiInjected
    // implied dataSource  comes from DataSourceInjected

    /// These are orgs that are in the app data store (goodrive) but not in lds.org. They likely need to be deleted, but may contain changes that the user will need to discard or merge to another org
    private var extraAppOrgs: [Org] = []

    /// Map of root level orgs in the current unit by their ID
    private var ldsUnitOrgsMap: [Int64: Org] = [:]

    /// Map of callings by member
    private var memberCallingsMap = MultiValueDictionary<Int64, Calling>()

    private var rootLevelOrgsForSubOrgs: [Int64: Int64] = [:]


    init() {

    }

    init(org: Org?, iMemberArray: [Member]) {
        ldsOrgUnit = org
        memberList = iMemberArray
    }

    /** Performs the calls that need to be made to lds.org at startup, or unit transition. First it gets the application config from our servers (which contains the lds.org endpoints to use). Next it logs in to lds.org, then it retrieves user data which includes their callings (to verify unit permissions), the unit member list and callings. Once all those have completed then we call the callback. If any one of them fails we will return an error via the callback. The data is not returned via the callback, it is just maintained internally in this class. The callback just lets the calling function know that this method has successfully completed.
     
     This method needs to be called prior to calling the authenticate() or loadAppData() methods */
    public func loadLdsData(forUnit unitNum: Int64, username: String, password: String, completionHandler: @escaping (Bool, Error?) -> Void) {
        // todo: eventually will want to enhance this so appConfig is cached, don't need to re-read when changing units.
        ldscdApi.getAppConfig() { (appConfig, error) in

            guard appConfig != nil else {
                print("No app config")
                let errorMsg = "Error: No Application Config"
                completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
                return
            }
            self.ldsOrgApi.setAppConfig(appConfig: appConfig!)
            let ldsApi = self.ldsOrgApi
            ldsApi.ldsSignin(username: username, password: password, { (error) -> Void in
                if error != nil {
                    print(error!)
                } else {
                    var ldsApiError: Error? = nil
                    let restCallsGroup = DispatchGroup()
                    // todo - need to add call to getUser

                    restCallsGroup.enter()
                    ldsApi.getMemberList(unitNum: unitNum) { (members, error) -> Void in
                        if members != nil && !members!.isEmpty {
                            self.memberList = members!
                            print("First Member of unit:\(members![0])")
                        } else {
                            print("no user")
                            if error != nil {
                                ldsApiError = error
                            }
                        }
                        restCallsGroup.leave()
                    }

                    restCallsGroup.enter()
                    ldsApi.getOrgWithCallings(unitNum: unitNum) { (org, error) -> Void in
                        if org != nil && !org!.children.isEmpty {
                            self.ldsOrgUnit = org
                            // need to put in dictionary by root level org for updating
                            self.ldsUnitOrgsMap.removeAll()
                            self.ldsUnitOrgsMap = org!.children.toDictionaryById() { $0.id }
                        } else {
                            print("no org")
                            if error != nil {
                                ldsApiError = error
                            }
                        }
                        restCallsGroup.leave()
                    }

                    restCallsGroup.notify(queue: DispatchQueue.main) {
                        // once all the calls have returned then call the callback
                        completionHandler(ldsApiError == nil, ldsApiError)
                    }
                }
            })

        }

    }

    /** Authenticate with the application's data source (currently google drive). We need to pass in the current view controller because if the user isn't already authenticated the google API will display a login screen for the user to authenticate. This should always be called before calling loadAppData() */
    public func authorizeDataSource(currentVC: UIViewController, completionHandler: @escaping (UIViewController?, Bool, NSError?) -> Void) {
        dataSource.authenticate(currentVC: currentVC, completionHandler: completionHandler)
    }

    /** Reads all the unit data from the application data store (currently google drive), and also reconciles any difference between data previously retrieved from lds.org. This method should only be called after loadLDSData() & authorizeDataSource() have successfully completed. The data is not returned in the callback, it is just maintained within this service. The callback just indicates to the calling function when this method has succesfully completed.
 The parameters for the callback indicate if all the data was loaded successfully, and whether there were extra orgs in the application data that were not in the lds.org data that potentially need to be removed or merged. This would be rare, but in cases where there were multiple EQ or RS groups, and then one gets removed in LCR we would still have the extra in our application data store*/
    public func loadAppData(completionHandler: @escaping(Bool, Bool, NSError?) -> Void) {
        guard let ldsUnit = self.ldsOrgUnit else {
            // todo - callback w/error
            return
        }

        self.appDataOrg = Org(id: ldsUnit.id, orgTypeId: ldsUnit.orgTypeId, orgName: ldsUnit.orgName, displayOrder: ldsUnit.displayOrder, children: [], callings: [])
        dataSource.initializeDrive(forOrgs: ldsOrgUnit!.children) { extraAppOrgs, error in
            self.extraAppOrgs = extraAppOrgs
            let dataSourceGroup = DispatchGroup()

            var mergedOrgs: [Org] = []
            for ldsOrg in ldsUnit.children {
                dataSourceGroup.enter()
                self.getOrgData(forOrgId: ldsOrg.id) { org, error in
                    dataSourceGroup.leave()

                    guard org != nil else {
                        return // exits the callback, not loadAppData
                    }
                    let mergedOrg = self.reconcileOrg(appOrg: org!, ldsOrg: ldsOrg)
                    mergedOrgs.append(mergedOrg)
                    // add all the child suborgs to a dictionary for lookup by ID
                    let subOrgsMap = mergedOrg.allSubOrgs.toDictionary({ subOrg in
                        return (subOrg.id, mergedOrg.id)
                    })

                    self.rootLevelOrgsForSubOrgs = self.rootLevelOrgsForSubOrgs.merged(withDictionary: subOrgsMap)
                }
            }

            dataSourceGroup.notify(queue: DispatchQueue.main) {
                self.appDataOrg!.children = mergedOrgs
                // this is only actual callings. Probably will need another for proposed callings
                self.memberCallingsMap = self.multiValueDictionaryFromArray(array: self.appDataOrg!.allOrgCallings) { $0.existingIndId }
                completionHandler(error == nil, extraAppOrgs.isNotEmpty, error)
            }
        }
    }

    /** Reads the given Org from google drive and calls the callback with the org converted from JSON */
    public func getOrgData(forOrgId orgId: Int64, completionHandler: @escaping (Org?, Error?) -> Void) {
        if let ldsOrg = self.ldsUnitOrgsMap[orgId] {

            dataSource.getData(forOrg: ldsOrg) { org, error in
                if error != nil {
                    completionHandler(nil, error)
                } else if org == nil {
                    let errorMsg = "Error: No Org data found for ID: \(orgId)"
                    completionHandler(nil, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
                } else {
                    let mergedOrg = self.reconcileOrg(appOrg: org!, ldsOrg: ldsOrg)
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
        updatedOrg.children = updatedChildren
        
        // now reconcile the callings in the current org
        updatedOrg = reconcileCallings(inSubOrg: updatedOrg, ldsOrgVersion: ldsOrg)

        return updatedOrg
        
    }
    
    /**Takes an org from the app data source (currently google drive) and compares the callings in it to the callings in an org from LCR to look for any differences. LCR is the authoritative source so we're mostly looking to make the app data match it, but we try to do it smartly where we looking for corresponding proposed changes that might match actual changes, and either automatically update the proposed data, or if we're not sure if something in the app data should be removed we mark it as being in conflict so it can be displayed to the user and resolved by them */
    private func reconcileCallings(inSubOrg appOrg: Org, ldsOrgVersion ldsOrg: Org) -> Org {
        // we could take and return [Calling] as params and return objects, but we also need to indicate if there were any changes that were made (currently stored in org.hasUnsavedChanges). That would require we return a tuple of (Bool, [Calling]), so rather than do that we'll stick with the Org object as the params & return type
        var updatedOrg = appOrg

        let appCallingsById = updatedOrg.callings.toDictionaryById() { $0.id }
        let appCallingIds = appCallingsById.keys
        let appCallingsByProposedIndId = multiValueDictionaryFromArray(array: updatedOrg.callings) { $0.proposedIndId }

        let ldsOrgCallingsById = ldsOrg.callings.toDictionaryById() { $0.id }
        let ldsOrgCallingIds = ldsOrgCallingsById.keys


        for (ldsCallingId, ldsCalling) in ldsOrgCallingsById {

            if appCallingIds.contains(ldsCallingId) {
                // the ID's match, we need to ensure nothing else has changed
                // can't do straight object == (even with Equatable) because comparing a lds.org calling to a app calling is different than appCalling == appCalling (lds.org callings have no proposed fields, etc.)
                let appCalling = appCallingsById[ldsCallingId]!

                if ldsCalling.existingIndId != appCalling.existingIndId {
                    var updatedCalling =  appCalling.updatedWith(indId: ldsCalling.existingIndId, activeDate: ldsCalling.activeDate)
                    // check potential - if it matches then remove the potential
                    // currently we're only looking at the potential for THIS calling - could in the future expand to look for a match of any similar potential calling, if desired
                    if appCalling.proposedIndId == appCalling.existingIndId {
                        updatedCalling.clearPotentialCalling()
                    }
                    updatedOrg = updatedOrg.updatedWith(changedCalling:updatedCalling, originalCalling: appCalling) ?? updatedOrg
                    updatedOrg.hasUnsavedChanges = true

                }

            } else {
                // it's not in the app org db so it needs to be added
                // first check to see if there's a potential calling with same type & ind ID
                if let indId = ldsCalling.existingIndId,
                   let callingParentOrg = ldsCalling.parentOrg {

                    let potentialCallingsForMember = appCallingsByProposedIndId.getValues(forKey: indId)
                    // filter all the potential callings that the given member has so it only includes those that are
                    // of the same parent org & position type as the lds.org calling we're iterating over
                    let matchingPotentialCallings = potentialCallingsForMember.filter() {
                        $0.position.positionTypeId == ldsCalling.position.positionTypeId && $0.parentOrg == callingParentOrg
                    }
                    for var potentialCalling in matchingPotentialCallings {
                        // for right now we're just marking it as changed - eventually may delete, but for now we'll leave it for the user to confirm before deleting
                        var updatedCalling = potentialCalling
                        updatedCalling.conflict = .EquivalentPotentialAndActual
                        updatedOrg = updatedOrg.updatedWith(changedCalling: updatedCalling, originalCalling: potentialCalling) ?? updatedOrg
                    }

                }

                // Now need to add the existing calling from LCR
                if let ldsCallingOrg = ldsCalling.parentOrg, let appCallingOrg = appOrg.id == ldsCallingOrg.id ? appOrg : appOrg.getChildOrg(id: ldsCallingOrg.id) {
                    let callingFromLcr = Calling(id: ldsCalling.id, existingIndId: ldsCalling.existingIndId, existingStatus: .Active, activeDate: ldsCalling.activeDate, proposedIndId: nil, status: nil, position: ldsCalling.position, notes: nil, editableByOrg: true, parentOrg: appCallingOrg)
                    updatedOrg = updatedOrg.updatedWith(newCalling: callingFromLcr) ?? updatedOrg
                }
                updatedOrg.hasUnsavedChanges = true
            }
        }

        // we've addressed any differences between callings that exist in LCR but weren't in the app. Now we need to look for any that are still in the app but aren't in LCR. For this step we only care about callings with actual ID's (that means they were at one point in LCR, but are no longer). Any callings in the app without an ID are just proposed callings that shouldn't exist in LCR yet, so we ignore those
        let callingIDsToRemove = Set(appCallingIds).subtracting(Set(ldsOrgCallingIds))
        for callingId in callingIDsToRemove {
            if var calling = appCallingsById[callingId] {
                calling.conflict = .LdsEquivalentDeleted
                updatedOrg = updatedOrg.updatedWith(changedCalling: calling, originalCalling: appCallingsById[callingId]!) ?? updatedOrg
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

    func getCallingsForMember(member: Member) -> [Calling] {
        let callingList = ldsOrgUnit?.allOrgCallings ?? []
        return callingList.filter() {
            $0.existingIndId == member.individualId
        }
    }
    
    func getCallingsForMemberAsStringWithMonths(member: Member) -> String {
        let callings = getCallingsForMember(member: member)
        var callingString = ""
        
        for calling in callings {
            if let nameString = calling.position.name {
                callingString.append("\(nameString) (\(calling.existingMonthsInCalling) M)")
                if (calling != callings[callings.count-1]) {
                    callingString.append(",  ")
                }
            }
        }
        
        return callingString
    }

    public func addCalling(calling: Calling, completionHandler: @escaping(Bool, Error?) -> Void) {
        self.storeCallingChange(changedCalling: calling, originalCalling: nil, operation: .Create, completionHandler: completionHandler)
    }

    public func deleteCalling(calling: Calling, completionHandler: @escaping(Bool, Error?) -> Void) {
        self.storeCallingChange(changedCalling: calling, originalCalling: nil, operation: .Delete, completionHandler: completionHandler)
    }

    public func updateCalling(originalCalling: Calling, updatedCalling: Calling, completionHandler: @escaping (Bool, Error?) -> Void) {
        self.storeCallingChange(changedCalling: updatedCalling, originalCalling: originalCalling, operation: .Update, completionHandler: completionHandler)
    }

    /** Performs the actual CRUD operations by reading the file for the org that the calling is in from google drive, performing the update, writing the entire org back to google drive, then updating the copy of the data that is cached locally. When this is all done we call the completion handler with the results */
    private func storeCallingChange(changedCalling: Calling, originalCalling: Calling?, operation: Org.CRUDOperation, completionHandler: @escaping (Bool, Error?) -> Void) {
        if let orgId = originalCalling?.parentOrg?.id ?? changedCalling.parentOrg?.id, let rootLevelOrgId = self.rootLevelOrgsForSubOrgs[orgId] {

            // read the org file fresh from google drive (to make sure we have the latest data before performing the change). This reduces the chance of clobbering another change in the org recorded by another user
            self.getOrgData(forOrgId: rootLevelOrgId) { org, error in
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
                if let updatedOrg = validOrg.updatedWithCallingChange(updatedCalling: changedCalling, originalCalling: originalCalling, operation: operation) {
                    self.dataSource.updateOrg(org: updatedOrg) { success, error in

                        if success {
                            // update the cached copy of the org, as well as the calling maps where we keep track of the callings that individuals hold
                            self.updateCachedCallingData(rootLevelOrg: updatedOrg, changedCalling: changedCalling, originalCalling: originalCalling, operation: operation)
                        }
                        // if it wasn't a success we just propogate the result and any errors on to the callback
                        completionHandler(success, error)
                    }
                } else {
                    // updatedOrg came back nil (either the calling wasn't really in the org, or originalCalling was nil on an update, Shouldn't ever happen).
                    var errorMsg = "Error: Calling data incomplete, unable to update."
                    if operation == .Update && originalCalling == nil {
                        errorMsg += " No original calling supplied for update."
                    } else {
                        errorMsg += " Calling was not found in org."
                    }
                    completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: ["error": errorMsg]))
                }
            }
        }
    }

    /** Currently this method just updates the org for the unit with the updated root level org (Primary, EQ, etc.). We don't change the map of actual callings because this is currently just for potential calling changes. The update of actual callings would only be after we've made a change in LCR */
    func updateCachedCallingData(rootLevelOrg: Org, changedCalling: Calling, originalCalling: Calling?, operation: Org.CRUDOperation) {
        if self.appDataOrg != nil {
            self.appDataOrg!.updateDirectChildOrg(org: rootLevelOrg)
        }
        // when we eventually add a potential Callings map we'll need to update it here - will need to switch on operation

        // no need to update existing callings - that should only be after we've saved a change in LCR
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

