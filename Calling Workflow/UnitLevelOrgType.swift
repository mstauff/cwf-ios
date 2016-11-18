//
//  OrgType.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

public enum UnitLevelOrgType : Int  {
    
    case Bishopric = 1179
    case BranchPresidency = -1
    case HighPriests = 69
    case Elders = 70
    case ReliefSociety = 74
    case YoungMen = 73
    case YoungWomen = 76
    case SundaySchool = 75
    case Primary = 77
    case WardMissionaries = 1310
    case Other = 1185
    
    static let wardOrgTypes = [Bishopric, HighPriests, Elders, ReliefSociety, YoungMen, YoungWomen, SundaySchool, Primary, WardMissionaries, Other]
    
    static let branchOrgTypes = [BranchPresidency, HighPriests, Elders, ReliefSociety, YoungMen, YoungWomen, SundaySchool, Primary, Other]
    
}

