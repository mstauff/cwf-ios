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
    // These values are defined in Debug.xcconfig, Test.xcconfig and Release.xcconfig files. We provide a default prod value in case there are errors loading any of the vars
    
    // whether we want to ensure that the google drive account is associated with the lds unit. Should be true for prod, false for dev
    static let authRemoteDataWithLdsAcct = (configValue(forKey: "Authorize Remote Data with LDS account") ?? "true").boolValue

    // whether we want to hit actual lds.org endpoints, or just use local sample json data. Should be true for dev, false for prod
    static let useLdsOrgData =  (configValue(forKey: "Use LDS org data") ?? "true").boolValue
    
    static let configUrl = configValue(forKey: "AppConfig URL") ?? "http://dev-config-server-ldscd.7e14.starter-us-west-2.openshiftapps.com/cwf/config"
    
    static private func configValue(forKey key: String) -> String? {
        return (Bundle.main.infoDictionary?[key] as? String)?
            .replacingOccurrences(of: "\\", with: "")
    }
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
