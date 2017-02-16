//
//  Calling.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 10/28/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

/**
 Represents the relationship between an individual currently serving in a position, as well as a possible replacement candidate to a Position. Most fields are optional since you could have just a proposed calling, in which case it would not have a CDOL ID, or any combination of current or proposed individual ID's, as well as even the status which would likely be the case for a calling that is recorded in LCR and not currently in the process of changing.
 */
public struct Calling : JSONParsable {
    
    /// The ID assigned by CDOL. It's optional as the calling could just be in process and not exist in CDOL yet. This is positionId in the LCR JSON
    let id : Int64?
    
    /// The individual ID of the member that currently holds the calling. Is optional because there may not be anyone currently serving in the calling. This is memberId in the LCR JSON
    var existingIndId: Int64?
    
    /// The individual ID of the person that is being considered to hold this calling.
    var proposedIndId : Int64?
    
    /// The current status of the proposed calling, i.e. "PROPOSED", "ACCEPTED", etc. It's optional as a calling from LCR that is not being changed would have no status. We opted for a String rather than an enum due to the fact that the list of statuses is customizable by the user.
    var proposedStatus : CallingStatus

    /// The status of the existing calling, i.e. "ACTIVE" or "NOTIFIED_OF_RELEASE". We don't currently have support for this in the app, but for units that want to track that people have been notified, or that a release has been announced over the pulpit then they could use this field
    var existingStatus : ExistingCallingStatus

    /// The date that the existing individual's calling was made active. In LCR there are 2 fields: Active date and set apart date. The set apart date is set by the users and may or may not be set. It appears that the active date is set automatically by LCR and not really visible/editable by the user, so we're going to use that date.
    var activeDate : Date?
    
    /// The position that is being filled, i.e. Primary Teacher, RS 2nd Counselor, etc.
    let position : Position
    
    /// Optional notes about the calling. Could include other people that might be considered, or if somebody declined, etc.
    var notes : String?
    
    /// This will likely be removed and will depend on the calling of the user and the position of the calling, and we'll need to determine position privileges. So a primary pres can propose a calling, but nothing more, but an EQ Pres can propose and call teachers & HT supervisors
    let editableByOrg : Bool

    /// Indicates that this calling was changed outside of the app (i.e. the calling was recorded or updated in LCR). This enum will allow us to visually mark the calling so the user can be aware of the change.
    var conflict : Calling.ConflictCause? = nil
    
    // reference back to the parent org that this calling is a member of. It is only optional because we create the org with the callings and then fill in the reference to the owning org afterwards.
    var parentOrg : Org?

    var existingMonthsInCalling : Int {
        get {
            var numMonths = 0

            guard activeDate != nil else {
                return numMonths
            }
            numMonths = Calendar.current.dateComponents([.month], from: activeDate!, to: Date()).month ?? 0

            return numMonths
        }
    }
    
    init(id : Int64?, existingIndId: Int64?, existingStatus : ExistingCallingStatus?, activeDate : Date?, proposedIndId : Int64?, status : CallingStatus?, position : Position, notes : String?, editableByOrg : Bool, parentOrg : Org?) {
        self.id = id
        self.existingIndId = existingIndId
        self.proposedIndId = proposedIndId
        self.proposedStatus = status ?? .Unknown
        self.position = position
        self.notes = notes
        self.editableByOrg = editableByOrg
        self.parentOrg = parentOrg
        self.existingStatus = existingStatus ?? .Unknown
        self.activeDate = activeDate
    }
    
    public init?(fromJSON json: JSONObject) {
        guard
            let validPosition = Position(fromJSON: json)
            else {
                return nil
        }
        id = (json[CallingJsonKeys.id] as? NSNumber)?.int64Value
        position = validPosition
        var statusStr = json[CallingJsonKeys.proposedStatus] as? String ?? ""
        proposedStatus = CallingStatus( rawValue:statusStr ) ?? .Unknown

        statusStr = json[CallingJsonKeys.existingStatus] as? String ?? ""
        existingStatus = ExistingCallingStatus( rawValue:statusStr ) ?? .Unknown
        
        existingIndId = (json[CallingJsonKeys.existingIndId] as? NSNumber)?.int64Value
        proposedIndId = (json[CallingJsonKeys.proposedIndId] as? NSNumber)?.int64Value
        // if notes are "null" then it comes through as NSNull, so we need to check if it's an actual string before assigning it. If it's not a string then we just use nil
        let notesJson = json[CallingJsonKeys.notes]
        notes = notesJson is String ? notesJson as? String : nil
        editableByOrg = json[CallingJsonKeys.editableByOrg] as? Bool ?? true
        parentOrg = nil

        activeDate = Date( fromLCRString: (json[CallingJsonKeys.activeDate] as? String ?? "") )
    }
    
    public func toJSONObject() -> JSONObject {
        var jsonObj = JSONObject()
        jsonObj[CallingJsonKeys.id] = self.id as AnyObject
        jsonObj[CallingJsonKeys.proposedStatus] = self.proposedStatus.rawValue as AnyObject
        jsonObj[CallingJsonKeys.existingStatus] = self.existingStatus.rawValue as AnyObject
        jsonObj[CallingJsonKeys.existingIndId] = self.existingIndId as AnyObject
        jsonObj[CallingJsonKeys.activeDate] = self.activeDate?.lcrDateString() as AnyObject
        jsonObj[CallingJsonKeys.proposedIndId] = self.proposedIndId as AnyObject
        jsonObj[CallingJsonKeys.notes] = self.notes as AnyObject
        jsonObj = jsonObj.merge( withDictionary: position.toJSONObject() )
        return jsonObj;
    }

    public mutating func updateExistingCalling( withIndId indId : Int64?, activeDate : Date? ) {
        self.existingIndId = indId
        self.activeDate = activeDate
        self.existingStatus = .Active
    }

    public mutating func clearPotentialCalling() {
        self.notes = nil
        self.conflict = nil
        self.proposedIndId = nil
        self.proposedStatus = .None
    }

    enum ConflictCause {
        case LdsEquivalentDeleted
        case EquivalentPotentialAndActual
    }

}

extension Calling : Equatable {
    /* This method does not compare all data in the calling objects. If the CDOL ID is the same for both they are considered equal, but it does not mean the content of the objects is equal. If the ID's are not set, or not the same then we traverse through the object looking for combinations of parentOrg, proposedIndId & positionTypeId to determine if it's the same calling */
    static public func == (lhs : Calling, rhs : Calling ) -> Bool {
        var result = false

        // If there is an ID then that's all that matters
        if lhs.id != nil || rhs.id != nil {
            result = lhs.id == rhs.id
        } else if lhs.parentOrg == rhs.parentOrg {
            // if they don't have an ID they have to be in the same org and then either have the same proposedIndId & position type, or same position type & notes if there's not a proposed ind. ID
            if lhs.proposedIndId != nil || rhs.proposedIndId != nil {
                result = lhs.proposedIndId == rhs.proposedIndId && lhs.position.positionTypeId == rhs.position.positionTypeId
            } else {
                result = lhs.position.positionTypeId == rhs.position.positionTypeId && lhs.notes == rhs.notes
            }
        }

        return result
    }

}

private struct CallingJsonKeys {
    static let id = "positionId"
    static let proposedStatus = "proposedStatus"
    static let existingStatus = "existingStatus"
    static let activeDate = "activeDate"
    static let existingIndId = "memberId"
    static let proposedIndId = "proposedIndId"
    static let notes = "notes"
    static let editableByOrg = "editableByOrg"
}

