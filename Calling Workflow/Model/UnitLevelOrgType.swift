//
//  OrgType.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation
/**
 UnitLevelOrgType represents the CDOL enum for an org type, but we only need them at the unit level to handle permissions (i.e. EQ, Primary, RS, etc. we don't need or want to manage enums for all the primary and SS classes, etc.). The int values for this enum are based on the CDOL values, and should not be changed unless there is a corresponding CDOL change (which would be very unlikely).
 
 For Convenience there are also collections of the orgs that apply to the basic units that we support. Currently that includes wardOrgTypes and branchOrgTypes, but at some point would include stake orgs as well
 */
public enum UnitLevelOrgType : Int  {
    
    case Stake = 5
    case Ward = 7
    
    case Bishopric = 1179
    case BranchPresidency = 1200
    case Elders = 70
    case ReliefSociety = 74
    case YoungMen = 73
    case YoungWomen = 76
    case SundaySchool = 75
    case Primary = 77
    case WardMissionaries = 1310
    case BranchMissionaries = 1283
    case Other = 1185
    
    static let wardOrgTypes = [Bishopric, Elders, ReliefSociety, YoungMen, YoungWomen, SundaySchool, Primary, WardMissionaries, Other]
    
    static let branchOrgTypes = [BranchPresidency, Elders, ReliefSociety, YoungMen, YoungWomen, SundaySchool, Primary, BranchMissionaries, Other]
    
}

