//
//  Calling_WorkflowUITests.swift
//  Calling WorkflowUITests
//
//  Created by Matt Stauffer on 9/21/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import XCTest

class Calling_WorkflowUITests: XCTestCase {
    
    var testJSONData : [String:AnyObject]? = nil

    override func setUp() {
        super.setUp()
        print(self.debugDescription)
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        setDeviceInitalState()
        XCTAssert(testJSONData != nil)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func setDeviceInitalState() {
        if let filePath = Bundle(for: type(of: self)).path(forResource: "cwf-object", ofType: "js") {
            let jsonData = Data( referencing: NSData(contentsOfFile: filePath)!)
            testJSONData = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
        } else {
            print( "No File Path found for file" )
        }

    }
    
}
