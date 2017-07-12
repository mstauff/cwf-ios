//
//  FilterOptionsTests.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 7/6/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import XCTest
@testable
import Calling_Workflow

class FilterOptionsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFilterForAge() {
        let member10 = createMemberCallings(withId: 10, withAge: 10)
        let member15 = createMemberCallings(withId: 15, withAge: 15)
        let member30 = createMemberCallings(withId: 30, withAge: 30)
        let member60 = createMemberCallings(withId: 60, withAge: 60)
        let memberNoAge = createMemberCallings(withId: 70, withAge: 0)
        
        let memberList = [member10, member15, member30, member60, memberNoAge]
        var filterOptions = FilterOptionsObject()
        
        // list should not be changed with no filter options
        var filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, memberList)
        
        
        // filter with a min age - no max
        filterOptions.minAge = 12
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [member15, member30, member60])
        
        // filter with max age, no min
        filterOptions.minAge = nil
        filterOptions.maxAge = 20
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [member10, member15])
        
        // filter with min & max, also ensure that the filter is <= or >=
        filterOptions.minAge = 15
        filterOptions.maxAge = 30
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [member15, member30])

        // nothing matching
        filterOptions.minAge = 65
        filterOptions.maxAge = 80
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssert(filteredList.isEmpty)
    }
    
    func testFilterForGender() {
        let male = MemberCallings( member: Member(indId: 100, name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: .Male, priesthood: nil, callings: []))
        let female = MemberCallings(member: Member(indId: 100, name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: .Female, priesthood: nil, callings: []))
        let badData = MemberCallings(member: Member(indId: 100, name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: nil, priesthood: nil, callings: []))
        let memberList = [male, female, badData]
        
        var filter = FilterOptionsObject()
        filter.gender = .Male
        var filteredList = filter.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [male])

        filter.gender = .Female
        filteredList = filter.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [female])
        
    }
    
    func testFilterForCallings() {
        let noCallings = createMemberCallings(withId: 1, withNumCallings: 0)
        let singleCalling = createMemberCallings(withId: 100, withNumCallings: 1)
        let twoCallings = createMemberCallings(withId: 200, withNumCallings: 2)
        let threeCallings = createMemberCallings(withId: 300, withNumCallings: 3)
        let fourCallings = createMemberCallings(withId: 400, withNumCallings: 4)
        var memberList = [noCallings, singleCalling, twoCallings, threeCallings, fourCallings]
        
        var filter = FilterOptionsObject()
        var filteredList = filter.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, memberList)

        // single criteria
        filter.callings = [0:false, 1:false, 2:true, 3: false]
        filteredList = filter.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [twoCallings])

        // single criteria - 3+
        filter.callings![2] = false
        filter.callings![3] = true
        filteredList = filter.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [threeCallings, fourCallings])
        
        // multiple criteria - 0 & 1
        filter.callings = [0:true, 1:true, 2:false, 3: false]
        filteredList = filter.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [noCallings, singleCalling])
        
        // criteria that's not in the list
        filter.callings![0]=false
        memberList.remove(at: 1)
        filteredList = filter.filterMemberData(unfilteredArray: memberList)
        XCTAssert(filteredList.isEmpty)
        
    }

    func testFilterForTimeInCalling() {
        let member10months = createMemberCallings(withId: 10, numMonthsInCallings: [10])
        let memberLongCallingEndList = createMemberCallings(withId: 15, numMonthsInCallings: [6,15])
        let memberLongCallingStartList = createMemberCallings(withId: 30, numMonthsInCallings: [15,6])
        let memberLongCallingMiddleList = createMemberCallings(withId: 60, numMonthsInCallings: [10,15,6])
        let memberNoCallings = createMemberCallings(withId: 70, numMonthsInCallings: [])
        
        let memberList = [member10months, memberLongCallingEndList, memberLongCallingStartList, memberLongCallingMiddleList, memberNoCallings]
        var filterOptions = FilterOptionsObject()
        
        // list should not be changed with no filter options
        var filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, memberList)
        
        
        // filter with nothing matching
        filterOptions.minMonthsInCalling = 20
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssert(filteredList.isEmpty)
        
        // filter with matches where the match is at start, end or middle
        filterOptions.minMonthsInCalling = 12
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [memberLongCallingEndList, memberLongCallingStartList, memberLongCallingMiddleList])
        
    }
    
    func testFilterForPriesthood() {
        let priestMember = createMemberCallings(withId: 100, withPriesthood: .Priest)
        let deaconMember = createMemberCallings(withId: 200, withPriesthood: .Deacon)
        let elderMember = createMemberCallings(withId: 300, withPriesthood: .Elder)
        let noPriesthoodMember = createMemberCallings(withId: 400, withAge: 40)
        
        let memberList = [priestMember, deaconMember, elderMember, noPriesthoodMember]
        
        var filterOptions = FilterOptionsObject()
        // options with just the desired priesthood set to true, the rest of the map is empty
        filterOptions.priesthood = [.Priest:true]
        var filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [priestMember])
        
        // multiple options set to true, but still rest of the map is empty
        filterOptions.priesthood![.Elder] = true
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [priestMember, elderMember])
        
        // multiple options - some true & some false
        filterOptions.priesthood = [.Deacon: true, .Teacher: true, .Priest: false, .Elder: true, .HighPriest: true, .Seventy: true]
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [deaconMember, elderMember])
    }
    
    func testFilterForClass() {
        // holding off on this for now, since currently we would have to do a bunch of age based setup that would all go away once we move to the longterm solution of pulling the data from a service
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func createMemberCallings( withId id: Int, withAge age: Int ) -> MemberCallings {
        var birthDate : Date? = nil
        if age > 0 {
            var ageComponents = DateComponents()
            ageComponents.year = -age
            birthDate = Calendar.current.date(byAdding: ageComponents, to: Date())
        }
        
        let member = Member(indId: Int64(id), name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: birthDate, gender: nil, priesthood: nil, callings: [])
        return MemberCallings(member: member)
    }
    
    func createMemberCallings( withId id: Int, withPriesthood priesthood: Priesthood ) -> MemberCallings {
        
        let member = Member(indId: Int64(id), name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: nil, priesthood: priesthood, callings: [])
        return MemberCallings(member: member)
    }

    func createMemberCallings( withId id: Int, withNumCallings numCallings: Int ) -> MemberCallings {
        let position = Position(positionTypeId: 100, name: "Teacher", hidden: false, multiplesAllowed: true, displayOrder: 100, metadata: PositionMetadata() )
        var callings : [Calling] = []
        if numCallings > 0 {
            for i in 1...numCallings {
                
                callings.append( Calling(id: Int64(id * 100 + i), cwfId: nil, existingIndId: Int64(id), existingStatus: .Active, activeDate: nil, proposedIndId: nil, status: nil, position:position, notes: nil, parentOrg: nil) )
            }
        }
        
        let member = Member(indId: Int64(id), name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: nil, priesthood: nil, callings: [])
        return MemberCallings(member: member, callings: callings, proposedCallings: [])
    }
    
    func createMemberCallings( withId id: Int, numMonthsInCallings: [Int] ) -> MemberCallings {
        let position = Position(positionTypeId: 100, name: "Teacher", hidden: false, multiplesAllowed: true, displayOrder: 100, metadata: PositionMetadata() )
        var callings : [Calling] = []
        if numMonthsInCallings.isNotEmpty {
            for (index, numMonths) in numMonthsInCallings.enumerated() {

                var timeInCalling = DateComponents()
                timeInCalling.month = -numMonths
                let activeDate = Calendar.current.date(byAdding: timeInCalling, to: Date())

                callings.append( Calling(id: Int64(id * 100 + index), cwfId: nil, existingIndId: Int64(id), existingStatus: .Active, activeDate: activeDate, proposedIndId: nil, status: nil, position:position, notes: nil, parentOrg: nil) )
            }
        }
        
        let member = Member(indId: Int64(id), name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: nil, priesthood: nil, callings: [])
        return MemberCallings(member: member, callings: callings, proposedCallings: [])
    }
    
    
}

extension MemberCallings : Equatable {
    static public func == (lhs : MemberCallings, rhs : MemberCallings ) -> Bool {
        
        return lhs.member.individualId == rhs.member.individualId
        
    }

}
