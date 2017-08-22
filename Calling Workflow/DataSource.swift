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
    func hasValidCredentials( forUnit unitNum : Int64, completionHandler: @escaping (Bool, Error?) -> Void )

    func initializeDrive(forOrgs orgs: [Org], completionHandler: @escaping(_ orgsToCreate: [Org], _ remainingOrgs: [Org], _ error: Error?) -> Void)
    func createFiles( forOrgs orgs: [Org], completionHandler: @escaping(_ success : Bool, _ errors : [Error] )-> Void ) 
    func getData( forOrg : Org, completionHandler : @escaping (_ org : Org?, _ error: Error? ) -> Void )
    
    func updateOrg( org : Org, completionHandler : @escaping (_ success : Bool, _ error: Error? ) -> Void )
    
}
