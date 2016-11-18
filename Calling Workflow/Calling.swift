//
//  Calling.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 10/28/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

public struct Calling : JSONParsable {
    let id : Int64?
    let currentIndId : Int64?
    let proposedIndId : Int64?
    let status : String
    let position : Position
    let notes : String?
    let editableByOrg : Bool
    var parentOrg : Org?
    
    
    public static func parseFrom(_ json: JSONObject) -> Calling? {
        guard
            let status = json["status"] as? String,
            let position = Position.parseFrom(json)
            else {
                return nil
        }
        let id = json["positionId"] as? NSNumber
        let currentIndIdNum = json["currentIndId"] as? NSNumber
        let proposedIndIdNum = json["proposedIndId"] as? NSNumber
        return Calling( id:id?.int64Value, currentIndId: currentIndIdNum?.int64Value, proposedIndId: proposedIndIdNum?.int64Value, status: status, position: position, notes: json["notes"] as! String?, editableByOrg: true, parentOrg: nil )
    }
    
}
