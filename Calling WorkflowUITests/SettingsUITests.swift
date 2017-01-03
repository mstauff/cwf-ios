//
//  SettingsUITests.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/22/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import XCTest

class SettingsUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()
        XCUIApplication().tables.staticTexts["Sign in"].tap()
        
        XCUIApplication().tabBars.buttons["Settings"].tap()
       
        
        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    func testTableView() {
        XCTAssert(XCUIApplication().tables.count == 1)
        XCTAssert(XCUIApplication().tables.cells.count == 3)

    }
    
    func testTableViewCells() {
        
        let app = XCUIApplication()
        let tablesQuery = app.tables
        tablesQuery.staticTexts["Sign in"].tap()
        app.tabBars.buttons["Settings"].tap()
        tablesQuery.staticTexts["LDS.org credentials"].tap()
        XCTAssert(app.navigationBars["Log in"].exists)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNavigationItem() {
        //let navigationItem = XCUIApplication.
    }
        
}
