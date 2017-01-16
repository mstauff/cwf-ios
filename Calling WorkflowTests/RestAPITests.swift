//
//  RestAPITests.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 1/9/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import XCTest
@testable
import Calling_Workflow


class RestAPITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testToHttpParams() {
        // empty params
        XCTAssertEqual( RestAPI.toHttpParams(from:[:]), "" )
        
        // single param - ensure no trailing &
        XCTAssertEqual(RestAPI.toHttpParams(from: ["username":"bob"]), "username=bob")
        // multiples params - ensure &
        XCTAssertEqual(RestAPI.toHttpParams(from: ["username":"bob", "password":"secret"]), "username=bob&password=secret")
        
        
    }
    
    func toHttpParms( methodInput : [String:String], expectedResult : String )  {
        
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
