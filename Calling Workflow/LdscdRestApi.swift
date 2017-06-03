//
//  LdscdRestApi.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 1/5/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

/* Extension of RestAPI for making network call to LDS Comm. Developers web services (for now it's just the app config) */
class LdscdRestApi : RestAPI {
    
    var appConfig : AppConfig? = nil
    
    /* Returns (via callback) an AppConfig object with the URL's and other config data for the app */
    func getAppConfig(_ completionHandler: @escaping ( _ appConfig:AppConfig?, _ error:NSError? ) -> Void) {
        if self.appConfig != nil {
            completionHandler( self.appConfig, nil )
        } else {
            
            doGet(url: NetworkConstants.configUrl, completionHandler: { (data, response, error) -> Void in
                
                print( "Response: \(response.debugDescription) Data: " + data.debugDescription + " Error: " + error.debugDescription )
                
                // error will be returned in cases of no route to host, etc. If it's a http error returned from the server error will be nil. That case is handled below
                guard error == nil else {
                    print( "Error: " + error.debugDescription )
                    completionHandler( nil, error as NSError? )
                    return
                }
                
                // according to docs a http error returned from the server will not populate the error variable. It will be in the http response code, so check for that
                if let httpResponse = response as? HTTPURLResponse {
                    let responseCode = httpResponse.statusCode
                    if RestAPI.isErrorResponse( responseCode ) {
                        let errorMsg = "Error: network error: \(responseCode)"
                        completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.networkError, userInfo: [ "error" : errorMsg ] ) )
                        return
                    }
                }
                
                guard let responseData = data else {
                    let errorMsg = "Error: No network error, but did not recieve data from \(NetworkConstants.configUrl)"
                    print( errorMsg )
                    completionHandler( nil, NSError( domain: ErrorConstants.domain, code: 404, userInfo: [ "error" : errorMsg ] ) )
                    return
                }
                
                self.appConfig = AppConfig( fromJSON: responseData.jsonDictionaryValue! )
                completionHandler( self.appConfig, nil )
            })
        }
        
    }
}

protocol LdscdApiInjected { }

extension LdscdApiInjected {
    var ldscdApi:LdscdRestApi { get { return InjectionMap.ldscdApi } }
}

