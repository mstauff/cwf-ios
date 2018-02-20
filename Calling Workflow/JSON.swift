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

public class JSONParseUtil {
    // Util method for handling a boolean from json that may be bool or string
    public static func boolean( fromJsonField jsonValue: AnyObject?, defaultingTo defaultVal : Bool ) -> Bool {
        var result = defaultVal
        if let boolVal = jsonValue as? Bool {
            result = boolVal
        } else if let stringVal = jsonValue as? String, !stringVal.isEmpty {
            result = stringVal.lowercased() == "true"
        }
        return result
    }
}

public protocol JSONSerializer {
    func serialize( jsonObject : JSONObject ) -> String?
}
public class JSONSerializerImpl : JSONSerializer  {
    public func prepare( jsonObject : JSONObject ) -> NSDictionary {
        let jsonDictionary : NSMutableDictionary = [:]
        for( jsonKey, jsonVal ) in jsonObject {
            if jsonVal is String {
                jsonDictionary[jsonKey] = jsonVal as? String
            } else if jsonVal is Bool {
                jsonDictionary[jsonKey] = jsonVal as? Bool
            } else if jsonVal is Int {
                jsonDictionary[jsonKey] = jsonVal as? Int
            } else if jsonVal is Int64 {
                jsonDictionary[jsonKey] = NSNumber(value: (jsonVal as? Int64)!)
            } else if jsonVal is [Int] {
                jsonDictionary[jsonKey] = jsonVal as? [Int]
            } else if jsonVal is [Int64] {
                let int64Arr = jsonVal as? [Int64]
                if let nsNumArray = int64Arr?.flatMap({ NSNumber( value: $0 ) }) {
                    jsonDictionary[jsonKey] = nsNumArray
                }
            } else if jsonVal is [String] {
                jsonDictionary[jsonKey] = jsonVal as? [String]
            } else if jsonVal is [JSONObject] {
                jsonDictionary[jsonKey] = (jsonVal as! Array).map() { jsonObj -> NSDictionary in
                    return prepare( jsonObject: jsonObj )
                }
            } else if jsonVal is JSONObject {
                jsonDictionary[jsonKey] = prepare( jsonObject: (jsonVal as? JSONObject)! )
            } else {
                if jsonVal is NSNull {
                    //  ignore - no need to add
                    //the JSONObject stores nil fields as NSNull - those are valid, we just don't need to include them in the JSON
                } else {
                    // it's some value we didn't handle - log so we can track down the issue
                    debugPrint("JSONSerializerImpl.prepare - unable to handle value for " + jsonKey + " with value of " + jsonVal.description)
                }
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

/** Class to load a json file that is included with the app. Not sure if this will work for files that we need to write back to the filesystem. */
public class JSONFileReader {
    
    /** Reads the specified JSON file from the filesystem and returns it as a JSONObject. The filename should just be the name, not the extension. The filename extension needs to be .js */
    public  func getJSON( fromFile : String ) -> JSONObject {
        let bundle = Bundle( for: type(of: self) )
        var result = JSONObject()
        if let filePath = bundle.path(forResource: fromFile, ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            if let validJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? JSONObject {
                result = validJSON
            }
        } else {
            print( "No File Path found for file" )
        }
        return result
    }
    
    /** Reads the specified JSON file from the filesystem and returns it as an array of JSONObject. The filename should just be the name, not the extension. The filename extension needs to be .js */
    public func getJSONArray( fromFile : String ) -> [JSONObject] {
        let bundle = Bundle( for: type(of: self) )
        var result : [JSONObject] = []
        if let filePath = bundle.path(forResource: fromFile, ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            if let validJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [JSONObject] {
                result = validJSON
            }
        } else {
            print( "No File Path found for file" )
        }
        return result
    }
}

