//
//  JsonFileReader.swift
//  Calling WorkflowTests
//
//  Created by Matt Stauffer on 3/9/18.
//  Copyright © 2018 colsen. All rights reserved.
//

import Foundation
@testable import Calling_Workflow

class JsonFileLoader {
    func loadJsonFromFile(_ fileName: String) -> JSONObject {
        let bundle = Bundle( for: type(of: self) )
        if let filePath = bundle.path(forResource: fileName, ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            if let jsonObj = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject] {
                return jsonObj
            }
        } else {
            print( "No File Path found for file" )
        }
        return JSONObject()
    }

    func loadJsonArrayFromFile(_ fileName: String) -> [JSONObject] {
        let bundle = Bundle( for: type(of: self) )
        if let filePath = bundle.path(forResource: fileName, ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            if let jsonObj = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [AnyObject] {
                return (jsonObj as? [JSONObject]) ?? []
            }
        } else {
            print( "No File Path found for file" )
        }
        return []
    }
    
    func getOrgFromFile( fileName: String, orgJsonName: String ) -> Org? {
        var result : Org? = nil
        let allOrgsJSON = loadJsonFromFile(fileName)
        result = Org( fromJSON: (allOrgsJSON[orgJsonName] as? JSONObject)! )
        
        return result
    }
    
    func getSingleOrgFromFile( fileName: String ) -> Org? {
        var result = Org(id: 111, unitNum: 111, orgTypeId: UnitLevelOrgType.Ward.rawValue)
        let bundle = Bundle( for: type(of: self) )
        if let filePath = bundle.path(forResource: fileName, ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            let testJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [AnyObject]
            result.children = Org.orgArrays( fromJSONArray: (testJSON as? [JSONObject])! )
            
        } else {
            print( "No File Path found for file" )
        }
        
        return result
    }
    
    func getOrgsFromFile( fileName: String, orgJsonName: String ) -> [Org] {
        var result : [Org] = []
        let bundle = Bundle( for: type(of: self) )
        if let filePath = bundle.path(forResource: fileName, ofType: "js"),
            let fileData = NSData(contentsOfFile: filePath) {
            
            let jsonData = Data( referencing: fileData )
            print( jsonData.debugDescription )
            let testJSON = try! JSONSerialization.jsonObject(with: jsonData, options: []) as? [String:AnyObject]
            result = Org.orgArrays( fromJSONArray: (testJSON?[orgJsonName] as? [JSONObject])! )
            
        } else {
            print( "No File Path found for file" )
        }
        
        return result
    }
    


}
