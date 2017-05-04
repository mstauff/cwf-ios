//
//  CallingStatus.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 1/19/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

public enum CallingStatus : String {
    
    case Proposed = "PROPOSED"
    case Submitted = "SUBMITTED"
    case Approved = "APPROVED"
    case ReSubmit = "RE_SUBMIT"
    case NotApproved = "NOT_APPROVED"
    case OnHold = "ON_HOLD"
    case AppointmentSet = "APPT_SET"
    case Extended = "EXTENDED"
    case Accepted = "ACCEPTED"
    case Refused = "REFUSED"
    case ReadyToSustain = "READY_TO_SUSTAIN"
    case Sustained = "SUSTAINED"
    case SetApart = "SET_APART"
    case Recorded = "RECORDED"
    case Unknown = "UNKNOWN"
    case None = "NONE"
    
    static let allValues = [ Proposed, Submitted, Approved, ReSubmit, NotApproved, OnHold, AppointmentSet, Extended, Accepted, Refused, ReadyToSustain, Sustained, SetApart, Recorded, Unknown, None]
    
}

public enum ExistingCallingStatus : String {
    
    case Unknown = "UNKNOWN"
    case Active = "ACTIVE"
    case NotifiedOfRelease = "NOTIFIED_OF_RELEASE"
    case Released = "RELEASED"
    case None = "NONE"

}

public enum ConflictCause {
    case LdsEquivalentDeleted
    case EquivalentPotentialAndActual
}

public enum Gender : String {
    case Male = "MALE"
    case Female = "FEMALE"
    
    public init?( optionalRaw: String? ) {
        guard optionalRaw != nil
            else {
                return nil
        }
        switch(optionalRaw!) {
        case  "MALE": self = .Male
        case "FEMALE" : self = .Female
        default: return nil
        }
    }
    
    // We have to write our own init as the default one apparently isn't visible outside the file the enum is declared in (everything worked fine when HTVTMemberParser was part of Member.swift, but as soon as we moved it to it's own file it could no longer use the default initializer. Since we had to write a manual one anyway I went ahead and created one to make the rawvalue optional
    public init?( rawValue: String ) {
        self.init( optionalRaw: rawValue )
    }
}

public enum Priesthood : String {
    case Deacon = "DEACON"
    case Teacher = "TEACHER"
    case Priest = "PRIEST"
    case Elder = "ELDER"
    case HighPriest = "HIGH_PRIEST"
    case Seventy = "SEVENTY"
    
    public init?( optionalRaw: String? ) {
        guard optionalRaw != nil
            else {
                return nil
        }
        switch(optionalRaw!) {
        case  "DEACON": self = .Deacon
        case "TEACHER" : self = .Teacher
        case  "PRIEST": self = .Priest
        case  "ELDER": self = .Elder
        case  "HIGH_PRIEST": self = .HighPriest
        case  "SEVENTY": self = .Seventy
        default: return nil
        }
    }
    
    // We have to write our own init as the default one apparently isn't visible outside the file the enum is declared in (everything worked fine when HTVTMemberParser was part of Member.swift, but as soon as we moved it to it's own file it could no longer use the default initializer. Since we had to write a manual one anyway I went ahead and created one to make the rawvalue optional
    public init?( rawValue: String ) {
        self.init( optionalRaw: rawValue )
    }
    
    static let allValues = [Deacon, Teacher, Priest, Elder, HighPriest, Seventy]
}

public enum MemberClass : String {
    case ReliefSociety = "RELIEF_SOCIETY"
    case Laurel = "LAUREL"
    case MiaMaid = "MIAMAID"
    case Beehive = "BEEHIVE"
    
    public init?( optionalRaw: String? ) {
        guard optionalRaw != nil else {
                return nil
        }
        switch(optionalRaw!) {
        case  "RELIEF_SOCIETY": self = .ReliefSociety
        case "LAUREL" : self = .Laurel
        case  "MIAMAID": self = .MiaMaid
        case  "BEEHIVE": self = .Beehive
        default: return nil
        }
    }
    
    // We have to write our own init as the default one apparently isn't visible outside the file the enum is declared in (everything worked fine when HTVTMemberParser was part of Member.swift, but as soon as we moved it to it's own file it could no longer use the default initializer. Since we had to write a manual one anyway I went ahead and created one to make the rawvalue optional
    public init?( rawValue: String ) {
        self.init( optionalRaw: rawValue )
    }
    
    static let allValues = [ReliefSociety, Laurel, MiaMaid, Beehive]
}



