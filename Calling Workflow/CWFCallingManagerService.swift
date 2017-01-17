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
        ldscdApi.getAppConfig() { (appConfig, error) in
            
            guard appConfig != nil else {
                print( "No app config" )
                //todo - call completionHandler with error
                return
            }
            self.ldsOrgApi.setAppConfig( appConfig: appConfig! )
            let ldsApi = self.ldsOrgApi
            ldsApi.ldsSignin(username: username, password: password,  { (error) -> Void in
                if error != nil {
                    print( error!)
                } else {
                    // todo: how do we handle error with the dispatchGroup
                    let restCallsGroup = DispatchGroup()
                    
                    restCallsGroup.enter()
                    ldsApi.getMemberList(unitNum: unitNum) {[weak weakSelf=self] (members, error) -> Void in
                        if members != nil && !members!.isEmpty {
                            weakSelf?.memberList = members!
                            print( "First Member of unit:\(members![0])" )
                        } else {
                            print( "no user" )
                        }
                        restCallsGroup.leave()
                    }
                    
                    restCallsGroup.enter()
                    ldsApi.getOrgWithCallings(unitNum: unitNum ) { [weak weakSelf=self]  (org, error) -> Void in
                        if org != nil && !org!.children.isEmpty {
                            // todo: this actually need to be reconcile with data coming from goodrive
                            weakSelf?.unitOrg = org
                            print( "First Org of unit:\(org!.children[0])" )
                            
                        } else {
                            print( "no org" )
                        }
                        restCallsGroup.leave()
                    }
                    
                    restCallsGroup.notify( queue: DispatchQueue.main ) {
                        print( "REST calls complete" )
                        completionHandler(true, nil)
                    }
                }
            })
            
        }
        
    }
    
    //todo: need update org methods
}

