//
//  CollectionExtensionsTests.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 3/14/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import XCTest
@testable import Calling_Workflow

class CollectionExtensionsTests: XCTestCase {
    
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
    func testmapForCallingsById() {
        // todo - this used to test a convenience method in callingMgr - needs to be moved to a new CollectionExtensionsTests
        let callingMap = org!.allOrgCallings.toDictionaryById( {$0.id})
        var calling = callingMap[734829]!
        XCTAssertEqual( calling.existingIndId, 123 )
        calling = callingMap[734820]!
        XCTAssertEqual( calling.existingIndId, 234 )
        // ensure we're pulling in callings from all suborgs - test org has 6 callings total, 1 is a proposed so it won't be included in the map (no ID), another is invalid calling so it's not in the org
        XCTAssertEqual( callingMap.count, 4 )
    }
    
    func testToDictionary() {
        struct MiniCalling {
            var id : Int64
            
            init(_ id: Int64 ) {
                self.id = id
            }
        }
        let ids  = [MiniCalling(5725983759238525), MiniCalling(63523098520934824), MiniCalling(72384029349323)]
        let parent = MiniCalling(789)
        
        let idMap  = ids.toDictionary({ ($0.id, parent.id) })
        
        XCTAssertEqual(idMap.count, 3)
        XCTAssertEqual(idMap[5725983759238525], 789)
        XCTAssertEqual(idMap[72384029349323], 789)
        XCTAssertNil(idMap[60])
    }
    
    func testContains() {
        let numbers = [55,88, 38284]
        XCTAssertTrue( numbers.contains( item: 88 ) )
        XCTAssertFalse( numbers.contains( item: 48 ) )
        
        let strings = [ "this", "is", "test"]
        XCTAssertTrue( strings.contains( item: "test" ) )
        XCTAssertFalse( strings.contains( item: "not" ) )
    }
    
    func testWithout() {
        let numbers = [55,88, 38284]
        XCTAssertEqual( numbers.without(subtractedItems: []).count, 3 )
        XCTAssertEqual( numbers.without(subtractedItems: [22, 101]).count, 3 )
        XCTAssertEqual( numbers.without(subtractedItems: [88]).count, 2 )
        XCTAssertEqual( numbers.without(subtractedItems: [38284, 88]).count, 1 )
        
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
