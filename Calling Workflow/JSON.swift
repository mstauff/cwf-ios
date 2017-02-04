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

public protocol JSONParsable {
    init?( fromJSON: JSONObject)
    func toJSONObject() -> JSONObject
}

public protocol JSONSerializer {
    func serialize( jsonObject : JSONObject ) -> String?
}
public class JSONSerializerImpl : JSONSerializer  {
    public func prepare( jsonObject : JSONObject ) -> NSDictionary {
        let jsonDictionary : NSMutableDictionary = [:]
        for( jsonKey, jsonVal ) in jsonObject {
            // We don't have support for Bool types. They need to be stored in the jsonObject as strings
            // before it becomes an AnyObject. Once it gets cast to AnyObject it gets converted to a 
            // 0/1 Int, so it gets handled by the is Int case below
            if jsonVal is String {
                jsonDictionary[jsonKey] = jsonVal as? String
            } else if jsonVal is Int {
                jsonDictionary[jsonKey] = jsonVal as? Int
            } else if jsonVal is Int64 {
                jsonDictionary[jsonKey] = NSNumber(value: (jsonVal as? Int64)!)
            } else if jsonVal is [JSONObject] {
                jsonDictionary[jsonKey] = (jsonVal as! Array).map() { jsonObj -> NSDictionary in
                    return prepare( jsonObject: jsonObj )
                }
            } else if jsonVal is JSONObject {
                jsonDictionary[jsonKey] = prepare( jsonObject: (jsonVal as? JSONObject)! )
            }
        }
        return NSDictionary(dictionary: jsonDictionary)
    }

    public func serialize( jsonObject : JSONObject ) -> String? {
        var jsonString : String? = nil
        do {
            let jsonDictionary = prepare( jsonObject : jsonObject )
            
            let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary )
            jsonString = String( data: jsonData, encoding: .utf8 ) ?? ""
            
        } catch {
            // do nothing - just return nil
        }
        
        return jsonString
    }
    
}

