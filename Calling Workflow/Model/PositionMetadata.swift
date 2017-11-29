//
//  PositionMetadata.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 4/28/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

public struct PositionMetadata : JSONParsable {
   
    /// The position type ID that is assigned by CDOL
    let positionTypeId : Int

    /// A shorter name that can be used when we already have the org context (Teacher vs. Primary Teacher, or District Supervisor vs. High Priests Home Teaching District Supervisor)
    let shortName : String?
    
    /// A medium name that includes the context, but uses common abbreviations (so HP 1st Asst.) to shorten names from the full name
    let mediumName : String?
    
    /// Set of requirements (Priesthood, gender or age) if there are any for the position
    var requirements : PositionRequirements?
    
    /** Function to create an array of PositionMetadata from an array of JSON objects. We store them as just an array of elements,  */
    static func positionArrays( fromJSONArray json: [JSONObject]) -> [PositionMetadata] {
        let positions : [PositionMetadata] = json.flatMap() {
            PositionMetadata(fromJSON: $0)
        }
        return positions
    }
    
    // todo - can eventually add who can propose 
    public init() {
        positionTypeId = -1
        shortName = nil
        mediumName = nil
        requirements = nil
    }
    
    public init?(fromJSON json: JSONObject) {
        guard
            let validPositionTypeId = json[PositionMetadataJsonKeys.positionTypeId] as? Int
            else {
                return nil
        }
        shortName = json[PositionMetadataJsonKeys.shortName] as? String
        mediumName = json[PositionMetadataJsonKeys.mediumName] as? String
        positionTypeId = validPositionTypeId
        
        if let validRequirements = json[PositionMetadataJsonKeys.requirements] as? JSONObject {
            requirements = PositionRequirements(fromJSON: validRequirements)
        } else {
            requirements = nil
        }
    }

    /** Unused - we never need to serialize this object */
    public func toJSONObject() -> JSONObject {
        return JSONObject()
    }

    private struct PositionMetadataJsonKeys {
        static let positionTypeId = "positionTypeId"
        static let shortName = "shortName"
        static let mediumName = "mediumName"
        static let requirements = "requirements"
    }
}

extension PositionMetadata : Equatable {
    static public func == (lhs: PositionMetadata, rhs: PositionMetadata ) -> Bool {
        return lhs.positionTypeId == rhs.positionTypeId && lhs.shortName == rhs.shortName && lhs.mediumName == rhs.mediumName && lhs.requirements == rhs.requirements
    }
}

