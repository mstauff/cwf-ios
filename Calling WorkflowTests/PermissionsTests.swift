//
//  PermissionsTests.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 5/5/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import XCTest

@testable
import Calling_Workflow


class PermissionsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRolePermissions() {
        XCTAssertEqual( Role.unitAdmin.permissions.count, 4 )
        let unitAdminActiveCallingPerms = Role.unitAdmin.permissions[.ActiveCalling]
        XCTAssertEqual( unitAdminActiveCallingPerms!, [.Update, .Delete, .Release] )
        
        let orgAdminActiveCallingPerms = Role.orgAdmin.permissions[.ActiveCalling]
        XCTAssertEqual( orgAdminActiveCallingPerms!, [.Update, .Delete, .Release] )

        let unitViewActiveCallingPerms = Role.unitViewer.permissions[.ActiveCalling]
        XCTAssertNil( unitViewActiveCallingPerms )
        
        let unitAdminGooglePerms = Role.unitAdmin.permissions[.UnitGoogleAccount]
        XCTAssertEqual( unitAdminGooglePerms!, [.Create, .Update ] )
        
        let orgAdminGooglePerms = Role.unitViewer.permissions[.UnitGoogleAccount]
        XCTAssertNil( orgAdminGooglePerms )
        
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
