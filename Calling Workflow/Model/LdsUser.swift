//
//  LdsUser.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 1/11/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

//TODO: tests for this class - need some local json in the test files first
/* This represents the result of a call to currentUserData which we use to get the individuals callings so we can determine permissions */
struct LdsUser : JSONParsable {
    
    let individualId : Int64
    let positions : [Position]
    
    public init( individualId : Int64, positions : [Position] ) {
        self.individualId = individualId
        self.positions = positions
    }
    
    public init?( _ json: JSONObject ) {
        guard
            
        let indId = (json[ "individualId" ] as? NSNumber)?.int64Value,
        let jsonPositions = json["memberAssignments"] as? [JSONObject]
            else {
                return nil
        }
        
        self.individualId = indId
        var userPositions : [Position] = []
        for jsonPosition in jsonPositions {
            if let position = Position( jsonPosition ) {
                userPositions.append( position )
            }
        }
        self.positions = userPositions
        
    }
    
    public func toJSONObject() -> JSONObject {
        // we never serialize this to json, so nothing to implement
        return JSONObject();
    }

}
