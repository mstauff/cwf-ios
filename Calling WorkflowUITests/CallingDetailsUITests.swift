//
//  CallingDetailsUITests.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 9/1/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import XCTest

class CallingDetailsUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        

        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSomething() {
        let tablesQuery = XCUIApplication().tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Elders Quorum"]/*[[".cells.staticTexts[\"Elders Quorum\"]",".staticTexts[\"Elders Quorum\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Instructors"]/*[[".cells.staticTexts[\"Instructors\"]",".staticTexts[\"Instructors\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        XCUIApplication().navigationBars["Elders Quorum"].otherElements["Elders Quorum"].tap()
        
        //XCTAssert(XCUIApplication().navigationBars.otherElements, <#T##message: String##String#>)
        
    }
}
