//
//  PermissionManager.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 5/16/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

//
//  Permissions.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 5/4/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

/** A combination of the type of Role (UnitAdmin, OrgAdmin, etc.) with their associated permissions). Includes static definitions of the existing roles with their granted permissions */
public struct Role {
    
    let type : RoleType
    let permissions : [Domain:[Permission]]
    
    public static let unitAdmin = Role(type: .UnitAdmin, permissions: Domain.validDomainPermissions)

    // orgAdmin has all the permissions of a unit admin, except changing the unit google account
    public static let orgAdmin = Role(type: .OrgAdmin, permissions: Domain.validDomainPermissions.filteredDictionary( {$0.0 != .UnitGoogleAccount}))
    
    // stake assistants (High Councilors) can only view & update potential callings
    public static let stakeAssistant = Role( type: .StakeAssistant, permissions: Domain.validDomainPermissions.filteredDictionary({$0.0 == .OrgInfo || $0.0 == .PotentialCalling}))
    
}

/** A combination of a user position, and their role within a specific unit*/
public struct UnitRole {
    let role : Role
    let unitNum : Int64
    // The ID of the org that the role is associated with. It's optional as for a unit admin it would not be set, only for an org admin. Currently it's not used, we base everything off of the position's org type, but if we want to limit an EQ Pres in a unit with multiple EQ's we would need to make use of this
    let orgId : Int64?
    
    // The orgType that an org admin is associated with (so EQ for EQ Pres)
    let orgType : UnitLevelOrgType?
    
    // The position that the user holds that grants this role. It's not currently being used.
    let activePosition : Position
    
    // An OrgAdmin will have rights to all sub-orgs in their org, except for the presidency org. This field stores the type id of the presidency org so we can handle it specially. The reason it's an ID rather than an enum like orgType is we only have enums for the main unit level orgs (RS, EQ, HP, etc.). There are too many suborgs, and the potential for new ones to be added or changed so we don't maintain an enum of all those, we just use the ID's
    let orgRightsException : Int?
}

/** This is the main glue of the permissions logic. It is what associates positions from lds.org with Roles within the app, and knows how to make use of the appropriate PermissionResolvers to check if a user is authorized to access data*/
public class PermissionManager {
    
    // Org leaders can see all changes within their org, except within their presidency, so for each root level org we have the org type ID's of the presidency.
    // todo - should bishopric & BP be added to this? Probably.
    static var unitLevelOrgExceptions : [UnitLevelOrgType:Int] = [ .HighPriests: 1299, .Elders: 1295, .ReliefSociety: 1279, .YoungMen: 1311, .YoungWomen: 1312, .SundaySchool: 1308, .Primary: 1303 ]
    
    private let unitPermResolver = UnitPermResolver()
    private let orgPermResolver = OrgPermResolver()
    
    private let permissionResolvers : [RoleType:PermissionResolver]
    
    public let orgAdminPositions : [UnitLevelOrgType:[PositionType]] = [.HighPriests : [.HPGroupLeader, .HP1stAssistant, .HP2ndAssistant, .HPSecretary],
                                                                .Elders : [.EQPres, .EQ1stCounselor, .EQ2ndCounselor, .EQSecretary],
                                                                .ReliefSociety : [.RSPres, .RS1stCounselor, .RS2ndCounselor, .RSSecretary],
                                                                .YoungMen : [.YMPres, .YM1stCounselor, .YM2ndCounselor, .YMSecretary],
                                                                .YoungWomen : [.YWPres, .YW1stCounselor, .YW2ndCounselor, .YWSecretary],
                                                                .SundaySchool : [.SSPres, .SS1stCounselor, .SS2ndCounselor, .SSSecretary],
                                                                .Primary : [.PrimaryPres, .Primary1stCounselor, .Primary2ndCounselor, .PrimarySecretary]]

    let unitAdminPositions : [PositionType] = [.Bishop, .Bishopric1stCounselor, .Bishopric2ndCounselor, .WardExecSec, .WardClerk] // still need to add stake positions & branch positions
    
    init() {
        permissionResolvers = [.UnitAdmin:unitPermResolver, .StakeAssistant:unitPermResolver, .OrgAdmin:orgPermResolver]
    }
    
    /** Method to be called once we have the users positions for lds.org getCurrentUser call to create the roles within the app associated with those positions */
    func createUserRoles( forPositions positions: [Position], inUnit unitNum: Int64 ) -> [UnitRole] {
        var unitRoles : [UnitRole] = []
        // filter out any positions that have no relevant rights (any non aux. leader), or that are in a different unit
        let unitPositions = positions.filter() {
            PositionType(rawValue: $0.positionTypeId) != nil && $0.unitNum == unitNum
        }
        
        // get all the roles for the positions
        for currPosition in unitPositions  {
            if let currPositionType = PositionType( rawValue: currPosition.positionTypeId ) {
                // if they have a unit admin position, then that overrides anything else, set it and we break out
                if unitAdminPositions.contains(item: currPositionType) {
                    // todo - modify this so there's a transformer function as part of the role that can create a role from the position, that way as new roles are created we don't have to modify this code - it's contained in the role
                    unitRoles = [UnitRole(role: Role.unitAdmin, unitNum: currPosition.unitNum!, orgId: nil, orgType: UnitLevelOrgType.Ward, activePosition: currPosition, orgRightsException: nil)]
                    break;
                } else {
                    for (orgType, positionTypes) in orgAdminPositions {
                        if positionTypes.contains( currPositionType ) {
                            let orgAdminRole = UnitRole(role: Role.orgAdmin, unitNum: currPosition.unitNum!, orgId: nil, orgType: orgType, activePosition: currPosition, orgRightsException: PermissionManager.unitLevelOrgExceptions[orgType])
                            unitRoles.append(orgAdminRole)
                        }
                        // todo - still need to account for unit viewers
                    }
                }
            }
        }
        return unitRoles
    }
    
    /** returns true if the role has the permission for the domain object, false otherwise. */
    public func hasPermission( unitRole: UnitRole, domain: Domain, permission: Permission ) -> Bool {
        // have to compare to true, because it could return nil as well as t/f
        return unitRole.role.permissions[domain]?.contains( permission ) == true
    }
    
    /** Checks to see if one of the roles in the list has the specified permission */
    public func hasPermission( unitRoles: [UnitRole], domain: Domain, permission: Permission ) -> Bool {
        var hasPerm = false
        for role in unitRoles {
            hasPerm = self.hasPermission(unitRole: role, domain: domain, permission: permission)
            if hasPerm {
                break
            }
        }
        return hasPerm
    }
    
    /** Determines if a user has a specified permission to perform an action on a set of data. An OrgAdmin may have permission to update a calling, but only on data within their org. */
    public func isAuthorized( unitRole: UnitRole, domain: Domain, permission: Permission, targetData: Authorizable ) -> Bool {
        return hasPermission(unitRole: unitRole, domain: domain, permission: permission) && permissionResolvers[unitRole.role.type]!.isAuthorized(role: unitRole, domain: domain, permission: permission, targetData: targetData)
        
    }

    /** Determines if a user has a in their list of roles, permission to perform an action on a set of data */
    public func isAuthorized( unitRoles: [UnitRole], domain: Domain, permission: Permission, targetData: Authorizable ) -> Bool {
        var isAuthorized = false
        for role in unitRoles {
            isAuthorized = self.isAuthorized(unitRole: role, domain: domain, permission: permission, targetData: targetData)
            if isAuthorized {
                break
            }
        }
        return isAuthorized
    }
    
}


