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
    let currentIndId : Int64?
    
    /// The individual ID of the person that is being considered to hold this calling.
    let proposedIndId : Int64?
    
    /// The current status of the calling, i.e. "PROPOSED", "ACCEPTED", etc. It's optional as a calling from LCR that is not being changed would have no status. We opted for a String rather than an enum due to the fact that the list of statuses is customizable by the user.
    // TODO - should we make this an enum and make the customization take the form of just selecting the statuses they want to use
    let status : String?
    
    /// The position that is being filled, i.e. Primary Teacher, RS 2nd Counselor, etc.
    let position : Position
    
    /// Optional notes about the calling. Could include other people that might be considered, or if somebody declined, etc.
    let notes : String?
    
    /// I'm not 100% sure how this will be used, but the use case is that the EQ Pres. can modify anything in the EQ, but not themselves. This may actually belong on the Position object rather than the calling?
    let editableByOrg : Bool
    
    // reference back to the parent org that this calling is a member of. It is only optional because we create the org with the callings and then fill in the reference to the owning org afterwards.
    var parentOrg : Org?
    
    
    public static func parseFrom(_ json: JSONObject) -> Calling? {
        guard
            let position = Position.parseFrom(json)
            else {
                return nil
        }
        let status = json["status"] as? String
        let id = json["positionId"] as? NSNumber
        let currentIndIdNum = json["memberId"] as? NSNumber
        let proposedIndIdNum = json["proposedIndId"] as? NSNumber
        return Calling( id:id?.int64Value, currentIndId: currentIndIdNum?.int64Value, proposedIndId: proposedIndIdNum?.int64Value, status: status, position: position, notes: json["notes"] as? String, editableByOrg: true, parentOrg: nil )
    }
    
}
