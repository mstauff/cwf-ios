//
//  CallingStatus.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 1/19/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

public enum CallingStatus : String {
    
    var description : String {
        return CallingStatus.descriptionDictionary[self] ?? "Unknown"
    }
    
    case Proposed = "PROPOSED"
    case Submitted = "SUBMITTED"
    case Approved = "APPROVED"
    case Resubmit = "RESUBMIT"
    case NotApproved = "NOT_APPROVED"
    case OnHold = "ON_HOLD"
    case AppointmentSet = "APPOINTMENT_SET"
    case Extended = "EXTENDED"
    case Accepted = "ACCEPTED"
    case Refused = "REFUSED"
    case ReadyToSustain = "READY_TO_SUSTAIN"
    case Sustained = "SUSTAINED"
    case SetApart = "SET_APART"
    case Recorded = "RECORDED"
    case Unknown = "UNKNOWN"
    case None = "NONE"
    
    static let allValues = [ Proposed, Submitted, Approved, Resubmit, NotApproved, OnHold, AppointmentSet, Extended, Accepted, Refused, ReadyToSustain, Sustained, SetApart, Recorded, Unknown, None]
    // Unknown is reserved for system use - cannot be selected by the user
    static let userValues = allValues.filter() {$0 != .Unknown}
    static let descriptionDictionary : [CallingStatus:String] = allValues.toDictionary() {
        return ($0, $0.rawValue.replacingOccurrences(of: "_", with: " ").localizedCapitalized)
    }
    
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

protocol FilterButtonEnum   {
    var description:String{get}
    var rawValue:String{get}
    
}

extension MemberClass : FilterButtonEnum {
    public var description : String {
        return MemberClass.descriptionDictionary[self] ?? "Unknown"
    }
    
    static let descriptionDictionary : [MemberClass:String] = allValues.toDictionary() {
        return ($0, $0.rawValue.replacingOccurrences(of: "_", with: " ").localizedCapitalized.replacingOccurrences(of:"Miamaid", with: "MiaMaid"))
    }    

}

extension Priesthood : FilterButtonEnum {
    public var description : String {
        return Priesthood.descriptionDictionary[self] ?? "Unknown"
    }
    
    static let descriptionDictionary : [Priesthood:String] = allValues.toDictionary() {
        return ($0, $0.rawValue.replacingOccurrences(of: "_", with: " ").localizedCapitalized)
    }
}


