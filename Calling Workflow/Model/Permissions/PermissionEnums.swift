//
//  PermissionEnums.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 5/16/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

public enum RoleType {
    case UnitAdmin
    case PriesthoodOrgAdmin
    case OrgAdmin
    case StakeAssistant
    
    static let allValues : [RoleType] = [.UnitAdmin, .PriesthoodOrgAdmin, .OrgAdmin, .StakeAssistant]
}

/** The different objects that can be acted upon. Without splitting into permissions and domain we have a lot of repeat type permissions (i.e. updatePotentialCalling, updateActiveCalling, updateGoogleAcctSeetings, etc.), by splitting them into Domain (objects) and Permission (actions) we can then combine the object with the relevant set of actions to get our total permissions. Not all actions can be performed on every object. validDomainPermissions contains the total valid actions for each domain */
public enum Domain {
    case OrgInfo
    case PotentialCalling
    case ActiveCalling
    case UnitGoogleAccount
    case PriesthoodOffice
    
    static let validDomainPermissions : [Domain: [Permission]] = [ .OrgInfo : [.View],
                                                                   .PriesthoodOffice: [.View],
                                                                   .PotentialCalling : [.Create, .Update, .Delete],
                                                                   .ActiveCalling : [.Update, .Delete, .Release],
                                                                   .UnitGoogleAccount: [.Create, .Update]]
}

/** The actions that can be taken on different objects (Domains) */
public enum Permission {
    case View
    case Create
    case Update
    case Delete
    case Release
}

/** Positions that have some role in the application. The Int value is the cdol position ID that will be in the current-user & org structure JSON*/
public enum PositionType : Int {
    case StakePres = 1
    case Stake1stCounselor = 2
    case Stake2ndCounselor = 3
    case StakeHighCouncilor = 94
    case StakeExecSec = 51
    case StakeClerk = 52
    
    
    case Bishop = 4
    case Bishopric1stCounselor = 54
    case Bishopric2ndCounselor = 55
    case WardExecSec = 56
    case WardClerk = 57
    //    case WardAsstClerk = 58
    
    case BranchPres = 12
    case Branch1stCounselor = 59
    case Branch2ndCounselor = 60
    case BranchClerk = 789
    case BranchExecSec = 1278
    // case BranchAsstClerk = 790
    
    case HPGroupLeader = 133
    case HP1stAssistant = 134
    case HP2ndAssistant = 135
    case HPSecretary = 136
    //    case HPAsstSecretary = ???
    
    case EQPres = 138
    case EQ1stCounselor = 139
    case EQ2ndCounselor = 140
    case EQSecretary = 141
    // case EQAsstSecretary = ???
    
    case RSPres = 143
    case RS1stCounselor = 144
    case RS2ndCounselor = 145
    case RSSecretary = 146
    // case RSAsstSec = ???
    
    case YMPres = 158
    case YM1stCounselor = 159
    case YM2ndCounselor = 160
    case YMSecretary = 161
    
    case YWPres = 183
    case YW1stCounselor = 184
    case YW2ndCounselor = 185
    case YWSecretary = 186
    
    case SSPres = 204
    case SS1stCounselor = 205
    case SS2ndCounselor = 206
    case SSSecretary = 207
    
    case PrimaryPres = 210
    case Primary1stCounselor = 211
    case Primary2ndCounselor = 212
    case PrimarySecretary = 213
    
    var roleType : RoleType {
        switch self {
        case .Bishop, .Bishopric1stCounselor, .Bishopric2ndCounselor, .WardExecSec, .WardClerk :
            return RoleType.UnitAdmin
        case .BranchPres, .Branch1stCounselor, .Branch2ndCounselor, .BranchExecSec, .BranchClerk :
            return RoleType.UnitAdmin
        case .HPGroupLeader, .HP1stAssistant, .HP2ndAssistant, .HPSecretary :
            return .PriesthoodOrgAdmin
        case .EQPres, .EQ1stCounselor, .EQ2ndCounselor, .EQSecretary :
            return .PriesthoodOrgAdmin
        case .YMPres, .YM1stCounselor, .YM2ndCounselor, .YMSecretary :
            return .PriesthoodOrgAdmin
        case .RSPres, .RS1stCounselor, .RS2ndCounselor, .RSSecretary :
            return .OrgAdmin
        case .YWPres, .YW1stCounselor, .YW2ndCounselor, .YWSecretary :
            return .OrgAdmin
        case .SSPres, .SS1stCounselor, .SS2ndCounselor, .SSSecretary :
            return .OrgAdmin
        case .PrimaryPres, .Primary1stCounselor, .Primary2ndCounselor, .PrimarySecretary :
            return .OrgAdmin
        case .StakePres, .Stake1stCounselor, .Stake2ndCounselor, .StakeExecSec, .StakeClerk :
            return .UnitAdmin
        case .StakeHighCouncilor :
            return .StakeAssistant
        }
    }
    
    var orgType : UnitLevelOrgType? {
        switch self {
        case .Bishop, .Bishopric1stCounselor, .Bishopric2ndCounselor, .WardExecSec, .WardClerk :
            return .Bishopric
        case .BranchPres, .Branch1stCounselor, .Branch2ndCounselor, .BranchExecSec, .BranchClerk :
            return .BranchPresidency
        case .HPGroupLeader, .HP1stAssistant, .HP2ndAssistant, .HPSecretary :
            return .HighPriests
        case .EQPres, .EQ1stCounselor, .EQ2ndCounselor, .EQSecretary :
            return .Elders
        case .YMPres, .YM1stCounselor, .YM2ndCounselor, .YMSecretary :
            return .YoungMen
        case .RSPres, .RS1stCounselor, .RS2ndCounselor, .RSSecretary :
            return .ReliefSociety
        case .YWPres, .YW1stCounselor, .YW2ndCounselor, .YWSecretary :
            return .YoungWomen
        case .SSPres, .SS1stCounselor, .SS2ndCounselor, .SSSecretary :
            return .SundaySchool
        case .PrimaryPres, .Primary1stCounselor, .Primary2ndCounselor, .PrimarySecretary :
            return .Primary
        case .StakePres, .Stake1stCounselor, .Stake2ndCounselor, .StakeExecSec, .StakeClerk :
            return nil
        case .StakeHighCouncilor :
            return nil
        }
    }
}



