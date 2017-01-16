//
//  MemberTests.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 12/14/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import XCTest
@testable
import Calling_Workflow

class MemberTests: XCTestCase {
    
    var testJSON : [String:AnyObject]? = nil
    var memberMap : [Int64:Member] = [:]
    
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
        if let filePath = bundle.path(forResource: "member-objects", ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            testJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
        } else {
            print( "No File Path found for file" )
        }
        
        let htvtParser = HTVTMemberParser()
        let memberList = testJSON?["families"] as? [JSONObject]
        memberList?.forEach() { familyJson in
            let familyMembers = htvtParser.parseFamilyFrom( json: familyJson )
            familyMembers.forEach() { member in
                memberMap[ member.individualId ] = member
            }
        }
    }
    
    func testAgeFilter() {
        let htvtParser = HTVTMemberParser()
        let memberJSON = testJSON?["families"] as? [JSONObject]
        [true, false].forEach() { includeChildren in
            var memberList : [Member] = []
            // parse the members, either including or excluding children
            memberJSON?.forEach() { familyJson in
                let familyMembers = htvtParser.parseFamilyFrom( json: familyJson, includeChildren: includeChildren )
                memberList.append(contentsOf: familyMembers)
            }
            // count how many members are under age.
            let underageMemberCount = memberList.reduce(0) { (count, member) in
                guard let age = member.age else {
                    return count
                }
                return  count + age <= MemberConstants.minimumAge ? 1 : 0
            }
            if includeChildren {
                // if children are included there should be 1 or more children in the list
                XCTAssertGreaterThan(underageMemberCount, 0)
            } else {
                // if children are not included there should be 0
                XCTAssertEqual(underageMemberCount, 0)
            }
            // if the json file gets modified so there aren't any children in the list then this test will fail until a child is added back in. Also note the age in the file is not dynamic so in 2026 this test will start to fail as well :)
            
        }
        
    }
    
    
    /*
     Tests that a household with a single member is correctly parsed. Also tests name, individual phone & email, birthdate, age, gender and null priesthood.
     */
    //TODO: would be good to add a family where the only member is in the spouse position rather than HOH
    func testSingleMemberFromJson() {
        let singleHOHMember = memberMap[8999999998963918]
        
        XCTAssertEqual( singleHOHMember?.name, "AFPEighteen, Member" )
        // test has ind phone & household phone. Should get individual
        XCTAssertEqual( singleHOHMember?.phone, "1112223333" )
        // test has ind email & hh email, should get individual
        XCTAssertEqual( singleHOHMember?.email, "ind@email.com" )
        // test has no address, want to make sure we don't have "nil, nil nil"
        XCTAssertEqual( singleHOHMember?.streetAddress.count, 0 )
        
        let hohBirthDate = Date( year: 1960, month: 11, day: 11 )
        XCTAssertEqual( Calendar.current.compare( (singleHOHMember?.birthdate!)!, to: hohBirthDate, toGranularity: .day ), .orderedSame )
        let expectedAge = Calendar.current.dateComponents([.year], from: hohBirthDate, to: Date()).year
        XCTAssertEqual( singleHOHMember?.age, expectedAge )
        
        XCTAssertEqual( singleHOHMember?.gender, .Female )
        XCTAssertNil( singleHOHMember?.priesthood )
        
    }
    
    /*
     Tests that a couple with no children are parsed correctly. Also validates null/empty phone, email, birthdate & priesthood are handled. Validates that the individual phone & email work when HH phone/email are null, and that the city state and zip are formatted properly when there is no city in street 2
     */
    func testCoupleFromJson() {
        let hoh = memberMap[-1]
        
        XCTAssertEqual( hoh?.name, "AFPTwo, Husband" )
        // individual phone is empty & home is null
        XCTAssertNil( hoh!.phone )
        // individual email is empty & home is null
        XCTAssertNil( hoh!.email )
        // should have an address
        XCTAssertGreaterThan( hoh!.streetAddress.count, 0 )
        XCTAssertEqual( hoh!.streetAddress[0], "123 Any Street" )
        XCTAssertEqual( hoh!.streetAddress[1], "Provo, UT 55555" )
        
        XCTAssertNil( hoh!.birthdate )
        XCTAssertNil( hoh!.age )
        
        XCTAssertEqual( hoh?.gender, .Male )
        XCTAssertNil( hoh!.priesthood )
        
        let spouse = memberMap[8999999998987510]
        XCTAssertEqual( spouse?.name, "AFPTwo, Wife" )
        // individual phone is set & home is null
        XCTAssertEqual( spouse!.phone, "555-SPOUSE-PHONE" )
        // individual email is set & home is null
        XCTAssertEqual( spouse!.email, "spouse@email.com" )
        // should have an address
        XCTAssertGreaterThan( spouse!.streetAddress.count, 0 )
        XCTAssertEqual( spouse?.gender, .Female )
    }
    
    /*
     Validates that children are parsed when included. Validates that the home phone is used if no individual phone is set. Validates that when address 2 already contains the city & state that we don't append it again.
     */
    //TODO: there are a few other variants here that could be tested, like city is contained in address2, but state is not, and vice versa
    func testChildrenFromJSON() {
        let hoh = memberMap[11111]
        let spouse = memberMap[22222]
        let child1 = memberMap[33333]
        let child2 = memberMap[44444]
        
        XCTAssertNotNil( hoh )
        XCTAssertNotNil( spouse )
        XCTAssertNotNil( child1 )
        XCTAssertNotNil( child2 )
        
        XCTAssertEqual( child1?.name, "AFPEleven, Child" )
        // individual phone is empty, fallback to home
        XCTAssertEqual( hoh!.phone, "444-HOME-PHONE" )
        XCTAssertEqual( child1!.phone, "444-HOME-PHONE" )
        // individual email is empty, fallback to home
        XCTAssertEqual( hoh!.email, "hh@email.com" )
        XCTAssertEqual( child1!.email, "hh@email.com" )
        // should have an address - this tests the case where the city is already in street address 2 and in the city field
        XCTAssertGreaterThan( hoh!.streetAddress.count, 0 )
        XCTAssertEqual( hoh!.streetAddress[1], "Savali, Tonga" )
        // shouldn't have any more address fields
        XCTAssertEqual( hoh!.streetAddress.count, 2 )
        
        XCTAssertEqual( child1!.gender, .Male )
        XCTAssertEqual( child1!.priesthood, .Deacon )
        
        XCTAssertEqual( child2!.name, "AFPEleven, Child2")
        
    }
    
    /*
     Validates that city state and zip are combined correctly into a single string. Since some LDS.org services don't provide discrete city, state, zip fields, we've modeled the member object to just have an array of strings for the address. HTVT does provide city state and zip, so we'll need to combine them. This method validates that if there is no city we don't get ", UT 58585", or that when we have all elements they are formatted correctly
     */
    func testAddressString() {
        let htvtParser = HTVTMemberParser()
        XCTAssertNil( htvtParser.addressString(city: nil, state: nil, zip: nil))
        
        XCTAssertEqual(htvtParser.addressString(city: nil, state: "State", zip: nil), "State " )
        XCTAssertEqual(htvtParser.addressString(city: "", state: "State", zip: ""), "State " )
        XCTAssertEqual(htvtParser.addressString(city: nil, state: "State", zip: "5555"), "State 5555" )
        XCTAssertEqual(htvtParser.addressString(city: "City", state: "State", zip: "5555"), "City, State 5555" )
        XCTAssertEqual(htvtParser.addressString(city: "City", state: nil, zip: "5555"), "City, 5555" )
        XCTAssertEqual(htvtParser.addressString(city: "City", state: nil, zip: nil), "City" )
        XCTAssertEqual(htvtParser.addressString(city: "City", state: "", zip: ""), "City" )
    }
    
    /*
     Since we couldn't use the default initializers for the enums, I'm adding a test to make sure they are correctly initialized from Strings
     */
    func testPriesthoodEnum() {
        let invalidVals : [String?] = [ nil, "", "foo" ]
        invalidVals.forEach() { val in
            XCTAssertNil( Priesthood( optionalRaw: val ) )
        }
        
        let validVals : [String:Priesthood] = ["DEACON": .Deacon, "TEACHER": .Teacher, "PRIEST": .Priest, "ELDER": .Elder, "HIGH_PRIEST": .HighPriest, "SEVENTY": .Seventy]
        
        validVals.forEach() { key, value in
            XCTAssertEqual( Priesthood(rawValue: key ), value )
            XCTAssertEqual( Priesthood(optionalRaw: key ), value )
            
        }
        
        
        
    }
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
