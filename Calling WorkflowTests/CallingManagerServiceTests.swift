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

    var callingMgr : PartialMockCallingManager = PartialMockCallingManager()
    let mockDataSource = MockDataSource()
    var org : Org?
    var positionsOrg : Org?
    var lcrOrg = Org( id: 111, unitNum: 111, orgTypeId: UnitLevelOrgType.Ward.rawValue )
    var appOrg  = Org( id: 111,unitNum: 111, orgTypeId: UnitLevelOrgType.Ward.rawValue )

    class MockPermissionMgr : PermissionManager {
        override func isAuthorized(unitRoles: [UnitRole], domain: Domain, permission: Permission, targetData: Authorizable) -> Bool {
            return true
        }
    }
    
    class PartialMockCallingManager : CWFCallingManagerService {
        var mockGoogleOrg : Org? = nil
        
        override func getOrgData(forOrgId orgId: Int64, completionHandler: @escaping (Org?, Error?) -> Void) {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                completionHandler(self.mockGoogleOrg, nil)
            }

            return
        }
        
        override func unitLevelOrgType( forOrg: Int64 ) -> UnitLevelOrgType? {
            return .Primary
        }
    }
    
    class MockDataSource : DataSource {
        var isAuthenticated: Bool {
            get {
                return true
            }
        }
        func hasValidCredentials( forUnit unitNum : Int64, completionHandler: @escaping (Bool, Error?) -> Void ) {
            completionHandler( true, nil )
        }
        
        func initializeDrive(forOrgs orgs: [Org], completionHandler: @escaping(_ remainingOrgs: [Org], _ error: Error?) -> Void) {
            completionHandler( [], nil )
        }
        
        func getData( forOrg : Org, completionHandler : @escaping (_ org : Org?, _ error: Error? ) -> Void ) {
            completionHandler( forOrg, nil )
        }
        
        func updateOrg( org : Org, completionHandler : @escaping (_ success : Bool, _ error: Error? ) -> Void ) {
            completionHandler( true, nil )
        }
        
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        org = getOrgFromFile(fileName: "cwf-object", orgJsonName: "orgWithCallingsInSubOrg")!
        lcrOrg.children = getOrgsFromFile(fileName: "reconcile-test-orgs", orgJsonName: "lcrOrg")
        appOrg.children = getOrgsFromFile(fileName: "reconcile-test-orgs", orgJsonName: "appOrg")
        positionsOrg = getSingleOrgFromFile(fileName: "org-callings")
        
        callingMgr = PartialMockCallingManager(org: nil, iMemberArray: [], permissionMgr: MockPermissionMgr() )
        InjectionMap.dataSource = mockDataSource
        
        callingMgr.mockGoogleOrg = org
        super.setUp()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func getOrgFromFile( fileName: String, orgJsonName: String ) -> Org? {
        var result : Org? = nil
        let bundle = Bundle( for: type(of: self) )
        if let filePath = bundle.path(forResource: fileName, ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            let testJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
            result = Org( fromJSON: (testJSON?[orgJsonName] as? JSONObject)! )
            
        } else {
            print( "No File Path found for file" )
        }

        return result
    }

    func getSingleOrgFromFile( fileName: String ) -> Org? {
        var result = Org(id: 111, unitNum: 111, orgTypeId: UnitLevelOrgType.Ward.rawValue)
        let bundle = Bundle( for: type(of: self) )
        if let filePath = bundle.path(forResource: fileName, ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            let testJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [AnyObject]
            result.children = Org.orgArrays( fromJSONArray: (testJSON as? [JSONObject])! )
            
        } else {
            print( "No File Path found for file" )
        }
        
        return result
    }
    
    func getOrgsFromFile( fileName: String, orgJsonName: String ) -> [Org] {
        var result : [Org] = []
        let bundle = Bundle( for: type(of: self) )
        if let filePath = bundle.path(forResource: fileName, ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            let testJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
            result = Org.orgArrays( fromJSONArray: (testJSON?[orgJsonName] as? [JSONObject])! )
            
        } else {
            print( "No File Path found for file" )
        }
        
        return result
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
    
    func testOrgPositions() {
        let testOrg = positionsOrg!
        let bishopric = testOrg.getChildOrg(id: 555)!
        let bishopricPositions = bishopric.validPositions
        XCTAssertEqual( bishopricPositions.count, 4 )
        XCTAssertTrue( bishopric.potentialNewPositions.isEmpty )
        
        
        var hpGroup = testOrg.getChildOrg(id: 2381009)!
        var positionTypeIds : [Int] = hpGroup.validPositions.map() {$0.positionTypeId}
        XCTAssertEqual( positionTypeIds.count, 5 )
        // ensure it has a position that's currently empty
        XCTAssertTrue( positionTypeIds.contains(item: 3635) )
        XCTAssertEqual( positionTypeIds.count, 5 )
        // there should be one position (Asst. Sec.) that's a potential for adding.
        XCTAssertEqual( hpGroup.potentialNewPositions.count, 1 )
        XCTAssertEqual( hpGroup.potentialNewPositions[0].positionTypeId, 3635 )
        // remove the president - then that position should show up in the list of potentials to be added
        hpGroup.callings.remove( at: 0 )
        XCTAssertEqual( hpGroup.potentialNewPositions.count, 2 )
        XCTAssertEqual( hpGroup.potentialNewPositions[1].positionTypeId, 133 )
        
        
        
        
        // ensure we only have one when there are multiples
        let hpInstructors = testOrg.getChildOrg(id: 4124695)!
        positionTypeIds = hpInstructors.validPositions.map() {$0.positionTypeId}
        // 2 callings, but only 1 type of position
        XCTAssertEqual( hpInstructors.callings.count, 2 )
        XCTAssertEqual( hpInstructors.potentialNewPositions.count, 1 )
        XCTAssertEqual( positionTypeIds.count, 1 )
        XCTAssertTrue( positionTypeIds.contains(item: 137) )
    }
    
    func testReconcileCallings() {
        // create a reconcileAppOrg & reconcileLdsOrg in the json file
        // read them in, pass to reconcileCallings & validate
            let reconciledOrg = callingMgr.reconcileOrg(appOrg: appOrg, ldsOrg: lcrOrg)
        let primaryOrg = reconciledOrg.getChildOrg(id: 7428354)!
        XCTAssertEqual( primaryOrg.children.count, 3 )
        let ctr7 = reconciledOrg.getChildOrg(id: 38432972)!
        // app & lcr both have 2 callings - but one of them has changed so it will appear as 3 callings, with one of them marked with a conflict for deletion
        XCTAssertEqual( ctr7.callings.count, 3 )
        
        // one should not have changed
        let sameCalling = ctr7.callings.first() { $0.id == 734829 }!
        XCTAssertEqual(sameCalling.existingIndId, 123)
        XCTAssertNil( sameCalling.proposedIndId )
        
        // one should be marked for deletion
        let oldCalling = ctr7.callings.first() { $0.id == 734820 }!
        XCTAssertEqual( oldCalling.existingIndId, 222 )
            XCTAssertEqual( oldCalling.conflict, ConflictCause.LdsEquivalentDeleted )
        // the other should be the new one
        let updatedCalling = ctr7.callings.first() { $0.id == 734821 }!
        XCTAssertEqual( updatedCalling.existingIndId, 234 )
        
        // someone was released outside the app - no replacement
        let ctr8 = reconciledOrg.getChildOrg(id: 752892)!
        let callingReleasedInLcr = ctr8.callings[0]
        XCTAssertEqual( callingReleasedInLcr.conflict, .LdsEquivalentDeleted )
        let callingDeletedInLcr = ctr8.callings[1]
        XCTAssertEqual( callingDeletedInLcr.conflict, .LdsEquivalentDeleted )
        
        let ctr9 = reconciledOrg.getChildOrg(id: 750112)
        XCTAssertNotNil( ctr9 )
        
        let varsityOrg = reconciledOrg.getChildOrg(id: 839510)!
        // varsity coach was finalized outside the app. ensure that the proposed version was deleted
        XCTAssertEqual(varsityOrg.callings.count, 1)
        let varsityCoach = varsityOrg.callings[0]
        XCTAssertEqual(varsityCoach.position.positionTypeId, 1459)
        XCTAssertEqual(varsityCoach.existingIndId, 890)
        XCTAssertNil(varsityCoach.proposedIndId)
        XCTAssertEqual(varsityCoach.proposedStatus, .Unknown)
        
        let scoutOrg = reconciledOrg.getChildOrg(id: 839500)!
        XCTAssertEqual(scoutOrg.allOrgCallings.count, 2)
        // validate that a new calling added in LCR shows up
        XCTAssertEqual(scoutOrg.callings.count, 1)
        let newCalling = scoutOrg.callings[0]
        XCTAssertEqual(newCalling.id, 14727)
        XCTAssertEqual(newCalling.existingIndId, 789)
        
        // todo - outstanding test cases
        // - proposed & actual with different person - should be merged
        // - variations with multiple allowed
        // - callings are same - except app has notes
    }
    
    func testAddCalling() {
        let primaryOrg = org!
        let unitOrg = Org(id: 123,unitNum: 123, orgTypeId: 7, orgName: "Test Ward", displayOrder: 0, children: [primaryOrg], callings: [])
        callingMgr.initLdsOrgData(memberList: [], org: unitOrg, positionMetadata: [:])
        callingMgr.initDatasourceData(fromOrg: unitOrg, extraOrgs: [])
        // todo - need a mock callingMgr.dataSource with mocked updateOrg() method
        let ctr8 = primaryOrg.getChildOrg(id: 752892)!

        let primaryTeacherPos = Position(positionTypeId: 1481, name: "Primary Teacher", hidden: false, multiplesAllowed: true, displayOrder: nil, metadata: PositionMetadata())
        
        // Add a calling for a member with a calling - see if we correctly get both active callings
        // NOTE: currently not a valid test case, you only add a proposed calling, not an active callings. Active callings go through the update to LCR
        var calling = Calling(id: 123, cwfId: nil, existingIndId: 123, existingStatus: nil, activeDate: nil, proposedIndId: nil, status: nil, position: primaryTeacherPos, notes: nil, parentOrg: ctr8)
        
        // Add a calling for a member with a potential calling - see if we correctly get both potential callings
        calling = Calling(id: nil, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: 456, status: .Proposed, position: primaryTeacherPos, notes: nil, parentOrg: ctr8)
        let memberWithMultipleProposedCallings = createMember(withId: 456)
        let addPotentialCallingExpectation = self.expectation( description: "Add a potential calling for a member that already has a potential calling")
        
        callingMgr.addCalling(calling: calling) { _, _ in
            XCTAssertEqual( self.callingMgr.getCallings(forMember: memberWithMultipleProposedCallings).count, 0 )
            XCTAssertEqual( self.callingMgr.getPotentialCallings(forMember: memberWithMultipleProposedCallings).count, 2)
            addPotentialCallingExpectation.fulfill()
        }
        
        // add a potential calling for a member with an active calling, make sure we get both
        calling = Calling(id: nil, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: 678, status: .Proposed, position: primaryTeacherPos, notes: nil, parentOrg: ctr8)
        let memberWithBothTypesCallings = createMember(withId: 678)
        let addPotentialToActiveExpectation = self.expectation(description: "Add a potential calling to a member that has an active calling")
        callingMgr.addCalling(calling: calling) { _, _ in
            XCTAssertEqual( self.callingMgr.getCallings(forMember: memberWithBothTypesCallings).count, 2 )
            XCTAssertEqual( self.callingMgr.getPotentialCallings(forMember: memberWithBothTypesCallings).count, 1)
            addPotentialToActiveExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)        
       
    }

    func testDeleteCalling() {
        let primaryOrg = org!
        let unitOrg = Org(id: 123, unitNum: 123, orgTypeId: 7, orgName: "Test Ward", displayOrder: 0, children: [primaryOrg], callings: [])
        callingMgr.initLdsOrgData(memberList: [], org: unitOrg, positionMetadata: [:])
        callingMgr.initDatasourceData(fromOrg: unitOrg, extraOrgs: [])
        // todo - need a mock callingMgr.dataSource with mocked updateOrg() method
        let ctr8 = primaryOrg.getChildOrg(id: 752892)!
        
        let primaryTeacherPos = Position(positionTypeId: 1481, name: "Primary Teacher", hidden: false, multiplesAllowed: true, displayOrder: nil, metadata: PositionMetadata())
        
        // Add a second calling for a member with a potential calling, so we can delete and make sure we still have at least one
        let calling = Calling(id: nil, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: 456, status: .Proposed, position: primaryTeacherPos, notes: nil, parentOrg: ctr8)
        let memberWithMultipleProposedCallings = createMember(withId: 456)
        let deleteValidCallingExpectation = self.expectation( description: "delete a potential calling for a member that has multiple potential calling")
        
        callingMgr.addCalling(calling: calling) { _, _ in
            XCTAssertEqual( self.callingMgr.getCallings(forMember: memberWithMultipleProposedCallings).count, 0 )
            XCTAssertEqual( self.callingMgr.getPotentialCallings(forMember: memberWithMultipleProposedCallings).count, 2)
            self.callingMgr.deleteCalling(calling: calling ) { success, error in
                XCTAssert( success )
                XCTAssertNil( error )
                XCTAssertEqual( self.callingMgr.getPotentialCallings(forMember: memberWithMultipleProposedCallings).count, 1)
                deleteValidCallingExpectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5)
        
    }

    func testDeleteNonCalling() {
        let primaryOrg = org!
        let unitOrg = Org(id: 123, unitNum: 123, orgTypeId: 7, orgName: "Test Ward", displayOrder: 0, children: [primaryOrg], callings: [])
        callingMgr.initLdsOrgData(memberList: [], org: unitOrg, positionMetadata: [:])
        callingMgr.initDatasourceData(fromOrg: unitOrg, extraOrgs: [])
        // todo - need a mock callingMgr.dataSource with mocked updateOrg() method
        let ctr8 = primaryOrg.getChildOrg(id: 752892)!
        let originalCallings = primaryOrg.allOrgCallings
        
        let ctr9TeacherPos = Position(positionTypeId: 1485, name: "Some other Teacher", hidden: false, multiplesAllowed: true, displayOrder: nil, metadata: PositionMetadata())
        let member = createMember(withId: 456)
        
        // try a delete for a calling that doesn't exist
        let calling = Calling(id: nil, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: 456, status: .Proposed, position: ctr9TeacherPos, notes: nil, parentOrg: ctr8)
        let deleteInvalidExpectation = self.expectation(description: "remove a calling that doesn't exist")
        callingMgr.deleteCalling(calling: calling) { success, error in
            // make sure that the calling they do have was not affected
            XCTAssertEqual( self.callingMgr.getPotentialCallings(forMember: member).count, 1 )
            let postChangeCallings = self.callingMgr.appDataOrg?.getChildOrg(id: primaryOrg.id)!.allOrgCallings
            // todo - validate this test is correct
            XCTAssertEqual(originalCallings, postChangeCallings!)
            deleteInvalidExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        
    }

    func testUpdateCalling() {
        let bishopric = getOrgFromFile(fileName: "cwf-object", orgJsonName: "orgWithDirectCallings")!

        let unitOrg = Org(id: 123, unitNum: 123, orgTypeId: 7, orgName: "Test Ward", displayOrder: 0, children: [bishopric], callings: [])
        callingMgr.initLdsOrgData(memberList: [], org: unitOrg, positionMetadata: [:])
        callingMgr.initDatasourceData(fromOrg: unitOrg, extraOrgs: [])
        callingMgr.mockGoogleOrg = bishopric
        
        var bishopCalling = bishopric.callings[0]
        let originalProposed = bishopCalling.proposedIndId!
        let updatedProposed = originalProposed + 111
        let updateCallingExpectation = self.expectation( description: "update a potential calling")
        
        bishopCalling.proposedIndId = updatedProposed
        
        callingMgr.updateCalling(updatedCalling: bishopCalling ) { success, error in
            XCTAssert( success )
            XCTAssertNil( error )
            // make sure the potential calling cache has the new calling
            bishopCalling = self.callingMgr.getPotentialCallings(forMember: self.createMember(withId: updatedProposed))[0]
            XCTAssertEqual( bishopCalling.proposedIndId, updatedProposed )
            
            // and the old calling doesn't have the proposed any more
            let oldMemberCallings = self.callingMgr.getPotentialCallings(forMember: self.createMember(withId: originalProposed))
            XCTAssert( oldMemberCallings.isEmpty )
            
            // the org data
            bishopCalling = (self.callingMgr.appDataOrg?.children[0].callings[0])!
            XCTAssertEqual( bishopCalling.proposedIndId, updatedProposed )

            updateCallingExpectation.fulfill()
        }
        
        waitForExpectations(timeout: 5)
        
    }


    func createMember( withId id: Int64 ) -> Member {
        return Member(indId: id, name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: nil, priesthood: nil)
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
