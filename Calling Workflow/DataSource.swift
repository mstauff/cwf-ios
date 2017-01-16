//
//  DateSource.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 12/19/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import Foundation
import GoogleAPIClient
import GTMOAuth2

//TODO: This will eventually go in a central location where we specify all the dependencies
struct InjectionMap {
    static var dataSource:DataSource = RemoteDataSource()
}

protocol DataSourceInjected { }

extension DataSourceInjected {
    var dateSource:DataSource { get { return InjectionMap.dataSource } }
}

protocol DataSource {

    var isAuthenticated : Bool {
        get
    }
    
    func authenticate( currentVC : UIViewController, completionHandler: @escaping (UIViewController, GTMOAuth2Authentication, NSError?) -> Void  )
    func getDataForOrg( org : Org, completionHandler : @escaping (_ org : Org?, _ error: NSError? ) -> Void )
    
    func updateOrg( org : Org, completionHandler : (_ success : Bool, _ error: NSError? ) -> Void )
    
}
