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
        var filterOptions = FilterOptions()
        
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
        let male = MemberCallings( member: Member(indId: 100, name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: .Male, priesthood: nil))
        let female = MemberCallings(member: Member(indId: 100, name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: .Female, priesthood: nil))
        let badData = MemberCallings(member: Member(indId: 100, name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: nil, priesthood: nil))
        let memberList = [male, female, badData]
        
        var filter = FilterOptions()
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
        
        var filter = FilterOptions()
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
        var filterOptions = FilterOptions()
        
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
        
        var filterOptions = FilterOptions()
        // options with just the desired priesthood set to true, the rest of the map is empty
        filterOptions.priesthood.append( .Priest)
        var filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [priestMember])
        
        // multiple options set to true, but still rest of the map is empty
        filterOptions.priesthood.append(.Elder)
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [priestMember, elderMember])
        
    }
    
    func testFilterForCallingStatus() {
        let proposedCalling = createMemberCallings(withId: 10, withPosition: PositionType.EQSecretary.rawValue, withStatus: .Proposed, withOrg: nil)
        let approvedCalling = createMemberCallings(withId: 20, withPosition: PositionType.EQSecretary.rawValue, withStatus: .Approved, withOrg: nil)
        let approvedCalling2 = createMemberCallings(withId: 25, withPosition: PositionType.EQ1stCounselor.rawValue, withStatus: .Approved, withOrg: nil)
        let extendedCalling = createMemberCallings(withId: 25, withPosition: PositionType.EQ1stCounselor.rawValue, withStatus: .Extended, withOrg: nil)
        
        let memberList = [proposedCalling, approvedCalling, approvedCalling2, extendedCalling]
        
        // no statuses specified, should get original list
        var filterOptions = FilterOptions()
        filterOptions.callingStatuses = []
        var filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual( filteredList, memberList )
        
        // status that doesn't match anything, should get empty list
        filterOptions.callingStatuses = [CallingStatus.Recorded]
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssert( filteredList.isEmpty )
        
        // status that matches 1 item
        filterOptions.callingStatuses = [CallingStatus.Extended]
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual( filteredList, [extendedCalling] )
        
        // single status that matches multiple items
        filterOptions.callingStatuses = [CallingStatus.Approved]
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual( filteredList, [approvedCalling, approvedCalling2] )
        
        // multiple statuses that match single item
        filterOptions.callingStatuses = [CallingStatus.Proposed, CallingStatus.AppointmentSet]
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual( filteredList, [proposedCalling] )
        
        
        // multiple statuses that match multiple items
        filterOptions.callingStatuses = [CallingStatus.Proposed, .Extended, .Refused]
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual( filteredList, [proposedCalling, extendedCalling] )
    }
    
    func testFilterForCallingOrg() {
        let bishopric = Org(id: 100, orgTypeId: 1, orgName: "Bishopric", displayOrder: 100, children: [], callings: [])
        let eqPresOrg = Org(id: 220, orgTypeId: 2, orgName: "EQ Presidency", displayOrder: 220, children: [], callings: [])
        let eqTeacherOrg = Org(id: 230, orgTypeId: 3, orgName: "EQ Teachers", displayOrder: 230, children: [], callings: [])
        let eqOrg = Org(id: 200, orgTypeId: 4, orgName: "EQ", displayOrder: 200, children: [eqPresOrg, eqTeacherOrg], callings: [])
        let rsOrg = Org(id: 300, orgTypeId: 5, orgName: "RS", displayOrder: 300, children: [], callings: [])
        
        let bishopricCalling = createMemberCallings(withId: 10, withPosition: PositionType.Bishopric1stCounselor.rawValue, withStatus: nil, withOrg: bishopric)
        let eqTeacherCalling = createMemberCallings(withId: 20, withPosition: 555, withStatus: nil, withOrg: eqTeacherOrg)
        let eqPresCalling = createMemberCallings(withId: 30, withPosition: PositionType.EQPres.rawValue, withStatus: nil, withOrg: eqPresOrg)
        let ssCalling = createMemberCallings(withId: 40, withPosition: PositionType.SSPres.rawValue, withStatus: nil, withOrg: nil)
        
        let callingList = [bishopricCalling, eqTeacherCalling, eqPresCalling, ssCalling]
        var filterOptions = FilterOptions()
        
        // list should not be changed with no filter options
        var filteredList = filterOptions.filterMemberData(unfilteredArray: callingList)
        XCTAssertEqual(filteredList, callingList)
        
        // when there's some orgs, but no matches you should get an empty list
        filterOptions.callingOrgs = rsOrg.allOrgIds
        filteredList = filterOptions.filterMemberData(unfilteredArray: callingList)
        XCTAssert(filteredList.isEmpty)
        
        // test callings that are a direct root org
        filterOptions.callingOrgs = bishopric.allOrgIds
        filteredList = filterOptions.filterMemberData(unfilteredArray: callingList)
        XCTAssertEqual(filteredList, [bishopricCalling])
        
        // test multiple matches in child orgs
        filterOptions.callingOrgs = eqOrg.allOrgIds
        filteredList = filterOptions.filterMemberData(unfilteredArray: callingList)
        XCTAssertEqual(filteredList, [eqTeacherCalling, eqPresCalling])
        
        // test with multiple orgs ID's in the filter
        filterOptions.callingOrgs = eqOrg.allOrgIds + bishopric.allOrgIds
        filteredList = filterOptions.filterMemberData(unfilteredArray: callingList)
        XCTAssertEqual(filteredList, [bishopricCalling, eqTeacherCalling, eqPresCalling])
    }
    
    func testFilterForClass() {
        // holding off on this for now, since currently we would have to do a bunch of age based setup that would all go away once we move to the longterm solution of pulling the data from a service
        
    }
    
    func testMultipleFilters() {
        let member10Male = createMemberCallings(withId: 10, withAge: 10, withGender: .Male)
        let member15Female = createMemberCallings(withId: 15, withAge: 15, withGender: .Female)
        let member30Male = createMemberCallings(withId: 30, withAge: 30, withGender: .Male)
        let member30Female = createMemberCallings(withId: 30, withAge: 30, withGender: .Female)
        let member60Male = createMemberCallings(withId: 60, withAge: 60, withGender: .Male)
        let member60Female = createMemberCallings(withId: 60, withAge: 60, withGender: .Female)
        let memberNoAge = createMemberCallings(withId: 70, withAge: 0)
        
        let memberList = [member10Male, member15Female, member30Male, member30Female, member60Male, member60Female, memberNoAge]
        var filterOptions = FilterOptions()
        
        // list should not be changed with no filter options
        var filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, memberList)
        
        // ensure filter is applied as an && not || - results need to match all the criteria
        filterOptions.minAge = 15
        filterOptions.maxAge = 30
        filterOptions.gender = .Male
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [member30Male])
        
        filterOptions.gender = .Female
        filteredList = filterOptions.filterMemberData(unfilteredArray: memberList)
        XCTAssertEqual(filteredList, [member15Female, member30Female])
    }
    


    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    func createMemberCallings( withId id: Int, withAge age: Int, withGender gender: Gender? ) -> MemberCallings {
        var birthDate : Date? = nil
        if age > 0 {
            var ageComponents = DateComponents()
            ageComponents.year = -age
            birthDate = Calendar.current.date(byAdding: ageComponents, to: Date())
        }
        
        let member = Member(indId: Int64(id), name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: birthDate, gender: gender, priesthood: nil)
        return MemberCallings(member: member)
    }

    func createMemberCallings( withId id: Int, withAge age: Int ) -> MemberCallings {
        return createMemberCallings(withId: id, withAge: age, withGender: nil)
    }
    
    func createMemberCallings( withId id: Int, withPriesthood priesthood: Priesthood ) -> MemberCallings {
        
        let member = Member(indId: Int64(id), name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: nil, priesthood: priesthood)
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
        
        let member = Member(indId: Int64(id), name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: nil, priesthood: nil)
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
        
        let member = Member(indId: Int64(id), name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: nil, priesthood: nil)
        return MemberCallings(member: member, callings: callings, proposedCallings: [])
    }

    func createMemberCallings( withId id: Int, withPosition positionId: Int, withStatus status: CallingStatus?, withOrg parentOrg : Org? ) -> MemberCallings {
        let position = Position(positionTypeId: positionId, name: "Calling", hidden: false, multiplesAllowed: false, displayOrder: 100, metadata: PositionMetadata() )
        let calling = Calling(id: Int64(id * 100), cwfId: nil, existingIndId: 100, existingStatus: .Active, activeDate: nil, proposedIndId: Int64(id), status: status, position:position, notes: nil, parentOrg: parentOrg)
        
        let member = Member(indId: Int64(id), name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: nil, priesthood: nil)
        return MemberCallings(member: member, callings: [], proposedCallings: [calling])
    }
    

    
}

extension MemberCallings : Equatable {
    static public func == (lhs : MemberCallings, rhs : MemberCallings ) -> Bool {
        
        return lhs.member.individualId == rhs.member.individualId
        
    }

}
