//
//  Position.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

/**
 Represents a specific Position, so Bishop, Primary Teacher, etc. It does not know anything about the person holding it, it is just the representation of the actual Position. All fields are required as there's not really a logical state where a field might not be populated or known. This is essentially a finite set of enums, we just don't make it an enum in our code so we don't have to duplicate everything that exists in the CDOL enums for positions.
 */
public struct Position : JSONParsable {
    
    /// The position type ID that is assigned by CDOL
    let positionTypeId : Int
    
    /// The name of the position - just used for display purposes
    let name : String?
    
    /// The unit number the position is in. This value is not set when filling in a calling in an org structure, but it is used when creating a position for LdsUser and when calculating permissions
    let unitNum : Int64?
    
    /**
     In LCR you can't remove some positions, but you can hide them if you want. I'm not sure the use case, but maybe in a situation where you don't have an EQ secretary, and don't plan to fill it you might want to hide the position rather than just leaving it blank. Also, if you have a class with multiple teachers, when there are more than one you can remove the extra teachers (actually remove the position, not just release the teacher), but once you are down to one the last one cannot be removed it can only be hidden.
     */
    let hidden : Bool
    
    // TODO: do we need something to indicate it's a custom calling? Or can we determine that from the positionTypeId????
    init(positionTypeId : Int, name : String?, hidden : Bool) {
        self.positionTypeId = positionTypeId
        self.name = name
        self.hidden = hidden
        self.unitNum = nil
    }
    
    public init?(fromJSON json: JSONObject) {
        guard
            let validPositionTypeId = json[PositionJsonKeys.positionTypeId] as? Int
            else {
                return nil
        }
        if let validName = json[PositionJsonKeys.name] {
            name = validName as? String
        } else {
            name = nil
        }
        if let validUnitNum = json[PositionJsonKeys.unitNum] {
            unitNum = (validUnitNum as? NSNumber)?.int64Value
        } else {
            unitNum = nil
        }
        positionTypeId = validPositionTypeId
        
        hidden = json[PositionJsonKeys.hidden] as? Bool ?? false
    }
    
    public func toJSONObject() -> JSONObject {
        var jsonObj = JSONObject()
        jsonObj[PositionJsonKeys.positionTypeId] = self.positionTypeId as AnyObject
        if self.name != nil {
            jsonObj[PositionJsonKeys.name] = self.name! as AnyObject
        }
        if self.unitNum != nil {
            jsonObj[PositionJsonKeys.unitNum] = self.unitNum! as AnyObject
        }
        // need to store this as a string rather than a bool before we cast to AnyObject, as casting a bool to AnyObject loses type info (it gets seen as Int and outputs 0/1 rather than true/false in the json
        jsonObj[PositionJsonKeys.hidden] = self.hidden.description as AnyObject
        return jsonObj;
    }
    
}

private struct PositionJsonKeys {
    static let positionTypeId = "positionTypeId"
    static let name = "position"
    static let hidden = "hidden"
    // this is not included in LCR org/calling data, but is included in current user details call and we need it to validate permissions
    static let unitNum = "unitNo"
}

