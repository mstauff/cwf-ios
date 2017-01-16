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


// something that needs access to the datasource implements DataSourceInjected and then they can reference dataSource as a class var
protocol DataSourceInjected { }

extension DataSourceInjected {
    var dataSource:DataSource { get { return InjectionMap.dataSource } }
}

protocol DataSource {

    var isAuthenticated : Bool {
        get
    }
    
    func authenticate( currentVC : UIViewController, completionHandler: @escaping (UIViewController, GTMOAuth2Authentication, NSError?) -> Void  )
    func getDataForOrg( org : Org, completionHandler : @escaping (_ org : Org?, _ error: NSError? ) -> Void )
    
    func updateOrg( org : Org, completionHandler : (_ success : Bool, _ error: NSError? ) -> Void )
    
}
