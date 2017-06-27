//
//  ModelTests.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 11/7/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import XCTest

@testable
import Calling_Workflow

class ModelTests: XCTestCase {
    
    var testJSON : [String:AnyObject]? = nil
    var jsonSerializer : JSONSerializer = JSONSerializerImpl()
    private var standardOrg = Org( id: 1, orgTypeId: 1 )
    private var multiDepthOrg = Org( id: 1, orgTypeId: 1 )
    private var fullLcrOrg = Org( id: 1, orgTypeId: 1 )
    private var positionMetadata : Array<PositionMetadata> = []

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
        if let filePath = bundle.path(forResource: "cwf-object", ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            testJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
            standardOrg = Org( fromJSON: (testJSON?["orgWithCallingsInSubOrg"] as? JSONObject)! )!
            multiDepthOrg = Org( fromJSON: (testJSON?["orgWithMultiDepthSubOrg"] as? JSONObject)! )!

        } else {
            print( "No File Path found for file" )
        }
        let jsonFileReader = JSONFileReader()
        let metadataList = jsonFileReader.getJSONArray(fromFile: "position-metadata")
        
//        if let positionMetadataFile = bundle.path(forResource: "position-metadata", ofType: "js"),
//            let fileData = NSData(contentsOfFile: positionMetadataFile) {
        
//            let jsonData = Data( referencing: fileData )
//            print( jsonData.debugDescription )
//            let metadataList = try! JSONSerialization.jsonObject(with: jsonData, options: []) as! [JSONObject]
            positionMetadata = metadataList.map() { PositionMetadata( fromJSON: $0 ) }.flatMap() {$0 }
            print( positionMetadata.debugDescription )
//        } else {
//            print( "No File Path found for postionMetadata file" )
//        }
        fullLcrOrg.children = Org.orgArrays(fromJSONArray: jsonFileReader.getJSONArray(fromFile: "org-callings"))
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPositionMetadataFromJson() {
        XCTAssertGreaterThan(positionMetadata.count, 0)
        var positionMap : [Int:PositionMetadata] = [:]
        positionMetadata.forEach() {
            positionMap[ $0.positionTypeId ] = $0
        }
        
        let bishop = positionMap[4]!
        XCTAssertNil( bishop.shortName)
        let bishopPriesthood = (bishop.requirements?.priesthood)!
        XCTAssertEqual( bishopPriesthood.count, 1 )
        XCTAssertEqual(bishopPriesthood[0], .HighPriest)
        XCTAssertEqual(bishop.requirements!.gender!, .Male)
        XCTAssertNil( bishop.requirements!.age )
        XCTAssertTrue( bishop.requirements!.memberClasses.isEmpty )
        
        let firstCounselor = positionMap[54]!
        XCTAssertEqual(firstCounselor.shortName, "1st Counselor")
        
        let htDistLeader = positionMap[1395]!
        XCTAssertEqual(htDistLeader.requirements?.priesthood.count, 5)
        XCTAssertTrue( (htDistLeader.requirements?.priesthood.contains(item: .Priest))!)
        
        let rsPres = positionMap[143]!
        XCTAssertEqual(rsPres.requirements?.gender, .Female)
        XCTAssertEqual( rsPres.requirements!.memberClasses, [MemberClass.ReliefSociety] )
        
        let primaryPianist = positionMap[215]!
        XCTAssertNil( primaryPianist.requirements )
    }
    
    func testOrgJsonDeserialization() {
        let org = standardOrg
        
        XCTAssertNotNil(org)
        XCTAssertEqual( org.orgName, "Primary" )
        XCTAssertEqual( org.orgTypeId, 77 )
        XCTAssertEqual( org.displayOrder, 700 )
        XCTAssertEqual( org.id, 7428354 )
        XCTAssertEqual( org.children.count, 3 )
        XCTAssertNotNil(org.callings)
        XCTAssertEqual(org.callings.count, 0)
    }
    func testCallingsInSubOrgFromJson() {
        let org = standardOrg
        
        let childOrg = org.children[0]
        XCTAssertNotNil(childOrg)
        XCTAssertEqual( childOrg.orgName, "CTR 7" )
        XCTAssertEqual(childOrg.callings.count, 2)
        let calling = childOrg.callings[0]
        XCTAssertEqual(calling.existingIndId!, 123)
        XCTAssertEqual(calling.existingStatus, ExistingCallingStatus.Active)
        XCTAssertNil( calling.activeDate )
        XCTAssertEqual(calling.id, 734829)
        XCTAssertEqual(calling.position.positionTypeId, 1481)
        XCTAssertEqual(calling.position.name, "Primary Teacher")
        XCTAssertEqual(calling.position.hidden, false)
        XCTAssertEqual(calling.proposedStatus, CallingStatus.Proposed)
        XCTAssertEqual(calling.notes, "Some String")
        
    }
    func testCallingsInOrgFromJson() {
        let org = Org( fromJSON: (testJSON?["orgWithDirectCallings"] as? JSONObject)! )
        
        XCTAssertNotNil(org)
        let calling = org!.callings[0]
        XCTAssertEqual(calling.existingIndId!, 123)
        XCTAssertEqual(calling.existingStatus, ExistingCallingStatus.Active)
        XCTAssertEqual( calling.activeDate, Date( year: 2015, month: 09, day: 22 ) )
        XCTAssertEqual(calling.id, 734829)
        XCTAssertEqual(calling.position.positionTypeId, 1481)
        XCTAssertEqual(calling.position.name, "Primary Teacher")
        XCTAssertEqual(calling.position.hidden, true)
        XCTAssertEqual(calling.proposedStatus, CallingStatus.Proposed)
        XCTAssertEqual(calling.notes, "Some String")
        
    }
    
    
    func testInvalidOrgsFromJson() {
        let orgsJSON = testJSON?["invalidOrgs"] as? [JSONObject]!
        orgsJSON?.forEach() { orgJSON in
            let org = Org( fromJSON: orgJSON )
            XCTAssertNil( org )
        }
    }
    
    func testOrgToJson() {
        let org = standardOrg
        
        let orgJson = org.toJSONObject()
        let jsonString = jsonSerializer.serialize( jsonObject: orgJson )
        XCTAssertTrue(jsonString!.contains( "\"defaultOrgName\":\"Primary\"" ))
        XCTAssertTrue(jsonString!.contains( "\"subOrgId\":7428354" ))
        XCTAssertTrue(jsonString!.contains( "\"orgTypeId\":77" ))
        // just test that there is some object in the callings array. If it's empty it would not have the { and " after the [
        XCTAssertTrue(jsonString!.contains( "\"callings\":[{\"" ))
        XCTAssertTrue(jsonString!.contains( "\"memberId\":123" ))
        XCTAssertTrue(jsonString!.contains( "\"positionId\":734829" ))
        XCTAssertTrue(jsonString!.contains( "\"proposedIndId\":456" ))
        XCTAssertTrue(jsonString!.contains( "\"positionTypeId\":1481" ))
        XCTAssertTrue(jsonString!.contains( "\"notes\":\"Some String\"" ))
        XCTAssertTrue(jsonString!.contains( "\"proposedStatus\":\"PROPOSED\"" ))
        XCTAssertTrue(jsonString!.contains( "\"position\":\"Primary Teacher\"" ))
        XCTAssertTrue(jsonString!.contains( "\"hidden\":\"false\"" ))
        XCTAssertTrue(jsonString!.contains( "\"activeDate\":\"20150922\"" ))
        XCTAssertTrue(jsonString!.contains( "\"displayOrder\":700" ))
        print( "JSON:" + jsonString! )
        
    
    }

    func testCallingMonths() {
        let org = standardOrg
        let callingWithNoDate = org.children[0].callings[0]
        XCTAssertEqual( callingWithNoDate.existingMonthsInCalling, 0 )

        var callingWithDate = org.children[0].callings[1]
        // manual test - would need to be updated monthly if enabled
//        XCTAssertEqual( callingWithDate.existingMonthsInCalling, 16 )
        callingWithDate.activeDate = Date().xMonths( x: -4 )
        XCTAssertEqual(callingWithDate.existingMonthsInCalling, 4)

    }

    func testGetChildOrg() {
        let org = standardOrg
        var childOrg = org.getChildOrg(id: 752892)
        XCTAssertNotNil( childOrg )
        XCTAssertEqual(childOrg!.orgTypeId, 40 )

        childOrg = org.getChildOrg(id: 38432972)
        XCTAssertNotNil( childOrg )
        XCTAssertEqual(childOrg!.orgTypeId, 35 )

        XCTAssertNil( org.getChildOrg( id: 17 ) )

        XCTAssertEqual(multiDepthOrg.getChildOrg(id: 839500)!.orgTypeId, 739)
        XCTAssertEqual(multiDepthOrg.getChildOrg(id: 839510)!.orgTypeId, 1700)

    }

    func testAllCallings() {
        let org = standardOrg
        XCTAssertEqual(org.allOrgCallings.count, 5)
        XCTAssertEqual(org.allOrgCallingIds.count, 4)
        XCTAssertEqual(org.children[0].allOrgCallings.count, 2)

        XCTAssertEqual( multiDepthOrg.allOrgCallings.count, 2 )

    }
    
    // todo - need to review these in light of displayOrder, anything else to test
    func testAddCalling() {
        var org = standardOrg
        var primaryClass = org.getChildOrg(id: 752892)!
        let unchangedClass = org.getChildOrg(id: 38432972)!
        XCTAssertEqual(primaryClass.callings.count, 2)
        let teacher = Position(positionTypeId: 1482, name: "Primary Teacher", hidden: false, multiplesAllowed: true, displayOrder: nil, metadata: PositionMetadata())
        
        let newCalling = Calling(id: nil, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: 999, status: .Proposed, position: teacher, notes: nil, parentOrg: primaryClass)
        
        org = org.updatedWith(newCalling: newCalling)!
        primaryClass = org.getChildOrg(id: 752892)!
        XCTAssertEqual(primaryClass.callings.count, 3)
        let newCallingFromOrg = primaryClass.callings[2]
        validateCallingsSame(newCalling, newCallingFromOrg)
        validateOrgSame( unchangedClass, org.getChildOrg(id: 38432972)! )
        
        
    }
    
    func testUpdateCalling() {
        var org = standardOrg
        var ctr7Org = org.getChildOrg( id: 38432972 )!
        let siblingOrg = org.getChildOrg( id: 752892 )!

        let callingWithId = ctr7Org.callings[1]
        var otherCallingInOrg = ctr7Org.callings[0]
        var updatedOrg = performCallingUpdateAndValidation(parentOrg: org, childOrg: ctr7Org, originalCalling: callingWithId, callingIdx: 1, expectedId: 734820, expectedPosition: nil, updatedIndId: 999, updatedStatus: .Accepted)
        var otherCallingAfterUpdate = updatedOrg.getChildOrg(id: 38432972)!.callings[0]
        // validate that other callings in the org were not affected by the update
        validateCallingsSame(  otherCallingInOrg, otherCallingAfterUpdate )
        //  check and make sure sibling orgs are not nil
        validateOrgSame( siblingOrg, updatedOrg.getChildOrg(id: 752892)! )

        var ctr8Org = org.getChildOrg( id: 752892 )!
        let proposedCalling = ctr8Org.callings[0]
        let ctr8Teacher = Position(positionTypeId: 1482, name: nil, hidden: false, multiplesAllowed: true,displayOrder: nil, metadata: PositionMetadata())
        otherCallingInOrg = ctr8Org.callings[1]
        updatedOrg = performCallingUpdateAndValidation(parentOrg: org, childOrg: ctr8Org, originalCalling: proposedCalling, callingIdx: 0, expectedId: nil, expectedPosition: ctr8Teacher, updatedIndId: 999, updatedStatus: .NotApproved)
        otherCallingAfterUpdate = updatedOrg.getChildOrg(id: 752892)!.callings[1]
        validateCallingsSame(  otherCallingInOrg, otherCallingAfterUpdate )
        
        org = multiDepthOrg
        var varsityOrg = org.getChildOrg(id: 839510)!
        let coach = varsityOrg.callings[0]
        performCallingUpdateAndValidation(parentOrg: org, childOrg: varsityOrg, originalCalling: coach, callingIdx: 0, expectedId: 275893, expectedPosition: nil, updatedIndId: 999, updatedStatus: .Proposed)
        

        
    }
    
    func validateCallingsSame( _ c1 : Calling, _ c2 : Calling ) {
        XCTAssertEqual(c1, c2)
        XCTAssertEqual(c1.proposedIndId, c2.proposedIndId)
        XCTAssertEqual(c1.proposedStatus, c2.proposedStatus)
    }
    
    func validatePositionSame( _ p1 : Position, _ p2 : Position ) {
        XCTAssertEqual(p1, p2)
        XCTAssertEqual(p1.name, p2.name)
        XCTAssertEqual(p1.unitNum, p2.unitNum)
        XCTAssertEqual(p1.hidden, p2.hidden)
        XCTAssertEqual(p1.multiplesAllowed, p2.multiplesAllowed)
        XCTAssertEqual(p1.metadata, p2.metadata)
    }
    
    func validateOrgSame( _ o1: Org, _ o2: Org ) {
        XCTAssertEqual(o1, o2)
        XCTAssertEqual(o1.orgTypeId, o2.orgTypeId)
        XCTAssertEqual(o1.allOrgCallings, o2.allOrgCallings)
        let o1Callings = o1.allOrgCallings
        let o2Callings = o2.allOrgCallings
        for calling in o1Callings {
            // this will match on ID or positionTypeId & proposedIndId
            let o2Calling = o2Callings[o2Callings.index(of: calling)!]
            
            XCTAssertNotNil(o2Calling)
            // still need to validate status, etc.
            validateCallingsSame(calling, o2Calling)
        }
        
        // validate child orgs
        XCTAssertEqual(o1.children, o2.children)
        for childOrg in o1.children {
            validateOrgSame( childOrg, o2.children.first( where: { $0 == childOrg })!)
        }
    }
    
    func testCallingComputedVarNames() {
        let eqPresPos = Position(positionTypeId: 138, name: "EQ Pres", hidden: false, multiplesAllowed: false, displayOrder: nil, metadata: PositionMetadata() )
        let teacherPos = Position(positionTypeId: 200, name: "Primary Teacher", hidden: false, multiplesAllowed: true, displayOrder: nil, metadata: PositionMetadata() )
        let eqPresCalling = Calling(id: nil, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: Date().xMonths(x: -15), proposedIndId: nil, status: .Proposed, position: eqPresPos, notes: nil, parentOrg: nil)
        var callingText = eqPresCalling.nameWithTime
        // should contain the name of the calling
        // should contain the time in calling
        assert(sourceText: callingText, containsText: ["EQ Pres", "(15M)"])

        callingText = eqPresCalling.nameWithStatus
        // should contain the name of the calling
        // should contain the time in calling
        assert(sourceText: callingText, containsText: ["EQ Pres", "Proposed"])

        var callings = [eqPresCalling]
        // single calling in array - should not have a ,
        XCTAssertFalse(callings.namesWithTime().contains( "," ))
        XCTAssertFalse(callings.namesWithStatus().contains( "," ))
        
        let teacherCalling = Calling(id: nil, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: Date().xMonths(x: -6), proposedIndId: nil, status: .Accepted, position: teacherPos, notes: nil, parentOrg: nil)
        callings = [eqPresCalling, teacherCalling]

        callingText = callings.namesWithTime()
        // should contain the names of both the callings
        // should contain the time for both callings
        // should  have a ,
        assert(sourceText: callingText, containsText: ["EQ Pres", "Primary Teacher", "(15M)", "(6M)", ","])
        
        // but should not end with one
        XCTAssertNotEqual(callingText.characters.last, ",")
        
        callingText = callings.namesWithStatus()
        // should contain the name of the calling
        // should contain the time in calling
        assert(sourceText: callingText, containsText: ["EQ Pres", "Primary Teacher", "Proposed", "Accepted", ","])
        
        // but should not end with one
        XCTAssertNotEqual(callingText.characters.last, ",")
        
    }
    
    func assert( sourceText: String, containsText: [String] ) {
        for text in containsText {
            XCTAssert(sourceText.contains( text ))
        }
    }
    
    func testPositionMetadataUpdate() {
        var org = fullLcrOrg
        let originalPositions = org.allOrgCallings.map() { $0.position }
        let emptyMetadata = PositionMetadata()
        org.allOrgCallings.forEach() {
            XCTAssertEqual( $0.position.metadata, emptyMetadata )
        }

        let jsonFileReader = JSONFileReader()
        let positionsMD = PositionMetadata.positionArrays(fromJSONArray: jsonFileReader.getJSONArray( fromFile: "position-metadata" ) )
        let positionMetadataMap = positionsMD.toDictionaryById( {$0.positionTypeId} )
        org = org.updatedWith(positionMetadata: positionMetadataMap)
        let updatedPositions = org.allOrgCallings.map() { $0.position }
        
        for (index, originalPosition) in originalPositions.enumerated() {
            let updatedPosition = updatedPositions[index]
            if let metadata = positionMetadataMap[originalPosition.positionTypeId] {
                XCTAssertEqual( updatedPosition.metadata, metadata )
            } else {
                validatePositionSame(originalPosition, updatedPosition)
            }
        }
    }
    
    func performCallingUpdateAndValidation( parentOrg: Org, childOrg: Org,  originalCalling : Calling, callingIdx : Int, expectedId : Int64?, expectedPosition : Position?, updatedIndId : Int64?, updatedStatus : CallingStatus ) -> Org {
        // just make sure we are starting with the calling that we think we are
        var calling = originalCalling
        XCTAssertEqual( calling.id, expectedId )
        if expectedId == nil {
            // check the position
            XCTAssertEqual(calling.position.positionTypeId, expectedPosition?.positionTypeId)
        }
        XCTAssertNotEqual( calling.proposedIndId, updatedIndId )
        XCTAssertNotEqual( calling.proposedStatus, updatedStatus )
        calling.proposedIndId = updatedIndId
        calling.proposedStatus = updatedStatus
        let updatedOrg = parentOrg.updatedWith( changedCalling: calling )
        print("+++++++++++ Org:" + updatedOrg.debugDescription )
        
        let changedChildOrg = updatedOrg?.getChildOrg( id: childOrg.id )
        calling = changedChildOrg!.callings[callingIdx]
        XCTAssertEqual( calling.id, expectedId )
        XCTAssertEqual( calling.proposedIndId, updatedIndId )
        XCTAssertEqual( calling.proposedStatus, updatedStatus )
        if expectedId == nil {
            // check the position
            XCTAssertEqual(calling.position.positionTypeId, expectedPosition?.positionTypeId)
        }
        
        return updatedOrg!
    }
    
    func testCallingCwfId() {
        XCTAssertNil( Calling.generateCwfId( id: 1234, cwfId: nil ) )
        XCTAssertEqual( Calling.generateCwfId( id: 1234, cwfId: "cwfID" ), "cwfID" )
        XCTAssertEqual( Calling.generateCwfId( id: nil, cwfId: "cwfID" ), "cwfID" )
        XCTAssertNotNil( Calling.generateCwfId( id: nil, cwfId: nil ) )
    }
    
    func testCallingEqual() {
        let eqPres = Position(positionTypeId: 138, name: "EQ President", hidden: false, multiplesAllowed: false, displayOrder: nil, metadata: PositionMetadata())
        let ctr7 = Position(positionTypeId: 222, name: "CTR 7 Teacher", hidden: false, multiplesAllowed: true, displayOrder: nil, metadata: PositionMetadata())
        let eqpCalling = Calling(id: 111, cwfId: "222-3434-111", existingIndId: 555, existingStatus: .Active, activeDate: nil, proposedIndId: 600, status: .Proposed, position: eqPres, notes: nil, parentOrg: standardOrg)
        let ctr7Calling = Calling(id: 222, cwfId: nil, existingIndId: 600, existingStatus: .Active, activeDate: nil, proposedIndId: 777, status: .Proposed, position: ctr7, notes: nil, parentOrg: standardOrg)
        
        
        // callings that has a position ID that matches
        var callingWithMatchingId = eqpCalling
        XCTAssertTrue( eqpCalling == callingWithMatchingId )
        
        // just changing the parent org should be enough to make it no longer match
        callingWithMatchingId.parentOrg = multiDepthOrg
        XCTAssertFalse( eqpCalling == callingWithMatchingId )
        
        //  diff. calling in same org doesn't match
        XCTAssertFalse( eqpCalling == ctr7Calling )

        // calling that matches only based on positionId
        callingWithMatchingId = Calling(id: 111, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: nil, status: nil, position: eqPres, notes: nil, parentOrg: standardOrg)
        XCTAssertTrue( eqpCalling == callingWithMatchingId )
        
        // calling with a different ID, but the same position, multiples not allowed so should match based on position
        let callingDiffIdSamePosition = Calling(id: 1122, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: nil, status: nil, position: eqPres, notes: nil, parentOrg: standardOrg)
        XCTAssertTrue( eqpCalling == callingDiffIdSamePosition )
        
        // calling with a different ID, but the same position, multiples are allowed so should not match based on position
        let callingDiffIdSamePositionWithMulti = Calling(id: 1122, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: nil, status: nil, position: ctr7, notes: nil, parentOrg: standardOrg)
        XCTAssertFalse( ctr7Calling == callingDiffIdSamePositionWithMulti )
        
        // proposed callings, only with cwfId
        let proposed = Calling(id: nil, cwfId: "11-22-33", existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: 555, status: .Proposed, position: ctr7, notes: nil, parentOrg: standardOrg)
        var changedProposed = proposed
        changedProposed.proposedIndId = 777
        changedProposed.proposedStatus = .Approved
        XCTAssertTrue( proposed == changedProposed )
        
        // if it has a different cwfId it should not match even though it's same position (when multiples are allowed)
        changedProposed = Calling(id: nil, cwfId: "44-55-66", existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: 777, status: .Approved, position: ctr7, notes: nil, parentOrg: standardOrg)
        XCTAssertFalse( proposed == changedProposed )
        
        // a proposed calling merged on another client with an active. Should match based on cwfId
        let proposedMergedActive = Calling(id: 1122, cwfId: "11-22-33", existingIndId: 555, existingStatus: .Active, activeDate: nil, proposedIndId: 777, status: .Approved, position: ctr7, notes: nil, parentOrg: standardOrg)
        XCTAssertTrue( proposed == proposedMergedActive )
        
        //  test for same calling w/ different cwfId's (multiples not allowed - should match based on position regardless of different cwfId)
        changedProposed = Calling(id: nil, cwfId: "44-55-66", existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: 777, status: .Approved, position: eqPres, notes: nil, parentOrg: standardOrg)
        XCTAssertTrue( eqpCalling == changedProposed )
        
        
        //  test for same calling w/ different cwfId's (multiples allowed - should NOT match based on position due to different cwfId)
        XCTAssertFalse( ctr7Calling == proposed )
        
    }

    // found this online as a way to count the number of enum values, so we can compare to make sure the allValues contains everything. If allValues size is different then the number of enums, an enum was likely added but left out of allValues. It's not perfect, but better than nothing
    func enumCount<T: Hashable>(_ t: T.Type) -> Int {
        var i = 1
        while (withUnsafePointer(to: &i) {
            $0.withMemoryRebound(to:t.self, capacity:1) { $0.pointee.hashValue != 0 }
        }) {
            i += 1
        }
        return i
    }
    
    func testStatusEnums() {
        // ensure that allValues has the same number of elements as the enum. This should catch the case where a we add an enum value but forget to add it to allValues
        XCTAssertEqual(enumCount(CallingStatus.self), CallingStatus.allValues.count)
        // basically check for any duplicates. This would catch a copy/paste error where something in allValues gets copied, but not updated to the new enum value
        XCTAssertEqual(CallingStatus.allValues.count, Set<CallingStatus>(CallingStatus.allValues).count)
        
        // test the descriptions
        // ensure that the basic status is capitalized
        XCTAssertEqual( CallingStatus.Accepted.description, "Accepted" )
        // ensure where there is a _ it gets changed to a space
        XCTAssertEqual( CallingStatus.OnHold.description, "On Hold" )
        
    }

    func testPriesthoodEnums() {
        XCTAssertEqual(enumCount(Priesthood.self), Priesthood.allValues.count)
        XCTAssertEqual(Priesthood.allValues.count, Set<Priesthood>(Priesthood.allValues).count)
    }
    
    func testMemberClassEnums() {
        XCTAssertEqual(enumCount(MemberClass.self), MemberClass.allValues.count)
        XCTAssertEqual(MemberClass.allValues.count, Set<MemberClass>(MemberClass.allValues).count)
    }
    

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
