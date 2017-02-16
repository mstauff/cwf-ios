//
//  ModelTests.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 11/7/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import XCTest

@testable
import Calling_Workflow

class ModelTests: XCTestCase {
    
    var testJSON : [String:AnyObject]? = nil
    var jsonSerializer : JSONSerializer = JSONSerializerImpl()
    private var standardOrg = Org( id: 1, orgTypeId: 1 )
    private var multiDepthOrg = Org( id: 1, orgTypeId: 1 )

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // Normally we would just inline the JSON as a string and then parse it and validate it.
        // unfortunately the options in xcode are either one big long string (which makes it difficult to decipher
        // where objects start and stop, and which properties belong to which object), or break it along multiple
        // lines like formatted JSON is usually presented, but the amount of escaping of quotes, and handling of line
        // breaks makes it very difficult to read, or add to or edit, so we're going to just put all the data in an
        // external file, read it in and reference different objects for different test cases
        let bundle = Bundle( for: type(of: self) )
        if let filePath = bundle.path(forResource: "cwf-object", ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            testJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
            standardOrg = Org( fromJSON: (testJSON?["orgWithCallingsInSubOrg"] as? JSONObject)! )!
            multiDepthOrg = Org( fromJSON: (testJSON?["orgWithMultiDepthSubOrg"] as? JSONObject)! )!

        } else {
            print( "No File Path found for file" )
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOrgJsonDeserialization() {
        let org = standardOrg
        
        XCTAssertNotNil(org)
        XCTAssertEqual( org.orgName, "Primary" )
        XCTAssertEqual( org.orgTypeId, 77 )
        XCTAssertEqual( org.displayOrder, 700 )
        XCTAssertEqual( org.id, 7428354 )
        XCTAssertEqual( org.children.count, 3 )
        XCTAssertNotNil(org.callings)
        XCTAssertEqual(org.callings.count, 0)
    }
    func testCallingsInSubOrgFromJson() {
        let org = standardOrg
        
        let childOrg = org.children[0]
        XCTAssertNotNil(childOrg)
        XCTAssertEqual( childOrg.orgName, "CTR 7" )
        XCTAssertEqual(childOrg.callings.count, 2)
        let calling = childOrg.callings[0]
        XCTAssertEqual(calling.existingIndId!, 123)
        XCTAssertEqual(calling.existingStatus, ExistingCallingStatus.Active)
        XCTAssertNil( calling.activeDate )
        XCTAssertEqual(calling.id, 734829)
        XCTAssertEqual(calling.position.positionTypeId, 1481)
        XCTAssertEqual(calling.position.name, "Primary Teacher")
        XCTAssertEqual(calling.position.hidden, false)
        XCTAssertEqual(calling.proposedStatus, CallingStatus.Proposed)
        XCTAssertEqual(calling.notes, "Some String")
        
    }
    func testCallingsInOrgFromJson() {
        let org = Org( fromJSON: (testJSON?["orgWithDirectCallings"] as? JSONObject)! )
        
        XCTAssertNotNil(org)
        let calling = org!.callings[0]
        XCTAssertEqual(calling.existingIndId!, 123)
        XCTAssertEqual(calling.existingStatus, ExistingCallingStatus.Active)
        XCTAssertEqual( calling.activeDate, Date( year: 2015, month: 09, day: 22 ) )
        XCTAssertEqual(calling.id, 734829)
        XCTAssertEqual(calling.position.positionTypeId, 1481)
        XCTAssertEqual(calling.position.name, "Primary Teacher")
        XCTAssertEqual(calling.position.hidden, true)
        XCTAssertEqual(calling.proposedStatus, CallingStatus.Proposed)
        XCTAssertEqual(calling.notes, "Some String")
        
    }
    
    
    func testInvalidOrgsFromJson() {
        let orgsJSON = testJSON?["invalidOrgs"] as? [JSONObject]!
        orgsJSON?.forEach() { orgJSON in
            let org = Org( fromJSON: orgJSON )
            XCTAssertNil( org )
        }
    }
    
    func testOrgToJson() {
        let org = standardOrg
        
        let orgJson = org.toJSONObject()
        let jsonString = jsonSerializer.serialize( jsonObject: orgJson )
        XCTAssertTrue(jsonString!.contains( "\"defaultOrgName\":\"Primary\"" ))
        XCTAssertTrue(jsonString!.contains( "\"subOrgId\":7428354" ))
        XCTAssertTrue(jsonString!.contains( "\"orgTypeId\":77" ))
        // just test that there is some object in the callings array. If it's empty it would not have the { and " after the [
        XCTAssertTrue(jsonString!.contains( "\"callings\":[{\"" ))
        XCTAssertTrue(jsonString!.contains( "\"memberId\":123" ))
        XCTAssertTrue(jsonString!.contains( "\"positionId\":734829" ))
        XCTAssertTrue(jsonString!.contains( "\"proposedIndId\":456" ))
        XCTAssertTrue(jsonString!.contains( "\"positionTypeId\":1481" ))
        XCTAssertTrue(jsonString!.contains( "\"notes\":\"Some String\"" ))
        XCTAssertTrue(jsonString!.contains( "\"proposedStatus\":\"PROPOSED\"" ))
        XCTAssertTrue(jsonString!.contains( "\"position\":\"Primary Teacher\"" ))
        XCTAssertTrue(jsonString!.contains( "\"hidden\":\"false\"" ))
        XCTAssertTrue(jsonString!.contains( "\"activeDate\":\"20150922\"" ))
        XCTAssertTrue(jsonString!.contains( "\"displayOrder\":700" ))
        print( "JSON:" + jsonString! )
        
    
    }

    func testCallingMonths() {
        let org = standardOrg
        let callingWithNoDate = org.children[0].callings[0]
        XCTAssertEqual( callingWithNoDate.existingMonthsInCalling, 0 )

        var callingWithDate = org.children[0].callings[1]
        // manual test - would need to be updated monthly if enabled
//        XCTAssertEqual( callingWithDate.existingMonthsInCalling, 16 )
        callingWithDate.activeDate = Date().xMonths( x: -4 )
        XCTAssertEqual(callingWithDate.existingMonthsInCalling, 4)

    }

    func testGetChildOrg() {
        let org = standardOrg
        var childOrg = org.getChildOrg(id: 752892)
        XCTAssertNotNil( childOrg )
        XCTAssertEqual(childOrg!.orgTypeId, 40 )

        childOrg = org.getChildOrg(id: 38432972)
        XCTAssertNotNil( childOrg )
        XCTAssertEqual(childOrg!.orgTypeId, 35 )

        XCTAssertNil( org.getChildOrg( id: 17 ) )

        XCTAssertEqual(multiDepthOrg.getChildOrg(id: 839500)!.orgTypeId, 739)
        XCTAssertEqual(multiDepthOrg.getChildOrg(id: 839510)!.orgTypeId, 1700)

    }

    func testAllCallings() {
        let org = standardOrg
        XCTAssertEqual(org.allOrgCallings.count, 5)
        XCTAssertEqual(org.allOrgCallingIds.count, 4)
        XCTAssertEqual(org.children[0].allOrgCallings.count, 2)

        XCTAssertEqual( multiDepthOrg.allOrgCallings.count, 2 )

    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
