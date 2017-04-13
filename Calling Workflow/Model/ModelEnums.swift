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


