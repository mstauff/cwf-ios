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
    
    /// A guid (uuid) for us to be able to identify a calling that doesn't have an ID assigned from LCR
    let cwfId : String?
    
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
    
    /// Indicates that this calling was changed outside of the app (i.e. the calling was recorded or updated in LCR). This enum will allow us to visually mark the calling so the user can be aware of the change.
    var conflict : ConflictCause? = nil
    
    // reference back to the parent org that this calling is a member of. It is only optional because we create the org with the callings and then fill in the reference to the owning org afterwards.
    var parentOrg : Org?
    
    // flag to indicate whether a calling was created by cwf app. We can't just rely on cwfId, because a position can exist in LCR, and just be empty in which case we will assign a cwfId to it. This allows us to differentiate between empty callings in LCR and callings that have been created in CWF when reconciling callings between the two
    var cwfOnly = false
    
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
    
    var nameWithTime : String {
        get {
            var result = ""
            if let nameString = self.position.mediumName  {
                result = nameString +  "(" + self.existingMonthsInCalling.description + "M)"
            }
            return result
        }
    }
    
    var nameWithStatus : String {
        get {
            var result = ""
            if let nameString = self.position.mediumName  {
                result = nameString +  "(" + self.proposedStatus.description + ")"
            }
            return result
        }
    }
    
    /** Copy constructor. The position is a separate argument to be able to provide a position with updated position metadata (this is used when we're merging the position metadata with the callings, we want to keeps the metadata a let constant, so we create a new calling with an updated Position object) */
    init( _ calling: Calling, position: Position ) {
        self.init( id: calling.id, cwfId: calling.cwfId, existingIndId : calling.existingIndId, existingStatus: calling.existingStatus, activeDate: calling.activeDate, proposedIndId: calling.proposedIndId, status: calling.proposedStatus, position: position, notes: calling.notes, parentOrg : calling.parentOrg, cwfOnly : calling.cwfOnly)
    }
    
    /** Create an empty calling with a given position. This is used by reconcile and add calling to create a new empty calling of a certain type */
    init( forPosition position: Position ) {
        self.init(id: nil, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: nil, status: nil, position: position, notes: nil, parentOrg: nil, cwfOnly: false)
    }
    
    init(id : Int64?, cwfId : String?, existingIndId: Int64?, existingStatus : ExistingCallingStatus?, activeDate : Date?, proposedIndId : Int64?, status : CallingStatus?, position : Position, notes : String?, parentOrg : Org?, cwfOnly : Bool) {
        self.id = id
        // if ID is not set then either cwfID has to contain a value, or we'll generate a UUID.
        self.cwfId = Calling.generateCwfId( id: id, cwfId: cwfId )
        self.existingIndId = existingIndId
        self.proposedIndId = proposedIndId
        self.proposedStatus = status ?? .None
        self.position = position
        self.notes = notes
        self.parentOrg = parentOrg
        self.existingStatus = existingStatus ?? .None
        self.activeDate = activeDate
        self.cwfOnly = cwfOnly
    }
    
    public init?(fromJSON json: JSONObject) {
        guard
            let validPosition = Position(fromJSON: json)
            else {
                return nil
        }
        id = (json[CallingJsonKeys.id] as? NSNumber)?.int64Value
        cwfId = Calling.generateCwfId( id: id, cwfId: json[CallingJsonKeys.cwfId] as? String )
        position = validPosition
        // if there is a status value in the JSON we try to convert it to a known value, otherwise we set it to unknown (indicating there was a status, but we don't have an equivalent enum). If there's no status in the json then we default to none
        if let statusStr = json[CallingJsonKeys.proposedStatus] as? String {
            proposedStatus = CallingStatus( rawValue:statusStr ) ?? .Unknown
        } else {
            proposedStatus = .None
        }
        
        if let statusStr = json[CallingJsonKeys.existingStatus] as? String {
            existingStatus = ExistingCallingStatus( rawValue:statusStr ) ?? .Unknown
        } else {
            existingStatus = .None
        }
        
        existingIndId = (json[CallingJsonKeys.existingIndId] as? NSNumber)?.int64Value
        proposedIndId = (json[CallingJsonKeys.proposedIndId] as? NSNumber)?.int64Value
        // if notes are "null" then it comes through as NSNull, so we need to check if it's an actual string before assigning it. If it's not a string then we just use nil
        let notesJson = json[CallingJsonKeys.notes]
        notes = notesJson is String ? notesJson as? String : nil
        parentOrg = nil
        cwfOnly = JSONParseUtil.boolean(fromJsonField: json[CallingJsonKeys.cwfOnly], defaultingTo: false)
        
        activeDate = Date( fromLCRString: (json[CallingJsonKeys.activeDate] as? String ?? "") )
    }

    static func generateCwfId( id: Int64?, cwfId: String? ) -> String? {
        return id == nil ? cwfId ?? UUID().uuidString : cwfId
    }
    
    public func toJSONObject() -> JSONObject {
        var jsonObj = JSONObject()
        jsonObj[CallingJsonKeys.id] = self.id as AnyObject
        jsonObj[CallingJsonKeys.cwfId] = self.cwfId as AnyObject
        jsonObj[CallingJsonKeys.proposedStatus] = self.proposedStatus.rawValue as AnyObject
        jsonObj[CallingJsonKeys.existingStatus] = self.existingStatus.rawValue as AnyObject
        jsonObj[CallingJsonKeys.existingIndId] = self.existingIndId as AnyObject
        jsonObj[CallingJsonKeys.activeDate] = self.activeDate?.lcrDateString() as AnyObject
        jsonObj[CallingJsonKeys.proposedIndId] = self.proposedIndId as AnyObject
        jsonObj[CallingJsonKeys.notes] = self.notes as AnyObject
        jsonObj[CallingJsonKeys.cwfOnly] = self.cwfOnly as AnyObject
        jsonObj = jsonObj.merged( withDictionary: position.toJSONObject() )
        return jsonObj;
    }
    

    /** Method returns true if the two elements are already in order, false if they're not in order*/
    public static func sortByDisplayOrder( c1: Calling, c2: Calling ) -> Bool {
        var result : Bool
        // since the displayOrder for positions can be nil we need to account for this. It will be nil for things like teachers for a specific class, HT/VT Dist. Supervisors, etc. and also for assistant secretaries (basically for anything that allows multiples, it appears). So anything that's nil needs to be sorted to the bottom of the list, if both are nil then there is no determinant order, just whichever order they're in, they stay in
        if c1.position.displayOrder == nil || c2.position.displayOrder == nil {
            // if either is nil (could be both) then we just look at the 2nd item. If they're both nil then they are already in order so this will return true. If the first is nil, but the 2nd isn't this will return false so they'll be switched. If the first is not nil and the 2nd is nil then this will return true.
            result = c2.position.displayOrder == nil
        } else {
            // at this point we know they're both non nil, so just use the display order
            result = c1.position.displayOrder! < c2.position.displayOrder!
        }
        return result
    }

    /** Returns a copy of the calling with any actual calling details removed (potential calling info is retained) */
    public func withActualReleased() -> Calling {
        return Calling(id: nil, cwfId: self.cwfId, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: self.proposedIndId, status: self.proposedStatus, position: self.position, notes: self.notes, parentOrg: self.parentOrg, cwfOnly: self.cwfOnly)
    }

    enum ChangeOperation {
        case Create
        case Release
        case Update
        case Delete
    }
    

    
}

extension Calling : Equatable {
    /** This method does not compare all data in the calling objects. If the CDOL ID is the same for both they are considered equal, but it does not mean the content of the objects is equal. If the ID's are not set, we look parentOrg, position and our internal cwfId to try to match */
    static public func == (lhs : Calling, rhs : Calling ) -> Bool {
        var result = false
        
        // The parentOrg and the position have to be the same for it to be considered for a match based on any other criteria. We don't know for sure it's a match just based on those 2 factors, but we do know it's NOT a match if those at least aren't the same
        if lhs.parentOrg == rhs.parentOrg && lhs.position == rhs.position {
            // If the LCR ID's are not nil and they are the same then we know it's a match, or if multiples are not allowed then we know it's a match (we've already determined it's the same position, so if we can only have 1 EQ Sec. then we know we're the same calling), also if it's a custom calling and the position matches (based on positionTypeId) then it's the same. LCR gives a unique positionTypeId to each custom position.
            if (lhs.id != nil && lhs.id == rhs.id) || !lhs.position.multiplesAllowed || lhs.position.custom {
                result = true
            } else if lhs.cwfId != nil {
                // the final check is our own internal cwfId. If that matches then it's the same calling.
                result = lhs.cwfId == rhs.cwfId
            }
        }
        
        return result
        
    }
}

extension Array where Iterator.Element == Calling {
    public func namesWithTime() -> String {
        return self.map({$0.nameWithTime}).joined(separator: ", ")
    }
    
    public func namesWithStatus() -> String {
        return self.map( {$0.nameWithStatus} ).joined( separator: ", " )
    }
}

private struct CallingJsonKeys {
    static let id = "positionId"
    static let cwfId = "cwfId"
    static let proposedStatus = "proposedStatus"
    static let existingStatus = "existingStatus"
    static let activeDate = "activeDate"
    static let existingIndId = "memberId"
    static let proposedIndId = "proposedIndId"
    static let notes = "notes"
    static let cwfOnly = "cwfOnly"
}

