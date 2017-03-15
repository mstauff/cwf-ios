//
//  CallingManagerServiceTests.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 2/6/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import XCTest
@testable import Calling_Workflow

class CallingManagerServiceTests: XCTestCase {

    var callingMgr = CWFCallingManagerService()
    var org : Org?
    var lcrOrg = Org( id: 111, orgTypeId: UnitLevelOrgType.Ward.rawValue )
    var appOrg  = Org( id: 111, orgTypeId: UnitLevelOrgType.Ward.rawValue )

    override func setUp() {
        org = getOrgFromFile(fileName: "cwf-object", orgJsonName: "orgWithCallingsInSubOrg")!
        lcrOrg.children = getOrgsFromFile(fileName: "reconcile-test-orgs", orgJsonName: "lcrOrg")
        appOrg.children = getOrgsFromFile(fileName: "reconcile-test-orgs", orgJsonName: "appOrg")
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func getOrgFromFile( fileName: String, orgJsonName: String ) -> Org? {
        var result : Org? = nil
        let bundle = Bundle( for: type(of: self) )
        if let filePath = bundle.path(forResource: fileName, ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            let testJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
            result = Org( fromJSON: (testJSON?[orgJsonName] as? JSONObject)! )
            
        } else {
            print( "No File Path found for file" )
        }

        return result
    }
    
    func getOrgsFromFile( fileName: String, orgJsonName: String ) -> [Org] {
        var result : [Org] = []
        let bundle = Bundle( for: type(of: self) )
        if let filePath = bundle.path(forResource: fileName, ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            let testJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
            result = Org.orgArrays( fromJSONArray: (testJSON?[orgJsonName] as? [JSONObject])! )
            
        } else {
            print( "No File Path found for file" )
        }
        
        return result
    }
    
    func testmapForCallingsByIndId() {
        let callingMap = callingMgr.multiValueDictionaryFromArray(array: org!.allOrgCallings, transformer: {$0.proposedIndId})
        validateCallingList(callingMap: callingMap, indId: 567, expectedNumCallings: 2, expectedCallings: [1482, 1483], shouldNotHaveCallings: [1481])
        validateCallingList(callingMap: callingMap, indId: 456, expectedNumCallings: 1, expectedCallings: [1481], shouldNotHaveCallings: [1482])

    }

    func validateCallingList(callingMap : MultiValueDictionary<Int64,Calling>, indId : Int64, expectedNumCallings : Int, expectedCallings : [Int], shouldNotHaveCallings : [Int] ) {
        let callings = callingMap.getValues(forKey: indId)
        XCTAssertEqual(callings.count, expectedNumCallings)
        let callingIds = callings.map(){$0.position.positionTypeId}
        for callingId in expectedCallings {
            XCTAssertTrue( callingIds.contains( callingId) )
        }
        for callingId in shouldNotHaveCallings{
            XCTAssertFalse( callingIds.contains( callingId) )
        }
    }
    
    func testReconcileCallings() {
        // create a reconcileAppOrg & reconcileLdsOrg in the json file
        // read them in, pass to reconcileCallings & validate
            let reconciledOrg = callingMgr.reconcileOrg(appOrg: appOrg, ldsOrg: lcrOrg)
        let primaryOrg = reconciledOrg.getChildOrg(id: 7428354)!
        XCTAssertEqual( primaryOrg.children.count, 3 )
        let ctr7 = reconciledOrg.getChildOrg(id: 38432972)!
        // app & lcr both have 2 callings - make sure no changes were recorded as new callings
        XCTAssertEqual( ctr7.callings.count, 2 )
        let callingWithChangedIndividual = ctr7.callings[1]
        // appOrg indId of 222 was changed to 234 in LCR
        XCTAssertEqual( callingWithChangedIndividual.existingIndId, 234 )
        
        let ctr8 = reconciledOrg.getChildOrg(id: 752892)!
        let callingReleasedInLcr = ctr8.callings[0]
        XCTAssertEqual( callingReleasedInLcr.conflict, .LdsEquivalentDeleted )
        
        let ctr9 = reconciledOrg.getChildOrg(id: 750112)
        XCTAssertNotNil( ctr9 )
        
        let varsityOrg = reconciledOrg.getChildOrg(id: 839510)!
        // varsity coach was finalized outside the app. ensure that the finalized & proposed version were merged
        XCTAssertEqual(varsityOrg.callings.count, 2)
        var varsityCoach = varsityOrg.callings[0]
        XCTAssertEqual(varsityCoach.position.positionTypeId, 1459)
        XCTAssertEqual(varsityCoach.conflict, .EquivalentPotentialAndActual)
        
        varsityCoach = varsityOrg.callings[1]
        XCTAssertEqual(varsityCoach.existingIndId, 890)
        XCTAssertEqual(varsityCoach.position.positionTypeId, 1459)
        XCTAssertEqual(varsityCoach.id, 275893)
        
        let scoutOrg = reconciledOrg.getChildOrg(id: 839500)!
        XCTAssertEqual(scoutOrg.allOrgCallings.count, 3)
        // validate that a new calling added in LCR shows up
        XCTAssertEqual(scoutOrg.callings.count, 1)
        let newCalling = scoutOrg.callings[0]
        XCTAssertEqual(newCalling.id, 14727)
        XCTAssertEqual(newCalling.existingIndId, 789)
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
