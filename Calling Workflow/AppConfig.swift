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
    
    public init?( fromJSON appConfigJSON: JSONObject) {
        
        statuses = appConfigJSON["statuses"] as? [String] ?? []
        //        if let orgTypesJSON = appConfigJSON["orgTypes"] as? [JSONObject] {
        //            appConfig.orgTypes = orgTypesJSON.flatMap() {
        //                orgType in OrgType.parseFrom(orgType)
        //            }
        //        }
        if let endpointUrls = appConfigJSON["ldsEndpointUrls"] as? JSONObject {
            // EndpointUrls is basically a dictionary. The key is some call ID and the value is the relative URL. We loop through our list of keys (in NetworkConstants) for all the web calls we need to make, if there's a URL for a given call then we'll update it in this app config. If there's not a URL for a given call then we'll leave the default (from NetworkConstants.ldsOrgEndpoints) in place. This way it only gets updated if there's an overriding value that came in the results from the server.
            let validEndpointKeys = NetworkConstants.ldsOrgEndpointKeys
            for endPointKey in validEndpointKeys {
                if let endpointUrl = endpointUrls[endPointKey] as? String {
                    ldsEndpointUrls[endPointKey] = endpointUrl
                }
            }
        }
    }
    
    // we don't ever need to serialize this, so this method is unused
    func toJSONObject() -> JSONObject {
        return JSONObject()
    }
    
}
