//
//  PermissionsTests.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 5/5/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import XCTest

@testable
import Calling_Workflow


class PermissionsTests: XCTestCase {
    
    let mainUnit : Int64 = 1234
    let permMgr = PermissionManager()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRolePermissions() {
        XCTAssertEqual( Role.unitAdmin.permissions.count, 4 )
        let unitAdminActiveCallingPerms = Role.unitAdmin.permissions[.ActiveCalling]
        XCTAssertEqual( unitAdminActiveCallingPerms!, [.Update, .Delete, .Release] )
        
        let orgAdminActiveCallingPerms = Role.orgAdmin.permissions[.ActiveCalling]
        XCTAssertEqual( orgAdminActiveCallingPerms!, [.Update, .Delete, .Release] )

        let unitViewActiveCallingPerms = Role.stakeAssistant.permissions[.ActiveCalling]
        XCTAssertNil( unitViewActiveCallingPerms )
        
        let unitAdminGooglePerms = Role.unitAdmin.permissions[.UnitGoogleAccount]
        XCTAssertEqual( unitAdminGooglePerms!, [.Create, .Update ] )
        
        let orgAdminGooglePerms = Role.stakeAssistant.permissions[.UnitGoogleAccount]
        XCTAssertNil( orgAdminGooglePerms )
        
    }
    
    func testPositionTypes() {
        // if a new position is added with rights we need to add its' ID here
        let bishopricPosIds = [4,54,55,56,57]
        let branchPresPosIds = [12,59,60,789,1278]
        let stakePosIds = [1,2, 3,94,51,52]
        let unitAdminPositionIds = bishopricPosIds + branchPresPosIds + stakePosIds
        let hpPosIds = [133,134,135,136]
        let eqPosIds = [138,139,140,141]
        let rsPosIds = [143,144,145,146]
        let ymPosIds = [158,159,160,161]
        let ywPosIds = [183,184,185,186]
        let ssPosIds = [204,205,206,207]
        let priPosIds = [210,211,212,213]
        let orgAdminPositionIds = hpPosIds + eqPosIds + rsPosIds + ymPosIds + ywPosIds + ssPosIds + priPosIds
        let validPositionIds = unitAdminPositionIds + orgAdminPositionIds
        // make sure we don't accidentally remove any rights
        validPositionIds.forEach() {
            XCTAssertNotNil(PositionType(rawValue: $0))
        }
        
        // make sure we don't accidentally grant any rights
        for i in 0...1000 {
            if !validPositionIds.contains(item: i) {
                XCTAssertNil( PositionType(rawValue: i ))
            }
        }
        
        let testCases : [(posIds: [Int], orgType: UnitLevelOrgType, expectedRoleType: RoleType)] =
        [ (hpPosIds, .HighPriests, .OrgAdmin),
          (eqPosIds, .Elders, .OrgAdmin),
          (rsPosIds, .ReliefSociety, .OrgAdmin),
          (ymPosIds, .YoungMen, .OrgAdmin),
          (ywPosIds, .YoungWomen, .OrgAdmin),
          (ssPosIds, .SundaySchool, .OrgAdmin),
          (priPosIds, .Primary, .OrgAdmin),
          (bishopricPosIds, .Ward, .UnitAdmin),
          // todo - need to add support for branch and stake positions before we can test for them
//          (branchPresPosIds, .Ward, .UnitAdmin),
        ]
        
        testCases.forEach() {
            for posId in $0.posIds {
                let unitRoles = permMgr.createUserRoles(forPositions: createPositions(posId, inUnitNum: mainUnit), inUnit: mainUnit)
                
                XCTAssertEqual(unitRoles[0].role.type, $0.expectedRoleType)
                XCTAssertEqual(unitRoles[0].orgType, $0.orgType)
            }
            
        }
    }
    
    func testUnitPermResolver() {
        
        let posDontCare = Position(positionTypeId: 0, name: nil, hidden: false, multiplesAllowed: false, displayOrder: nil, metadata: PositionMetadata())
        let authorizedUnit = AuthorizableUnit(unitNum: mainUnit)
        let authorizedOrg = AuthorizableOrg(unitNum: mainUnit, unitLevelOrgId: 5555, unitLevelOrgType: .Elders, orgTypeId: 66)
        
        let unitPermResolver = UnitPermResolver()
        let authUnitRole = UnitRole(role: .unitAdmin, unitNum: mainUnit, orgId: nil, orgType: nil, activePosition: posDontCare, orgRightsException: nil)
        let nonAuthUnitRole = UnitRole(role: .unitAdmin, unitNum: 2748, orgId: nil, orgType: nil, activePosition: posDontCare, orgRightsException: nil)
        let testCases : [(role: UnitRole, domain: Domain, perm: Permission, authorizable: Authorizable, expectedResult: Bool)] =
            [(authUnitRole, .OrgInfo,  .View, authorizedUnit, true ), // authorized via unit
            (authUnitRole, .OrgInfo,  .View, authorizedOrg, true ), // authorized via org
             (authUnitRole, .ActiveCalling, .Create, authorizedUnit, true), // perm & domain shouldn't matter
             (nonAuthUnitRole, .OrgInfo, .View, authorizedUnit, false ), // not authorized
                (nonAuthUnitRole, .OrgInfo, .View, authorizedUnit, false ), // not authorized
             ]
        testCases.forEach() {
            XCTAssertEqual( unitPermResolver.isAuthorized( role: $0.role, domain: $0.domain, permission: $0.perm, targetData: $0.authorizable), $0.expectedResult )
        }
        
    }
    
    func testOrgPermResolver() {
        let eqPresOrgTypeId = 222
        let posDontCare = Position(positionTypeId: 0, name: nil, hidden: false, multiplesAllowed: false, displayOrder: nil, metadata: PositionMetadata())
        let eqOrg = AuthorizableOrg(unitNum: mainUnit, unitLevelOrgId: 5555, unitLevelOrgType: .Elders, orgTypeId: 66)
        let eqPresOrg = AuthorizableOrg(unitNum: mainUnit, unitLevelOrgId: 5555, unitLevelOrgType: .Elders, orgTypeId: eqPresOrgTypeId)
        
        let orgPermResolver = OrgPermResolver()
        let eqAdmin = UnitRole(role: .orgAdmin, unitNum: mainUnit, orgId: nil, orgType: .Elders, activePosition: posDontCare, orgRightsException: eqPresOrgTypeId)
        let eqAdminOtherUnit = UnitRole(role: .orgAdmin, unitNum: mainUnit + 100, orgId: nil, orgType: .Elders, activePosition: posDontCare, orgRightsException: eqPresOrgTypeId)
        
        let rsAdmin = UnitRole(role: .orgAdmin, unitNum: mainUnit, orgId: nil, orgType: .ReliefSociety, activePosition: posDontCare, orgRightsException: nil)
        let testCases : [(role: UnitRole, domain: Domain, perm: Permission, authorizable: Authorizable, expectedResult: Bool)] =
            [(eqAdmin, .OrgInfo,  .View, eqOrg, true ), // authorized via org
                (eqAdmin, .ActiveCalling, .Create, eqOrg, true), // perm & domain shouldn't matter
                (rsAdmin, .OrgInfo, .View, eqOrg, false ), // not authorized - admin in diff org
                (eqAdminOtherUnit, .OrgInfo, .View, eqOrg, false ), // eq admin, but in diff. unit
                (eqAdmin, .OrgInfo, .View, eqPresOrg, false ), // eq admin - but org is excaption (presidency)
        ]
        testCases.forEach() {
            XCTAssertEqual( orgPermResolver.isAuthorized( role: $0.role, domain: $0.domain, permission: $0.perm, targetData: $0.authorizable), $0.expectedResult )
        }
        
    }
    
    func testCreateUserRoles() {
        
        let noRoles = createPositions( 200, 100, inUnitNum: mainUnit )
        let unitAdmin = createPositions( 4, inUnitNum: mainUnit )
        let otherUnitAdmin = createPositions( 4, inUnitNum: mainUnit + 111 )
        let eqPresPos = createPositions(138, inUnitNum: mainUnit)
        let ssPresPos = createPositions(205, inUnitNum: mainUnit)
        
        let unitAdminRole = UnitRole(role: .unitAdmin, unitNum: mainUnit, orgId: nil, orgType: .Ward, activePosition: unitAdmin[0], orgRightsException: nil )
        let eqAdminRole = UnitRole(role: .orgAdmin, unitNum: mainUnit, orgId: nil, orgType: .Elders, activePosition: eqPresPos[0], orgRightsException: nil) // an org admin will have a rights exception, but we're not validating that in this test, so no need to set it
        let ssAdminRole = UnitRole(role: .orgAdmin, unitNum: mainUnit, orgId: nil, orgType: .SundaySchool, activePosition: ssPresPos[0], orgRightsException: nil) // an org admin will have a rights exception, but we're not validating that in this test, so no need to set it
        
        // all these positions should result in no roles for the given unit
        let noRoleTestCases : [(positions: [Position], unitNum: Int64)] = [
            ( noRoles, mainUnit ), // positions with no roles in the app
            ( otherUnitAdmin, mainUnit ) // positions with roles, but in a different unit
        ]
        
        noRoleTestCases.forEach() {
            XCTAssertTrue( permMgr.createUserRoles(forPositions: $0.positions, inUnit: $0.unitNum).isEmpty )
        }
        
        // all these positions should result in a single unit admin role for the unit
        let singleAdminTestCases : [(positions: [Position], unitNum: Int64, expectedRole : UnitRole)] = [
            ( unitAdmin, mainUnit, unitAdminRole ), // positions with a single unit admin
            ( noRoles + unitAdmin + noRoles, mainUnit, unitAdminRole ), // unit admin plus other non admin callings
            ( eqPresPos + unitAdmin + eqPresPos, mainUnit, unitAdminRole ), // unit admin plus other org admins
            ( otherUnitAdmin + unitAdmin + eqPresPos, mainUnit, unitAdminRole ), // unit admin plus other org admins plus admin in another unit
            ( eqPresPos, mainUnit, eqAdminRole ), // single Org admin in the EQ
            ( noRoles + eqPresPos + noRoles, mainUnit, eqAdminRole ), // Org admin in the EQ plus other calllings with no role in the app
            ( otherUnitAdmin + eqPresPos + noRoles, mainUnit, eqAdminRole ), // single Org admin in the EQ & OOU admin in other unit
        ]
        
        singleAdminTestCases.forEach() {
            let roles = permMgr.createUserRoles(forPositions: $0.positions, inUnit: $0.unitNum)
            XCTAssertEqual( roles.count, 1 )
            validateUnitRoleEqual( roles[0], $0.expectedRole)
        }

        let multiAdminTestCases : [(positions: [Position], unitNum: Int64, expectedRoles : [UnitRole])] = [
            ( eqPresPos + ssPresPos, mainUnit, [eqAdminRole, ssAdminRole]),
            ( eqPresPos + noRoles + ssPresPos, mainUnit, [eqAdminRole, ssAdminRole]),
        ]

        multiAdminTestCases.forEach() {
            let roles = permMgr.createUserRoles(forPositions: $0.positions, inUnit: $0.unitNum)
            XCTAssertEqual( roles.count, $0.expectedRoles.count )
            for (index, role) in roles.enumerated() {
                validateUnitRoleEqual( role, $0.expectedRoles[index])
            }
        }

    }
    
    func validateUnitRoleEqual( _ role1 : UnitRole, _ role2 : UnitRole ) {
        XCTAssertEqual( role1.role.type, role2.role.type )
        XCTAssertEqual( role1.unitNum, role2.unitNum )
        XCTAssertEqual(role1.orgId, role2.orgId)
        XCTAssertEqual(role1.orgType, role2.orgType)
    }
    
    func createPositions( _ typeIds: Int..., inUnitNum unitNum : Int64) -> [Position] {
        var positions : [Position] = []
        for typeId in typeIds {
            positions.append(Position(positionTypeId: typeId, name: nil, unitNum: unitNum, hidden: false, multiplesAllowed: false, displayOrder: nil, metadata: PositionMetadata()) )
        }
        
        return positions
    }
    
    func testOrgExceptions() {
        
    }
    
    func testHasPermission() {
        let unitAdmin = createPositions( 4, inUnitNum: mainUnit )
        let orgAdmin = createPositions(138, inUnitNum: mainUnit)

        let unitAdminRole = UnitRole(role: .unitAdmin, unitNum: mainUnit, orgId: nil, orgType: .Ward, activePosition: unitAdmin[0], orgRightsException: nil )
        let orgAdminRole = UnitRole(role: .orgAdmin, unitNum: mainUnit, orgId: nil, orgType: .Elders, activePosition: orgAdmin[0], orgRightsException: nil) // an org admin will have a rights
        
        let testCases : [( unitRoles: [UnitRole], domain: Domain, perm: Permission, expectedResult: Bool)] = [
            ([unitAdminRole], .OrgInfo, .View, true), // valid permissions the role should have
            ([orgAdminRole], Domain.PotentialCalling, .Update, true),
            ([unitAdminRole], Domain.UnitGoogleAccount, .Update, true), // permission that is valid, but restricted to certain roles
            ([orgAdminRole], Domain.UnitGoogleAccount, .Update, false),
            ([unitAdminRole], Domain.OrgInfo, .Update, false),// invalid permission - not available regardless of role
            ([unitAdminRole,orgAdminRole], Domain.PotentialCalling, .Update, true),
            ([orgAdminRole, unitAdminRole], Domain.UnitGoogleAccount, .Update, true),// perm that orgAdmin doesn't have, but unit admin does
        ]

        testCases.forEach() {
            XCTAssertEqual(permMgr.hasPermission(unitRoles: $0.unitRoles, domain: $0.domain, permission: $0.perm), $0.expectedResult)
        }
        
    }
    
    // we don't have any tests for isAuthorized, but it's using hasPermission() which is tested, and the permissionResolver classes which are also tested. We could add test for isAuth at some point, but it's low value/priority since everything is already being tested. The only way it might break is if we added any more logic to isAuth, rather than calling other methods to do the actual work.
    
    func testRolePerms() {
        let unitAdminPerms : [Domain: [Permission]]  =  [ .OrgInfo : [.View],
                                .PotentialCalling : [.Create, .Update, .Delete],
                                .ActiveCalling : [.Update, .Delete, .Release],
                                .UnitGoogleAccount: [.Create, .Update]]
        
        let testCases : [(role: Role, expectedPerms: [Domain:[Permission]])] =
            [
                (Role.unitAdmin, unitAdminPerms),
                (Role.orgAdmin, [.OrgInfo: [.View], .PotentialCalling : [.Create, .Update, .Delete],
                                 .ActiveCalling : [.Update, .Delete, .Release]]),
                (Role.stakeAssistant, [.OrgInfo: [.View], .PotentialCalling : [.Create, .Update, .Delete]])
        ]
        testCases.forEach() {
            for domain in $0.expectedPerms.keys {
                XCTAssertTrue($0.role.permissions.keys.contains(domain))
                XCTAssertEqual($0.role.permissions[domain]!, $0.expectedPerms[domain]!)
                
            }
        }
    }
    
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
