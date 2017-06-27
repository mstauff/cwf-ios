//
//  MultiValueDictionaryTests.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 6/14/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import XCTest
@testable
import Calling_Workflow

class MultiValueDictionaryTests: XCTestCase {
    
    var mvd : MultiValueDictionary<String, Int> = MultiValueDictionary()
    
    override func setUp() {
        super.setUp()
        mvd = MultiValueDictionary()
        mvd.setValues(forKey: "four", values: [4,5])
        mvd.addValue( forKey: "ten", value: 10 )
        mvd.setValues( forKey: "empty", values: [] )
       // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testAddValue() {
        // should add the value if it doesn't exist
        mvd.addValue(forKey: "one", value: 1)
        XCTAssertEqual( mvd.getValues(forKey: "one"), [1] )
        
        // should add to the list if the key already exists
        mvd.addValue(forKey: "one", value: 2)
        XCTAssertEqual( mvd.getValues(forKey: "one"), [1,2] )
        
    }
    
    func testSetValue() {
        var oldVals = mvd.setValues(forKey: "three", values: [3,4])
        XCTAssertEqual( mvd.getValues(forKey: "three"), [3,4] )
        XCTAssertEqual( oldVals, [] )

         oldVals = mvd.setValues(forKey: "three", values: [33,34])
        XCTAssertEqual( mvd.getValues(forKey: "three"), [33,34] )
        XCTAssertEqual( oldVals, [3,4] )
        
    }
    
    func testGetSingleValue() {
        XCTAssertNil( mvd.getSingleValue(forKey: "not in dictionary"))
        XCTAssertEqual( mvd.getSingleValue(forKey: "ten"), 10)
        XCTAssertEqual( mvd.getSingleValue(forKey: "four"), 4)
        XCTAssertNil( mvd.getSingleValue(forKey: "emptyValue") )
        
        
    }

    func testContains() {
        
        XCTAssertFalse( mvd.contains(key: "not in dictionary"))
        XCTAssertFalse( mvd.contains(key: "empty"))
        XCTAssertTrue( mvd.contains(key: "four"))
        XCTAssertTrue( mvd.contains(key: "ten"))
        
    }
    
    func testRemoveValue() {
        mvd.addValue(forKey: "four", value: 6)
        XCTAssertEqual( mvd.getValues(forKey: "four"), [4,5,6])
        
        // ensure remove behaves when we try to remove value not in the list
        mvd.removeValue(forKey: "four", value: 13)
        XCTAssertEqual( mvd.getValues(forKey: "four"), [4,5,6])
        // test that we can remove a single value
        mvd.removeValue(forKey: "four", value: 5)
        XCTAssertEqual( mvd.getValues(forKey: "four"), [4,6])
        
        // empty out the list and see if it behaves when the list is empty
        mvd.removeValue(forKey: "four", value: 4)
        mvd.removeValue(forKey: "four", value: 6)
        XCTAssertEqual( mvd.getValues(forKey: "four"), [] )

        mvd.removeValue(forKey: "four", value: 6)
        XCTAssertEqual( mvd.getValues(forKey: "four"), [] )
        
        // ensure remove doesn't choke if we try to remove something not in the list in the first place
        mvd.removeValue(forKey: "not in dictionary", value: 6)

    }
    
    // no need for tests for remove or removeAll since they just are direct calls to dict.removeXXX()

    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
