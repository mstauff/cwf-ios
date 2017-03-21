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
        // app & lcr both have 2 callings - but one of them has changed so it will appear as 3 callings, with one of them marked with a conflict for deletion
        XCTAssertEqual( ctr7.callings.count, 3 )
        
        // one should not have changed
        let sameCalling = ctr7.callings.first() { $0.id == 734829 }!
        XCTAssertEqual(sameCalling.existingIndId, 123)
        XCTAssertNil( sameCalling.proposedIndId )
        
        // one should be marked for deletion
        let oldCalling = ctr7.callings.first() { $0.id == 734820 }!
        XCTAssertEqual( oldCalling.existingIndId, 222 )
            XCTAssertEqual( oldCalling.conflict, ConflictCause.LdsEquivalentDeleted )
        // the other should be the new one
        let updatedCalling = ctr7.callings.first() { $0.id == 734821 }!
        XCTAssertEqual( updatedCalling.existingIndId, 234 )
        
        // someone was released outside the app - no replacement
        let ctr8 = reconciledOrg.getChildOrg(id: 752892)!
        let callingReleasedInLcr = ctr8.callings[0]
        XCTAssertEqual( callingReleasedInLcr.conflict, .LdsEquivalentDeleted )
        
        let ctr9 = reconciledOrg.getChildOrg(id: 750112)
        XCTAssertNotNil( ctr9 )
        
        let varsityOrg = reconciledOrg.getChildOrg(id: 839510)!
        // varsity coach was finalized outside the app. ensure that the proposed version was deleted
        XCTAssertEqual(varsityOrg.callings.count, 1)
        var varsityCoach = varsityOrg.callings[0]
        XCTAssertEqual(varsityCoach.position.positionTypeId, 1459)
        XCTAssertEqual(varsityCoach.existingIndId, 890)
        XCTAssertNil(varsityCoach.proposedIndId)
        XCTAssertEqual(varsityCoach.proposedStatus, .Unknown)
        
        let scoutOrg = reconciledOrg.getChildOrg(id: 839500)!
        XCTAssertEqual(scoutOrg.allOrgCallings.count, 2)
        // validate that a new calling added in LCR shows up
        XCTAssertEqual(scoutOrg.callings.count, 1)
        let newCalling = scoutOrg.callings[0]
        XCTAssertEqual(newCalling.id, 14727)
        XCTAssertEqual(newCalling.existingIndId, 789)
        
        // todo - outstanding test cases
        // - proposed & actual with different person - should be merged
        // - variations with multiple allowed
        // - callings are same - except app has notes
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
