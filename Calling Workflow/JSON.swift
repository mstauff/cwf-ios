//
//  JSON.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 9/2/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

// JSONObject is a dictionary with Strings as keys and AnyObject as value
public typealias JSONObject = [String:AnyObject]

public extension Data {
    public var jsonArrayValue : [JSONObject] {
        guard
        let json = try? JSONSerialization.jsonObject(with: self, options: []),
        let objects = json as? [JSONObject]
            else {
                return[]
        
        }
        return objects
    }
    
    public var jsonDictionaryValue : JSONObject? {
        guard
        let json = try? JSONSerialization.jsonObject(with: self, options: []),
        let object = json as? JSONObject
            else {
                return nil
        }
        return object
    }
}

public protocol JSONParsable {
    static func parseFrom( _ object: JSONObject) -> Self?
//    func toJSON() -> String
}
