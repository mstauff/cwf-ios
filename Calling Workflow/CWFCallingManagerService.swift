//
//  CWFDataSource.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/5/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation
import UIKit

class CWFCallingManagerService : DataSourceInjected, LdsOrgApiInjected, LdscdApiInjected {

    // todo - this should be private once we have all controllers correctly using public methods
    var ldsOrgUnit:Org? = nil
    var appDataOrg : Org? = nil
    private(set) var memberList:[Member] = []
    var appConfig : AppConfig? = nil

    // implied ldscdApi  comes from LdscdApiInjected
    // implied ldsOrgApi  comes from LdsOrgApiInjected
    // implied dataSource  comes from DataSourceInjected

    /// These are orgs that are in the app data store (goodrive) but not in lds.org. They likely need to be deleted, but may contain changes that the user will need to discard or merge to another org
    private var extraAppOrgs : [Org] = []

    /// Map of root level orgs in the current unit by their ID
    private var ldsUnitOrgsMap: [Int64:Org] = [:]

    /// Map of callings by member
    private var memberCallingsMap = MultiValueDictionary<Int64, Calling>()

    init() {
        
    }
    
    init(org: Org?, iMemberArray: [Member]) {
        ldsOrgUnit = org
        memberList = iMemberArray
    }
    
    public func loadLdsData( forUnit unitNum: Int64, username: String, password: String, completionHandler: @escaping (Bool, Error?) -> Void ) {
        // todo: eventually will want to enhance this so appConfig is cached, don't need to re-read when changing units.
        ldscdApi.getAppConfig() { [weak weakSelf = self] (appConfig, error) in
            
            guard appConfig != nil else {
                print( "No app config" )
                let errorMsg = "Error: No Application Config"
                completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [ "error" : errorMsg ] ) )
                return
            }
            weakSelf?.ldsOrgApi.setAppConfig( appConfig: appConfig! )
            let ldsApi = self.ldsOrgApi
            ldsApi.ldsSignin(username: username, password: password,  { (error) -> Void in
                if error != nil {
                    print( error!)
                } else {
                    var ldsApiError : Error? = nil
                    let restCallsGroup = DispatchGroup()
                    
                    restCallsGroup.enter()
                    ldsApi.getMemberList(unitNum: unitNum) { (members, error) -> Void in
                        if members != nil && !members!.isEmpty {
                            weakSelf?.memberList = members!
                            print( "First Member of unit:\(members![0])" )
                        } else {
                            print( "no user" )
                            if error != nil {
                                ldsApiError = error
                            }
                        }
                        restCallsGroup.leave()
                    }
                    
                    restCallsGroup.enter()
                    ldsApi.getOrgWithCallings(unitNum: unitNum ) { (org, error) -> Void in
                        if org != nil && !org!.children.isEmpty {
                            weakSelf?.ldsOrgUnit = org
                            // need to put in dictionary by root level org for updating
                            weakSelf?.ldsUnitOrgsMap.removeAll()
                            weakSelf?.ldsUnitOrgsMap = org!.children.toDictionaryById() { $0.id }
                        } else {
                            print( "no org" )
                            if error != nil {
                                ldsApiError = error
                            }
                        }
                        restCallsGroup.leave()
                    }

                    restCallsGroup.notify( queue: DispatchQueue.main ) {
                        completionHandler( ldsApiError == nil, ldsApiError )
                    }
                }
            })
            
        }
        
    }

    public func authorizeDataSource( currentVC : UIViewController, completionHandler: @escaping (UIViewController?, Bool, NSError?) -> Void  ) {
        dataSource.authenticate(currentVC: currentVC, completionHandler: completionHandler )
    }

    public func loadAppData( completionHandler: @escaping(Bool, Bool, NSError?) -> Void ) {
        guard let ldsUnit = self.ldsOrgUnit else {
            // todo - callback w/error
            return
        }

        self.appDataOrg = Org(id: ldsUnit.id, orgTypeId: ldsUnit.orgTypeId, orgName: ldsUnit.orgName, displayOrder: ldsUnit.displayOrder, children: [], callings: [])
        dataSource.initializeDrive(forOrgs: ldsOrgUnit!.children) { [weak weakSelf=self] extraAppOrgs, error in
            weakSelf?.extraAppOrgs = extraAppOrgs
            let dataSourceGroup = DispatchGroup()

            var mergedOrgs : [Org] = []
            for ldsOrg in ldsUnit.children {
                dataSourceGroup.enter()
                weakSelf?.getOrgData( forOrgId: ldsOrg.id ) { org, error in
                    dataSourceGroup.leave()

                    guard org != nil else {
                        return // exits the callback, not loadAppData
                    }
                    let mergedOrg  = weakSelf?.reconcileCallings( inSubOrg: org!, ldsOrgVersion: ldsOrg ) ?? ldsOrg
                    mergedOrgs.append( mergedOrg )
                }
            }

            dataSourceGroup.notify( queue: DispatchQueue.main ) {
                weakSelf?.appDataOrg!.children = mergedOrgs
                // this is only actual callings. Probably will need another for proposed callings
                weakSelf?.memberCallingsMap = weakSelf?.multiValueDictionaryFromArray(array: weakSelf!.appDataOrg!.allOrgCallings) { $0.existingIndId } ?? MultiValueDictionary()
                completionHandler( error == nil, extraAppOrgs.isNotEmpty, error )
            }
        }
    }

    public func getOrgData( forOrgId orgId : Int64, completionHandler: @escaping (Org?, Error?) -> Void ) {
        if let ldsOrg = self.ldsUnitOrgsMap[orgId] {

            dataSource.getData(forOrg: ldsOrg) { [weak weakSelf = self] org, error in
                if error != nil {
                    completionHandler( nil, error )
                } else if org == nil {
                    let errorMsg = "Error: No Org data found for ID: \(orgId)"
                    completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [ "error" : errorMsg ] ) )
                } else {
                    var mergedOrg : Org
                    mergedOrg = weakSelf?.reconcileCallings( inSubOrg: org!, ldsOrgVersion: ldsOrg) ?? org!
                    completionHandler( mergedOrg, nil )
                }
            }
        } else {
            let errorMsg = "Error: No Org with ID: \(orgId)"
            completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [ "error" : errorMsg ] ) )
        }
    }

    func reconcileCallings(inSubOrg appOrg: Org, ldsOrgVersion ldsOrg: Org) -> Org {
        var updatedOrg = appOrg


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
            if var calling = appCallingsById[callingId] {
                calling.conflict = Calling.ConflictCause.LdsEquivalentDeleted
            }
        }

        return updatedOrg
    }

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
        var member : Member? = nil
        for currentMember in memberList {
            if currentMember.individualId == memberId {
                member = currentMember
            }
        }
        return member
    }
    
    func getCallingsForMember(member: Member) -> [Calling] {
        let callingList = ldsOrgUnit?.allOrgCallings ?? []
        return callingList.filter() { $0.existingIndId == member.individualId }
    }
    
    func updateCalling(callingForUpdate:Calling) {

    }
    //todo: need update org methods
}

