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
    // todo - do we need this? This comes from the LCR call for an org? If we need then we populate from there
    var standardPositions : [Position] = []
    // default list of endpoints in case we can't contact the config URL
    var ldsEndpointUrls = NetworkConstants.ldsOrgEndpoints
//    var orgTypes : [OrgType] = []
    
}

extension AppConfig : JSONParsable {
    public init?(_ appConfigJSON: JSONObject) {
        
            statuses = appConfigJSON["statuses"] as? [String] ?? []
//        if let orgTypesJSON = appConfigJSON["orgTypes"] as? [JSONObject] {
//            appConfig.orgTypes = orgTypesJSON.flatMap() {
//                orgType in OrgType.parseFrom(orgType)
//            }
//        }
        // todo - run this to make sure it works, finish stanford lecture then see about writing tests
        if let endpointUrls = appConfigJSON["ldsEndpointUrls"] as? [JSONObject] {
            // EndpointUrls are an array of dictionaries where each dictionary should only have one entry. The key is some call ID and the value is the relative URL
            // i.e. [{"MEMBER_LIST":"/directory/list"},{"CALLING_LIST":"/directory/callings"}] so we want to loop through each element in the array, get the key/value and store it in the app config
            for endPointUrl in endpointUrls {
                let validEndpointKeys = NetworkConstants.ldsOrgEndpointKeys
                let (key, value) = endPointUrl[endPointUrl.startIndex]
                guard value is String && validEndpointKeys.contains(key) else {
                    break
                }
                ldsEndpointUrls[key] = value as? String
            }
        }
        
    }
    
    // we don't ever need to serialize this, so this method is unused
    func toJSONObject() -> JSONObject {
        return JSONObject()
    }
    
}
