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
    
    let multiplesAllowed : Bool
    
    let custom : Bool // custom 
    
    let displayOrder : Int?
    
    /// This should not change once set, but because it comes from a different source (not in the position JSON that comes from LCR, we need it to be var so we can set it after the position is init'ed from JSON)
    var metadata : PositionMetadata

    /// The short version of the name if it exists in the metadata, or just the regular name if there is no short name
    var shortName : String? {
        get  {
            return metadata.shortName ?? name
        }
    }
    
    var mediumName : String? {
        get {
            return metadata.mediumName ?? metadata.shortName ?? name
        }
    }
    

    init(positionTypeId : Int, name : String?, hidden : Bool, multiplesAllowed : Bool, displayOrder : Int?, metadata: PositionMetadata) {
        self.init(positionTypeId: positionTypeId, name: name, unitNum: nil, hidden: hidden, multiplesAllowed: multiplesAllowed, displayOrder : displayOrder, metadata: metadata, custom: false)
    }
    
    init(positionTypeId : Int, name : String?, unitNum : Int64?, hidden : Bool, multiplesAllowed : Bool, displayOrder : Int?, metadata: PositionMetadata) {
        self.init(positionTypeId: positionTypeId, name: name, unitNum: unitNum, hidden: hidden, multiplesAllowed: multiplesAllowed, displayOrder : displayOrder, metadata: metadata, custom: false)
    }
    
    init(positionTypeId : Int, name : String?, unitNum : Int64?, hidden : Bool, multiplesAllowed : Bool, displayOrder : Int?, metadata: PositionMetadata, custom: Bool) {
        self.positionTypeId = positionTypeId
        self.name = name
        self.hidden = hidden
        self.unitNum = unitNum
        self.multiplesAllowed = multiplesAllowed
        self.metadata = metadata
        self.displayOrder = displayOrder
        self.custom = custom
    }
    
    init( customPosition name: String, inUnitNum unitNum: Int64? ) {
        self.init(positionTypeId: 0, name: name, unitNum: unitNum, hidden: false, multiplesAllowed: true, displayOrder: nil, metadata: PositionMetadata(), custom: true)
    }
    
    public init?(fromJSON json: JSONObject) {
        guard
            let validPositionTypeId = json[PositionJsonKeys.positionTypeId] as? Int
            else {
                return nil
        }
        name = json[PositionJsonKeys.name] as? String
        
        if let validUnitNum = json[PositionJsonKeys.unitNum] {
            unitNum = (validUnitNum as? NSNumber)?.int64Value
        } else {
            unitNum = nil
        }
        positionTypeId = validPositionTypeId
        // We're defaulting to true, even though there are likely more positions that allowMultiples is false, if we default to false we could potentially identify different primary teaching positions as equivalent, and overwrite one when we shouldn't. If we default to true for a position that should be false then we might incorrectly not match an EQ 1st Counselor with the correct calling, resulting in duplicates. But that is much easier for a user to identify and correct than two callings that are incorrectly merged, or one just deleted, that could result in a loss of data
        // They should be written as booleans, but we also want to support them if they are strings ("true" vs true). We default to true if it's not in the JSON, or if it's an empty string.
        multiplesAllowed = JSONParseUtil.boolean(fromJsonField: json[PositionJsonKeys.allowMultiples], defaultingTo: true)
        hidden = JSONParseUtil.boolean(fromJsonField: json[PositionJsonKeys.hidden], defaultingTo: false)
        custom = JSONParseUtil.boolean(fromJsonField: json[PositionJsonKeys.custom], defaultingTo: false)


        displayOrder = json[PositionJsonKeys.displayOrder] as? Int
        metadata = PositionMetadata()
    }
    
    public func toJSONObject() -> JSONObject {
        var jsonObj = JSONObject()
        jsonObj[PositionJsonKeys.positionTypeId] = self.positionTypeId as AnyObject
        if let name = self.name {
            jsonObj[PositionJsonKeys.name] = name as AnyObject
        }
        if let unitNum = self.unitNum {
            jsonObj[PositionJsonKeys.unitNum] = unitNum as AnyObject
        }
        if let displayOrder = self.displayOrder {
            jsonObj[PositionJsonKeys.displayOrder] = displayOrder as AnyObject
        }
        jsonObj[PositionJsonKeys.hidden] = self.hidden  as AnyObject
        jsonObj[PositionJsonKeys.allowMultiples] = self.multiplesAllowed as AnyObject
        jsonObj[PositionJsonKeys.custom] = self.custom as AnyObject
        return jsonObj;
    }
    
}

extension Position : Equatable {
    static public func == (lhs : Position, rhs : Position ) -> Bool {
        // if the positionTypeId is 0 or less then it's a custom position, that hasn't been assigned a positionTypeId from LCR, so those are always unique. Once it's been given a positionTypeId by LCR then we can use that
        return lhs.positionTypeId > 0 ? lhs.positionTypeId == rhs.positionTypeId : false
    }
}

extension Position : Hashable {
    public var hashValue : Int {
        get { return positionTypeId.hashValue }
    }
}

private struct PositionJsonKeys {
    static let positionTypeId = "positionTypeId"
    static let name = "position"
    static let hidden = "hidden"
    static let allowMultiples = "allowMultiple"
    static let displayOrder = "positionDisplayOrder"
    static let custom = "custom"
    // this is not included in LCR org/calling data, but is included in current user details call and we need it to validate permissions
    static let unitNum = "unitNo"
}


