//
//  DateSource.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 12/19/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import Foundation
import UIKit

// something that needs access to the datasource implements DataSourceInjected and then they can reference dataSource as a class var
protocol DataSourceInjected { }

extension DataSourceInjected {
    var dataSource:DataSource { get { return InjectionMap.dataSource } }
}

protocol DataSource {

    var isAuthenticated : Bool {
        get
    }

    // todo - need to tie this to a unit. HOW????
    func authenticate( currentVC : UIViewController, completionHandler: @escaping (UIViewController?, Bool, NSError?) -> Void  )
    func initializeDrive(forOrgs orgs: [Org], completionHandler: @escaping(_ remainingOrgs: [Org], _ error: NSError?) -> Void)
    func getData( forOrg : Org, completionHandler : @escaping (_ org : Org?, _ error: NSError? ) -> Void )
    
    func updateOrg( org : Org, completionHandler : @escaping (_ success : Bool, _ error: NSError? ) -> Void )
    
}
