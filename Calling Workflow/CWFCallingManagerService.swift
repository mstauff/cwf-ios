//
//  CWFDataSource.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/5/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

class CWFCallingManagerService : DataSourceInjected, LdsOrgApiInjected, LdscdApiInjected {
    
    var unitOrg:Org? = nil
    private(set) var memberList:[Member] = []
    var appConfig : AppConfig? = nil
    
    init() {
        
    }
    
    init(org: Org?, iMemberArray: [Member]) {
        unitOrg = org
        memberList = iMemberArray
    }
    
    func loadData( forUnit unitNum: Int64, username: String, password: String, completionHandler: @escaping (Bool, Error?) -> Void ) {
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
                            // todo: this actually need to be reconcile with data coming from goodrive
                            // also need to put in dictionary by root level org for updating
                            weakSelf?.unitOrg = org
                            print( "First Org of unit:\(org!.children[0])" )
                            
                        } else {
                            print( "no org" )
                            if error != nil {
                                ldsApiError = error
                            }
                        }
                        restCallsGroup.leave()
                    }
                    
                    restCallsGroup.notify( queue: DispatchQueue.main ) {
                        print( "REST calls complete" )
                        completionHandler( ldsApiError == nil, ldsApiError )
                    }
                }
            })
            
        }
        
    }
    // Used to get a member from the memberlist by memberId
    func getMemberWithId(memberId: Int64) -> Member? {
        var member : Member? = nil
        for currentMember in memberList {
            if (currentMember.individualId == memberId) {
                member = currentMember
            }
        }
        return member
    }
    
    // Used to get a list of all callings belonging to an org
    func getCallingsList() -> [Calling] {
        var callingList : [Calling] = []
        if let callings = unitOrg?.callings {
            callingList += callings
        }
        
        if let children = unitOrg?.children {
            for org in children {
                callingList.append(contentsOf: org.getCallingsList())
            }
        }
        return callingList
    }
    func getCallingsForMember(member: Member) -> [Calling] {
        var callingsForMember : [Calling] = []
        let callingList = getCallingsList()
        for calling in callingList {
            if calling.existingIndId == member.individualId {
                callingsForMember.append(calling)
            }
        }
        
        return callingsForMember
    }
    //todo: need update org methods
}

