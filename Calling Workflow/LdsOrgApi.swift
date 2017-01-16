//
//  LdsOrg.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 1/13/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

protocol LdsOrgApi {
    var appConfig : AppConfig { get set }
    
    func ldsSignin(username: String, password: String,_ completionHandler: @escaping ( _ error:NSError? ) -> Void)
    func getCurrentUser( _ completionHandler: @escaping ( LdsUser?, Error? ) -> Void )
    func getMemberList( unitNum : Int64, _ completionHandler: @escaping ( [Member]?, Error? ) -> Void )
    func getOrgWithCallings( unitNum : Int64, _ completionHandler: @escaping ( Org?, Error? ) -> Void )
    
}

protocol LdsOrgApiInjected { }

extension LdsOrgApiInjected {
    var ldsOrgApi:LdsOrgApi { get { return InjectionMap.ldsOrgApi } }
}
