//
//  Authorizable.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 5/16/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

/** Protocol for defining target objects that can be used to verify if a user is authorized to act on the data. For example, a EQ Pres (OrgAdmin) has permissions to view and edit data, but only within his org, not within the primary. A Bishop would be authorized to create or edit the google drive settings but only for his ward. So for any object that needs to be analyzed to ensure that the user has rights to view it we can create an Authorizable representation of that object with the data that is needed to be able to verify whether a user has access. The PermissionManager.isAuthorized() and PermissionResolver.isAuthorized() methods all take an Authorizable targetData parameter.
 
 The most basic case is at the very least we need to verify that the data is for the users unit, so having a unit number is the only required method of the interface, but other objects (like an AuthorizableOrg) need more than just a unit number so other instances have their own data that is specific to what they need to verify user access.
 */
public protocol Authorizable {
    var unitNum : Int64 { get }
}

/** Data necessary to verify whether or not a specific user has access to a given org*/
public struct AuthorizableOrg : Authorizable {
    public let unitNum : Int64
    
    // this is not currently used in resolving any permissions. It may be in the future if we want to support multiple EQ's or RS's
    let unitLevelOrgId : Int64
    // This is the org type of the root org. So it may be that the org the user is trying to edit is the EQ Instructors, but this org type would be that of the root org (EQ)
    let unitLevelOrgType : UnitLevelOrgType
    // This is the orgType of the actual org that is being verified. We don't have an enum for every possible sub org type (i.e. EQ Instructors), we only make an enum for the main root level org types (HP, EQ, RS, etc.). So that's why we use the enum for the unitLevelOrgType, but just the orgTypeId for the actual org. This is primarily used to verify if it's a sub-org that may be an exception to the users privileges. Most orgs presidencies have rights to view their org, but they have an exception for the presidency org (so if a bishop is making changes to the primary presidency, the presidency members won't see it through the app when they shouldn't be privy to that information). So this id is necessary to know if an org that someone has rights to via their rights to the unit level org may not have rights to the presidency sub-org.
    let orgTypeId : Int
    
    init( fromSubOrg subOrg: Org, inUnitLevelOrg unitLevelOrg: Org) {
        self.unitNum = unitLevelOrg.unitNum
        self.unitLevelOrgId = unitLevelOrg.id
        // should this be an optional init rather than default to other org type?
        self.unitLevelOrgType = UnitLevelOrgType(rawValue: unitLevelOrg.orgTypeId) ?? UnitLevelOrgType.Other
        self.orgTypeId = subOrg.orgTypeId
    }
    
    init( unitNum : Int64, unitLevelOrgId : Int64, unitLevelOrgType : UnitLevelOrgType, orgTypeId : Int ) {
        self.unitNum = unitNum
        self.unitLevelOrgId = unitLevelOrgId
        self.unitLevelOrgType = unitLevelOrgType
        self.orgTypeId = orgTypeId
    }
}

public struct AuthorizableUnit : Authorizable {
    public let unitNum : Int64
}

/** This is not currently used, but likely will be once we want to support the use case where we want more granularity into changes within a presidency. In the case where the Bishopric may be changing a presidency, the presidency should not have access to that change. But in the case where say the Primary President needs to change a counselor, if she was the one that made the initial proposal then she may have rights to see any status updates as the calling is considered. This would be used to be able to support those types of use cases */
public struct AuthorizableCalling : Authorizable {
    let owningAuthOrg : AuthorizableOrg
    public var unitNum : Int64 {
        get {
            return owningAuthOrg.unitNum
        }
    }
    // todo - who created the calling for future
}

