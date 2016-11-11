//
//  ModelTests.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 11/7/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import XCTest
import Calling_Workflow

class ModelTests: XCTestCase {
    
    var testJSON : [String:AnyObject]? = nil
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        if let filePath = Bundle.main.path(forResource: "cwf-object", ofType: "json") {
            let jsonData = Data( referencing: NSData(contentsOfFile: filePath)!)
            testJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
//                print( "JSON=" + (testJSON?.debugDescription)! )
            
        } else {
            print( "No File Path found for file" )
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testJsonSerialization() {
//        JSONSerialization.jsonObject(with: <#T##Data#>, options: <#T##JSONSerialization.ReadingOptions#>)
        let org = Org.parseFrom( (testJSON?["org"] as? JSONObject)! )
        print( org.debugDescription )
        

        XCTAssert( true )
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
