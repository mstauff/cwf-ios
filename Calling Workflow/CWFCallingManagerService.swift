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
                    let mergedOrg = self.reconcileCallings(inSubOrg: org!, ldsOrgVersion: ldsOrg)
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
                    var mergedOrg: Org
                    mergedOrg = self.reconcileCallings(inSubOrg: org!, ldsOrgVersion: ldsOrg)
                    completionHandler(mergedOrg, nil)
                }
            }
        } else {
            let errorMsg = "Error: No Org with ID: \(orgId)"
            completionHandler(nil, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
        }
    }

    /** Takes an org from the application data source (currently google drive) and compares it to an org coming from lds.org (currently LCR) and reconciles any differences between callings in the two. The lds.org version is authoritative, so we generally modify the application version to match that. But we try to be smart about it so if we have an actual calling from LCR for a CTR7 teacher without a match in google drive, we would check to see if we have a potential calling in google drive for that same calling and individual (basically it was started in the app, but then recorded officially directly in LCR). If there's a match we update the potential with the actual. */
    func reconcileCallings(inSubOrg appOrg: Org, ldsOrgVersion ldsOrg: Org) -> Org {
        var updatedOrg = appOrg


        // todo - this method is all wrong due to the fact we're working with structs not classes & value copy semantics. Need to revisit it
        let appCallingsById = updatedOrg.allOrgCallings.toDictionaryById() { $0.id }
        let appCallingIds = appCallingsById.keys
        let appCallingsByProposedIndId = multiValueDictionaryFromArray(array: updatedOrg.allOrgCallings) { $0.proposedIndId }

        let ldsOrgCallingsById = ldsOrg.allOrgCallings.toDictionaryById() { $0.id }
        let ldsOrgCallingIds = ldsOrgCallingsById.keys


        for (ldsCallingId, ldsCalling) in ldsOrgCallingsById {

            if appCallingIds.contains(ldsCallingId) {
                // the ID's match, we need to ensure nothing else has changed
                // can't do straight object == (even with Equatable) because comparing a lds.org calling to a app calling is different than appCalling == appCalling (lds.org callings have no proposed fields, etc.)
                var appCalling = appCallingsById[ldsCallingId]!

                if ldsCalling.existingIndId != appCalling.existingIndId {
                    appCalling.updateExistingCalling(withIndId: ldsCalling.existingIndId, activeDate: ldsCalling.activeDate)
                    updatedOrg.hasUnsavedChanges = true
                    // check potential - if it matches then remove the potential
                    // currently we're only looking at the potential for THIS calling - could in the future expand to look for a match of any similar potential calling, if desired
                    if appCalling.proposedIndId == appCalling.existingIndId {
                        appCalling.clearPotentialCalling()
                    }

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
                        potentialCalling.conflict = Calling.ConflictCause.EquivalentPotentialAndActual
                    }

                }

                // Now need to add the existing calling from LCR
                updatedOrg.hasUnsavedChanges = true
                if let ldsCallingOrg = ldsCalling.parentOrg, var appCallingOrg = appOrg.getChildOrg(id: ldsCallingOrg.id) {
                    appCallingOrg.callings.append(Calling(id: ldsCalling.id, existingIndId: ldsCalling.existingIndId, existingStatus: .Active, activeDate: ldsCalling.activeDate, proposedIndId: nil, status: nil, position: ldsCalling.position, notes: nil, editableByOrg: true, parentOrg: appCallingOrg))
                }
            }
        }

        // we've addressed any differences between callings that exist in LCR but weren't in the app. Now we need to look for any that are still in the app but aren't in LCR. For this step we only care about callings with actual ID's (that means they were at one point in LCR, but are no longer). Any callings in the app without an ID are just proposed callings that shouldn't exist in LCR yet, so we ignore those
        let callingIDsToRemove = Set(appCallingIds).subtracting(Set(ldsOrgCallingIds))
        for callingId in callingIDsToRemove {
            // todo - test this. May not work due to value copy semantics
            if var calling = appCallingsById[callingId] {
                calling.conflict = Calling.ConflictCause.LdsEquivalentDeleted
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

