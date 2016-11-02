//
//  Constants.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

struct NetworkConstants {
    static let configUrl = "http://dev-ldscd.rhcloud.com/cwf/config"
    
    static let memberListURLKey = "MEMBER_LIST"
    static let callingsListURLKey = "CALLING_LIST"
    
    static let ldsOrgEndpoints = [ memberListURLKey : "/directory/list", callingsListURLKey : "/directory/callings" ]
    static var ldsOrgEndpointKeys : [String] {
        // implicit get for computed properties that are read only
        return [String](ldsOrgEndpoints.keys)
    }
}

struct RemoteStorageConstants {
    // for right now we have a single file. Eventually will likely have a file per sub org.
    static let dataFileName = "cwf-unit-data.json"
    // taken from google developers console. This is particular to local dev machine. When we approach shipping will
    // need to get a prod level one
    static let oauthClientId = "1055866482667-m0ublpvsibgvseenble8l112rr1gboou.apps.googleusercontent.com"
    // This is just a name to use as a key to store the google credentials in the keychain, can be anything just needs to 
    // be the same between writes to & reads from keychain
    static let authTokenKeychainId = "cwf-google-oauth"
    
    static let dataFileMimeType = "application/json"
    // special Application Data folder available in google drive that is not viewable by users outside the app that created it
    static let dataFileFolder = "appDataFolder"
    
}

struct ErrorConstants {
    static let domain = "org.ldscd"
}
