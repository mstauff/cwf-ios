//
//  OrgType.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

struct OrgType : JSONParsable {
    
    let id : Int
    let name : String
    
    static func parseFrom(_ json: JSONObject) -> OrgType? {
        guard
            let id = json["id"] as? Int,
            let name = json["name"] as? String
            else {
                return nil
        }
        let orgType = OrgType( id:id, name: name )
        return orgType
    }
    
}

