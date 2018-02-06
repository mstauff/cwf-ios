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
    // without a dedicated setter we can't (after init) do ldsApi.appConfig = appConfig in the class that initialies the API (get a compiler error about ldsOrgApi being read only)
    func setAppConfig( appConfig : AppConfig )
    
    func ldsSignin(forUser: String, withPassword: String,_ completionHandler: @escaping ( _ error:NSError? ) -> Void)
    func ldsSignout( _ completionHandler: @escaping() -> Void )
    func getCurrentUser( _ completionHandler: @escaping ( LdsUser?, Error? ) -> Void )
    func getMemberList( unitNum : Int64, _ completionHandler: @escaping ( [Member]?, Error? ) -> Void )
    func getOrgWithCallings( unitNum : Int64, _ completionHandler: @escaping ( Org?, Error? ) -> Void )
    func releaseCalling( unitNum : Int64, calling : Calling, _ completionHandler: @escaping ( Bool, Error? ) -> Void )
    func deleteCalling( unitNum : Int64, calling : Calling, _ completionHandler: @escaping ( Bool, Error? ) -> Void )
    func updateCalling( unitNum : Int64, calling : Calling, _ completionHandler: @escaping ( Calling?, Error? ) -> Void )
    
}

protocol LdsOrgApiInjected { }

extension LdsOrgApiInjected {
    var ldsOrgApi:LdsOrgApi { get { return InjectionMap.ldsOrgApi } }
}
