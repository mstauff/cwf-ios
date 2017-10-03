//
//  Constants.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

struct NetworkConstants {
    static let configUrl = "http://dev-config-server-ldscd.7e14.starter-us-west-2.openshiftapps.com/cwf/config?env=test"
    
    static let memberListURLKey = "MEMBER_LIST"
    static let callingsListURLKey = "CALLING_LIST"
    static let userDataURLKey = "USER_DATA"
    static let signInURLKey = "SIGN_IN"
    static let signOutURLKey = "SIGN_OUT"
    static let updateCallingURLKey = "UPDATE_CALLING"
    
    // these are defaults - they will potentially be overridden by results from the configUrl
    static let ldsOrgEndpoints = [ memberListURLKey : "https://www.lds.org/htvt/services/v1/:unitNum/members", callingsListURLKey : "https://www.lds.org/mls/mbr/services/orgs/sub-orgs-with-callings", userDataURLKey : "https://www.lds.org/mobiledirectory/services/v2/ldstools/current-user-detail", signInURLKey : "https://signin.lds.org/login.html", signOutURLKey: "https://www.lds.org/signinout/?lang=eng&signmeout", updateCallingURLKey : "https://www.lds.org/mls/mbr/services/orgs/callings?lang=eng" ]
    
    // if hitting "https://test.lds.org/htvt/services/v1/:unitNum/members" for member list then the data is wrapped in an object with property data.families (that's the array that contains the ward list).
    // if hitting https://www.lds.org/mobiledirectory/services/ludrs/1.1/mem/mobile/member-detaillist/:unitNum the data is just a raw array that gets returned. As of 9/17 we're hitting the htvt service because it includes priesthood information
    static var ldsOrgEndpointKeys : [String] {
        // implicit get for computed properties that are read only
        return [String](ldsOrgEndpoints.keys)
    }
    
    static let ldsOrgSignInUsernameParam = "username"
    static let ldsOrgSignInPasswordParam = "password"
    
    static let contentTypeHeader = "Content-Type"
    static let acceptHeader = "Accept"
}

struct RemoteStorageConstants {
    
    static let dataFileMimeType = "application/json"
    // special Application Data folder available in google drive that is not viewable by users outside the app that created it
    static let dataFileFolder = "appDataFolder"
    static let dataFileExtension = ".json"
    static let configFileExtension = ".config"
    
}

struct MemberConstants {
    static let minimumAge = 11
}

struct ErrorConstants {
    static let domain = "org.ldscd"
    
    static let networkError = 400
    static let notAuthorized = 403
    static let notFound = 404
    static let jsonParseError = 450
    static let jsonSerializeError = 455
    static let illegalArgument = 460
    static let serviceError = 500
}

struct FilterConstants {
    static let youthMinAge = 12
    static let youthMaxAge = 17
    static let adultMinAge = 18
}
