//
//  Constants.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

struct NetworkConstants {
    static let configUrl = "http://dev-ldscd.rhcloud.com/cwf/config?env=test"
    
    static let memberListURLKey = "MEMBER_LIST"
    static let callingsListURLKey = "CALLING_LIST"
    static let userDataURLKey = "USER_DATA"
    static let signInURLKey = "SIGN_IN"
    static let signOutURLKey = "SIGN_OUT"
    static let updateCallingURLKey = "UPDATE_CALLING"
    
    // these are defaults - they will potentially be overridden by results from the configUrl
    static let ldsOrgEndpoints = [ memberListURLKey : "https://www.lds.org/mobiledirectory/services/ludrs/1.1/mem/mobile/member-detaillist/:unitNum", callingsListURLKey : "https://www.lds.org/mls/mbr/services/orgs/sub-orgs-with-callings", userDataURLKey : "https://www.lds.org/mobiledirectory/services/v2/ldstools/current-user-detail", signInURLKey : "https://signin.lds.org/login.html", signOutURLKey: "https://www.lds.org/signinout/?lang=eng&signmeout" ]
    static var ldsOrgEndpointKeys : [String] {
        // implicit get for computed properties that are read only
        return [String](ldsOrgEndpoints.keys)
    }
    
    static let ldsOrgSignInUsernameParam = "username"
    static let ldsOrgSignInPasswordParam = "password"
}

struct RemoteStorageConstants {
    // for right now we have a single file. Eventually will likely have a file per sub org.
    static let dataFileName = "cwf-unit-data.json"
    // taken from google developers console. This is particular to local dev machine. When we approach shipping will
    // need to get a prod level one
    static let oauthClientId = "***REMOVED***"
    // This is just a name to use as a key to store the google credentials in the keychain, can be anything just needs to 
    // be the same between writes to & reads from keychain
    static let authTokenKeychainId = "cwf-google-oauth"
    
    static let dataFileMimeType = "application/json"
    // special Application Data folder available in google drive that is not viewable by users outside the app that created it
    static let dataFileFolder = "appDataFolder"
    static let dataFileExtension = ".json"
    
}

struct MemberConstants {
    static let minimumAge = 11
}

struct ErrorConstants {
    static let domain = "org.ldscd"
    
    static let networkError = 400
    static let notFound = 404
    static let jsonParseError = 450
    static let jsonSerializeError = 455
    static let illegalArgument = 460
}
