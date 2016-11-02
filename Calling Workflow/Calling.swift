//
//  Calling.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 10/28/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

struct Calling : JSONParsable {
    let id : Int64
    let currentIndId : Int64?
    let proposedIndId : Int64?
    let status : String
    let position : Position
    let notes : String?
    let editableByOrg : Bool
    let parentOrg : Org?
    
    
    static func parseFrom(_ json: JSONObject) -> Calling? {
        guard
            let id = json["id"] as? Int64,
            let status = json["status"] as? String,
            let position = Position.parseFrom(json["position"] as! JSONObject)
            else {
                return nil
        }
        return Calling( id:id, currentIndId: json["currentIndId"] as! Int64?, proposedIndId: json["proposedIndId"] as! Int64?, status: status, position: position, notes: json["notes"] as! String?, editableByOrg: true, parentOrg: nil )
    }
    
}
