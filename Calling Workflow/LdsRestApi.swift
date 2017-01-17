//
//  ldsRestApi.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 1/6/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

/* Extension of RestAPI for making calls to retrieve data for LDS.org. Calling code should start by always calling ldsSignin to make sure the user has a valid OBSSOCookie before making any other calls */
class LdsRestApi : RestAPI, LdsOrgApi {
    
    var appConfig : AppConfig
    
    init( appConfig : AppConfig ) {
        self.appConfig = appConfig
        super.init()
    }
    
    func setAppConfig( appConfig : AppConfig ) {
        self.appConfig = appConfig
    }
    
    // At some point it would be good to see if we can check for the cookie first - we probably need to save that manually, along with the last access time
    /*
     Method to signin with the given username and password. The completion handler only includes an error. If this method was successful the error will be nil, there's nothin else returned. It stores the OBSSOCookie, which is basically what's required for authentication with the other lds.org services.
     */
    func ldsSignin(username: String, password: String,_ completionHandler: @escaping ( _ error:NSError? ) -> Void) {
        
        let loginCredentialParams = [ NetworkConstants.ldsOrgSignInUsernameParam : username, NetworkConstants.ldsOrgSignInPasswordParam: password ]
        
        // ok to use ! for endpointUrls. We start with default values, and the ones that come from
        // the network only will override the default if they exist. We don't just replace the entire
        // set of defaults with what came from the network, which could potentially be incomplete
        doPost( url: appConfig.ldsEndpointUrls[NetworkConstants.signInURLKey]!, params: loginCredentialParams ) {
            (data, response, error) -> Void in
            
            print( "Response: \(response.debugDescription) Data: " + data.debugDescription + " Error: " + error.debugDescription )
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler(error as NSError? )
                return
            }
            
            guard let responseData = data else {
                let errorMsg = "Error: No network error, but did not recieve data from \(NetworkConstants.ldsOrgEndpoints["SIGN_IN"]!)"
                print( errorMsg )
                completionHandler(NSError( domain: ErrorConstants.domain, code: 404, userInfo: [ "error" : errorMsg ] ) )
                return
            }
            
            completionHandler(nil)
        }
        
    }
    
    /*
     Gets the current user. This method is so we can get the callings that the current user has to grant permissions.
     */
    func getCurrentUser( _ completionHandler: @escaping ( LdsUser?, Error? ) -> Void ) {
        let url = appConfig.ldsEndpointUrls[NetworkConstants.userDataURLKey]!
        doGet(url: url ) { data, response, error in
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler(nil, error as Error? )
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let responseCode = httpResponse.statusCode
                if RestAPI.isErrorResponse( responseCode ) {
                    let errorMsg = "Error: network error: \(responseCode)"
                    completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.networkError, userInfo: [ "error" : errorMsg ] ) )
                    return
                }
            }
            
            guard let responseData = data, let jsonData = responseData.jsonDictionaryValue else {
                let errorMsg = "Error: No network error, but did not recieve data from \(url)"
                print( errorMsg )
                completionHandler( nil, NSError( domain: ErrorConstants.domain, code: 404, userInfo: [ "error" : errorMsg ] ) )
                return
            }
            print( "Current User: \(jsonData)" )
            
            completionHandler( LdsUser( fromJSON: jsonData ), nil )
            
            
        }
    }
    
    /* Returns a list of members (via callback) for the given unit. This will include all members age 11+. Family structure is not preserved. */
    func getMemberList( unitNum : Int64, _ completionHandler: @escaping ( [Member]?, Error? ) -> Void ) {
        var url = appConfig.ldsEndpointUrls[NetworkConstants.memberListURLKey]!
        url = url.replacingOccurrences(of: ":unitNum", with: String(unitNum))
        doGet(url: url ) { data, response, error in
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler( nil, error )
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let responseCode = httpResponse.statusCode
                if RestAPI.isErrorResponse( responseCode ) {
                    let errorMsg = "Error: network error: \(responseCode)"
                    completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.networkError, userInfo: [ "error" : errorMsg ] ) )
                    return
                }
            }
            
            guard let responseData = data else {
                let errorMsg = "Error: No network error, but did not recieve data from \(url)"
                print( errorMsg )
                completionHandler( nil, NSError( domain: ErrorConstants.domain, code: 404, userInfo: [ "error" : errorMsg ] ) )
                return
            }
            
            var memberList : [Member] = []
            let json = responseData.jsonDictionaryValue;
            let jsonMemberList = json?["families"] as? [JSONObject]
            if jsonMemberList != nil {
                let htvtMemberParser = HTVTMemberParser()
                for jsonFamily in jsonMemberList! {
                    let members = htvtMemberParser.parseFamilyFrom(json: jsonFamily)
                    memberList.append( contentsOf: members )
                }
                
            }
            
            completionHandler( memberList, nil )
            
        }
    }
    
    func getOrgWithCallings( unitNum : Int64, _ completionHandler: @escaping ( Org?, Error? ) -> Void ) {
        // TODO - implement this
    }
    
}
