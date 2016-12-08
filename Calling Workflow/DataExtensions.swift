//
//  DataExtensions.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 12/7/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import Foundation

/**
 Data object extension to convert data to array of JSONObjects, or a single JSONObject
 */
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
