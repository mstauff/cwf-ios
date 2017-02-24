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

    override func setUp() {
        let bundle = Bundle( for: type(of: self) )
        if let filePath = bundle.path(forResource: "cwf-object", ofType: "js"),
           let fileData = NSData(contentsOfFile: filePath) {

            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            let testJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
            org = Org( fromJSON: (testJSON?["orgWithCallingsInSubOrg"] as? JSONObject)! )

        } else {
            print( "No File Path found for file" )
        }
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
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

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
