//
//  AppConfig.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

struct AppConfig {
    // default list of endpoints in case we can't contact the config URL
    var ldsEndpointUrls = NetworkConstants.ldsOrgEndpoints

}

extension AppConfig {

    // whether we want to ensure that the google drive account is associated with the lds unit. Should be true for prod, false for dev
    static let validateRemoteDataAgainstLdsAccount = false

    // whether we want to hit actual lds.org endpoints, or just use local sample json data. Should be true for dev, false for prod
    static let useLocalLdsOrgData = true
}

extension AppConfig : JSONParsable {
    
    public init?( fromJSON appConfigJSON: JSONObject) {
        
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
