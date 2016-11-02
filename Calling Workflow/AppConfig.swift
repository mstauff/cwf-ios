//
//  AppConfig.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

struct AppConfig {
    var statuses : [String] = []
    var standardPositions : [Position] = []
    var ldsEndpointUrls = NetworkConstants.ldsOrgEndpoints
    var orgTypes : [OrgType] = []
    
}

extension AppConfig : JSONParsable {
    static func parseFrom(_ appConfigJSON: JSONObject) -> AppConfig? {
        var appConfig = AppConfig()
        
        if let statuses = appConfigJSON["statuses"] as? [String] {
            appConfig.statuses = statuses
        }
        //        if let standardPositions = appConfigJSON["positions"] as? [String] {
        //            appConfig.standardPositions = standardPositions
        //        }
        if let orgTypesJSON = appConfigJSON["orgTypes"] as? [JSONObject] {
            appConfig.orgTypes = orgTypesJSON.flatMap() {
                orgType in OrgType.parseFrom(orgType)
            }
        }
        // todo - run this to make sure it works, finish stanford lecture then see about writing tests
        if let endpointUrls = appConfigJSON["ldsEndpointUrls"] as? [JSONObject] {
            // EndpointUrls are an array of dictionaries where each dictionary should only have one entry. The key is some call ID and the value is the relative URL
            // i.e. [{"MEMBER_LIST":"/directory/list"},{"CALLING_LIST":"/directory/callings"}] so we want to loop through each element in the array, get the key/value
            // and store it in the app config
            for endPointUrl in endpointUrls {
                let validEndpointKeys = NetworkConstants.ldsOrgEndpointKeys
                let (key, value) = endPointUrl[endPointUrl.startIndex]
                guard value is String && validEndpointKeys.contains(key) else {
                    break
                }
                appConfig.ldsEndpointUrls[key] = value as? String
                
                
            }
        }
        // todo - finish deserialization
        
        
        return appConfig
    }
    
}
