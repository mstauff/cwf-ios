//
//  Position.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

public struct Position : JSONParsable {
    let id : Int64?
    let positionTypeId : Int
    let name : String
    let description : String?
    let hidden : Bool
    
    public static func parseFrom(_ json: JSONObject) -> Position? {
        guard
            let positionTypeId = json["positionTypeId"] as? Int,
            let hidden = json["hidden"] as? Bool,
            let name = json["name"] as? String
            else {
                return nil
        }
        return Position( id:json["id"] as! Int64?, positionTypeId: positionTypeId, name: name, description: json["description"] as! String?, hidden: hidden )
    }
    
}
