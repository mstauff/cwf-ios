//
//  OrgServiceTests.swift
//  Calling WorkflowTests
//
//  Created by Matt Stauffer on 4/17/18.
//  Copyright © 2018 colsen. All rights reserved.
//

import XCTest
@testable import Calling_Workflow

class OrgServiceTests: XCTestCase {
    var lcrOrg = Org( id: 111, unitNum: 111, orgTypeId: UnitLevelOrgType.Ward.rawValue )
    var appOrg  = Org( id: 111,unitNum: 111, orgTypeId: UnitLevelOrgType.Ward.rawValue )
    var memberList : [Member] = []
    let jsonReader = JsonFileLoader()
    let orgService = OrgService()

    override func setUp() {
        super.setUp()
        lcrOrg.children = jsonReader.getOrgsFromFile(fileName: "reconcile-test-orgs", orgJsonName: "orgConflictLcr")
        appOrg.children = jsonReader.getOrgsFromFile(fileName: "reconcile-test-orgs", orgJsonName: "orgConflictApp")

        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testResolveSuborgConflicts() {
        // reconcileOrg marks items as conflicts, but doesn't process them - that's done by resolveSubOrgConflicts
        var combinedOrg = orgService.reconcileOrg(appOrg: appOrg, ldsOrg: lcrOrg, unitLevelOrg: lcrOrg)
        combinedOrg = orgService.resolveSuborgConflicts(inOrg: combinedOrg)
        
        let primary = combinedOrg.getChildOrg(id: 7428354)!
        
        // CTR 6 is in app & lcr - should exist and have no conflict
        let ctr6 = primary.getChildOrg(id: 47283)
        XCTAssertNotNil( ctr6 )
        XCTAssertNil( ctr6!.conflict )
        
        // CTR 7 removed in LCR, no pending changes in app, so it should be removed
        XCTAssertNil( primary.getChildOrg(id: 38432972) )
        
        // CTR 8 removed in LCR, but pending changes in app so it should exist but be marked as conflict
        let ctr8 = primary.getChildOrg(id: 752892)
        XCTAssertNotNil( ctr8 )
        if let ctr8 = ctr8 {
            XCTAssertEqual( ctr8.conflict, ConflictCause.LdsEquivalentDeleted )
        }
        
        // boy scouts has been removed from LCR, but a child org has outstanding callings so it should not be removed. But scouts and all sub-orgs should be marked with a conflict notice
        let ym = combinedOrg.getChildOrg(id: 839202)
        XCTAssertNotNil( ym )
        if let ym = ym {
            let scouts = ym.getChildOrg(id: 839500)
            XCTAssertNotNil( scouts )
            if let scouts = scouts {
                XCTAssertEqual( scouts.conflict, ConflictCause.LdsEquivalentDeleted )

                scouts.children.forEach() {
                    XCTAssertEqual( $0.conflict, ConflictCause.LdsEquivalentDeleted )
                }
            }
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
