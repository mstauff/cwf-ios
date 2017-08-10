//
//  DataSourceTests.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 1/27/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import XCTest
@testable
import Calling_Workflow


class DataSourceTests: XCTestCase {

    let dataSource = RemoteDataSource( )

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGetFileName() {
        let validOrg = Org(id: 12345, unitNum: 1111, orgTypeId: UnitLevelOrgType.Elders.rawValue)
        let badOrg = Org( id: 41234, unitNum: 1111, orgTypeId: 8248482 )
        XCTAssertEqual( dataSource.getFileName(forOrg: validOrg)!, "EQ-12345.json")
        XCTAssertNil( dataSource.getFileName(forOrg: badOrg) )
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
