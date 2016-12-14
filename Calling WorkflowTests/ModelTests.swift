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
        } else {
            print( "No File Path found for file" )
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testOrgJsonDeserialization() {
        let org = Org( (testJSON?["orgWithCallingsInSubOrg"] as? JSONObject)! )
        
        XCTAssertNotNil(org)
        XCTAssertEqual( org!.orgName, "Primary" )
        XCTAssertEqual( org!.orgTypeId, 77 )
        XCTAssertEqual( org!.displayOrder, 700 )
        XCTAssertEqual( org!.id, 7428354 )
        XCTAssertEqual( org!.children.count, 1 )
        XCTAssertNotNil(org!.callings)
        XCTAssertEqual(org!.callings.count, 0)
    }
    func testCallingsInSubOrgFromJson() {
        let org = Org( (testJSON?["orgWithCallingsInSubOrg"] as? JSONObject)! )
        
        let childOrg = org?.children[0]
        XCTAssertNotNil(childOrg)
        XCTAssertEqual( childOrg!.orgName, "CTR 7" )
        XCTAssertEqual(childOrg!.callings.count, 2)
        let calling = childOrg!.callings[0]
        XCTAssertEqual(calling.currentIndId!, 123)
        XCTAssertEqual(calling.id, 734829)
        XCTAssertEqual(calling.position.positionTypeId, 1481)
        XCTAssertEqual(calling.position.name, "Primary Teacher")
        XCTAssertEqual(calling.position.hidden, false)
        XCTAssertEqual(calling.status, "PROPOSED")
        XCTAssertEqual(calling.notes, "Some String")
        
    }
    func testCallingsInOrgFromJson() {
        let org = Org( (testJSON?["orgWithDirectCallings"] as? JSONObject)! )
        
        XCTAssertNotNil(org)
        let calling = org!.callings[0]
        XCTAssertEqual(calling.currentIndId!, 123)
        XCTAssertEqual(calling.id, 734829)
        XCTAssertEqual(calling.position.positionTypeId, 1481)
        XCTAssertEqual(calling.position.name, "Primary Teacher")
        XCTAssertEqual(calling.position.hidden, true)
        XCTAssertEqual(calling.status, "PROPOSED")
        XCTAssertEqual(calling.notes, "Some String")
        
    }
    
    
    func testInvalidOrgsFromJson() {
        let orgsJSON = testJSON?["invalidOrgs"] as? [JSONObject]!
        orgsJSON?.forEach() { orgJSON in
            let org = Org( orgJSON )
            XCTAssertNil( org )
        }
    }
    
    func testOrgToJson() {
        let org = Org( (testJSON?["orgWithCallingsInSubOrg"] as? JSONObject)! )
        
        let orgJson = org!.toJSONObject()
        let jsonString = jsonSerializer.serialize( jsonObject: orgJson )
        XCTAssertTrue(jsonString!.contains( "\"defaultOrgName\":\"Primary\"" ))
        XCTAssertTrue(jsonString!.contains( "\"subOrgId\":\"7428354\"" ))
        XCTAssertTrue(jsonString!.contains( "\"orgTypeId\":\"77\"" ))
        // just test that there is some object in the callings array. If it's empty it would not have the { and " after the [
        XCTAssertTrue(jsonString!.contains( "\"callings\":[{\"" ))
        XCTAssertTrue(jsonString!.contains( "\"memberId\":\"123\"" ))
        XCTAssertTrue(jsonString!.contains( "\"positionId\":\"734829\"" ))
        XCTAssertTrue(jsonString!.contains( "\"proposedIndId\":\"456\"" ))
        XCTAssertTrue(jsonString!.contains( "\"positionTypeId\":\"1481\"" ))
        XCTAssertTrue(jsonString!.contains( "\"notes\":\"Some String\"" ))
        XCTAssertTrue(jsonString!.contains( "\"status\":\"PROPOSED\"" ))
        XCTAssertTrue(jsonString!.contains( "\"position\":\"Primary Teacher\"" ))
        XCTAssertTrue(jsonString!.contains( "\"hidden\":\"false\"" ))
        print( jsonString )
        
    
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
