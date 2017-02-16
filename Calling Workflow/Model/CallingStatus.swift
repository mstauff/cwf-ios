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
    case Rejected = "REJECTED"
    case OnHold = "ON_HOLD"
    case AppointmentSet = "APPT_SET"
    case Extended = "EXTENDED"
    case Accepted = "ACCEPTED"
    case Declined = "DECLINED"
    case Sustained = "SUSTAINED"
    case SetApart = "SET_APART"
    case Recorded = "RECORDED"
    case Unknown = "UNKNOWN"
    case None = "NONE"
    
    
}

public enum ExistingCallingStatus : String {
    
    case Unknown = "UNKNOWN"
    case Active = "ACTIVE"
    case NotifiedOfRelease = "NOTIFIED_OF_RELEASE"
    case Released = "RELEASED"
    case None = "NONE"

}
