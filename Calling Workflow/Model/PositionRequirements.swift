//
//  PositionRequirements.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 4/27/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

public struct PositionRequirements : JSONParsable {
    
    let gender : Gender?
    
    // whether the position generally requires an adult. This will match enable the 18+ filter if it is set. We don't currently know a use case for a youth Bool, but could add that also if need arises
    let adult : Bool
    
    let priesthood : [Priesthood]
    
    let memberClasses : [MemberClass]
    
    
    
    public init?( fromJSON json: JSONObject) {
        gender = Gender.init( optionalRaw: json[PositionRequirementsJsonKeys.gender] as? String )
        
        adult = json[PositionRequirementsJsonKeys.adult] as? Bool ?? false
        
        let priesthoodOffices = json[PositionRequirementsJsonKeys.priesthood] as? [String] ?? []
        priesthood = priesthoodOffices.map() { Priesthood.init( optionalRaw: $0 ) }.flatMap() { $0 } // .flatMap() will remove any nill objects

        let classes = json[PositionRequirementsJsonKeys.memberClasses] as? [String] ?? []
        memberClasses = classes.map() { MemberClass.init( optionalRaw: $0 ) }.flatMap() { $0 }
        
    }
    
    /** Shouldn't need to be called, so for now just return an empty object */
    public func toJSONObject() -> JSONObject {
        return JSONObject()
    }

    private struct PositionRequirementsJsonKeys {
        static let gender = "gender"
        static let adult = "adult"
        static let priesthood = "priesthood"
        static let memberClasses = "memberClasses"
    }

}

extension PositionRequirements : Equatable {
    static public func == (lhs: PositionRequirements, rhs: PositionRequirements ) -> Bool {
        return lhs.gender == rhs.gender && lhs.adult == rhs.adult && lhs.priesthood == rhs.priesthood && lhs.memberClasses == rhs.memberClasses
    }
}

