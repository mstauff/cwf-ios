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
    
    let age : Int?
    
    let priesthood : [Priesthood]
    
    let memberClasses : [MemberClass]
    
    
    
    public init?( fromJSON json: JSONObject) {
        gender = Gender.init( optionalRaw: json[PositionRequirementsJsonKeys.gender] as? String )
        
        age = json[PositionRequirementsJsonKeys.age] as? Int
        
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
        static let age = "age"
        static let priesthood = "priesthood"
        static let memberClasses = "memberClasses"
    }

}

extension PositionRequirements : Equatable {
    static public func == (lhs: PositionRequirements, rhs: PositionRequirements ) -> Bool {
        return lhs.gender == rhs.gender && lhs.age == rhs.age && lhs.priesthood == rhs.priesthood && lhs.memberClasses == rhs.memberClasses
    }
}

