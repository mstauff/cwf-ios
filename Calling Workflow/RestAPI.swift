//
//  RestAPI.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/26/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

class RestAPI {
    
    static func getAppConfig(_ completionHandler: @escaping ( _ appConfig:AppConfig?, _ error:NSError? ) -> Void) {
        guard let url = URL( string: NetworkConstants.configUrl ) else {
            let errorMsg = "Error: cannot create URL: " + NetworkConstants.configUrl
            print( errorMsg )
            completionHandler( nil, NSError( domain: ErrorConstants.domain, code: 404, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        
        let restRequest = URLRequest( url:  url )
        
        let config = URLSessionConfiguration.default
        let session = URLSession( configuration: config )
        
        let task = session.dataTask(with: restRequest, completionHandler: { (data, response, error) -> Void in
            
            print( "Response: \(response.debugDescription) Data: " + data.debugDescription + " Error: " + error.debugDescription )
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler( nil, error as NSError? )
                return
            }
            
            guard let responseData = data else {
                let errorMsg = "Error: No network error, but did not recieve data from \(NetworkConstants.configUrl)"
                print( errorMsg )
                completionHandler( nil, NSError( domain: ErrorConstants.domain, code: 404, userInfo: [ "error" : errorMsg ] ) )
                return
            }
            
                completionHandler( AppConfig.parseFrom( responseData.jsonDictionaryValue! ), nil )
        }) 
        
        task.resume()
    }
}
