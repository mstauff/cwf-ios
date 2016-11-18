//
//  Position.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

public struct Position : JSONParsable {
    let positionTypeId : Int
    let name : String
    let hidden : Bool
    
    public static func parseFrom(_ json: JSONObject) -> Position? {
        guard
            let positionTypeId = json["positionTypeId"] as? Int,
            let name = json["position"] as? String
            else {
                return nil
        }
        let hidden = json["hidden"] as? Bool ?? false
        return Position( positionTypeId: positionTypeId, name: name, hidden: hidden )
    }
    
}
