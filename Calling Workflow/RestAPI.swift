//
//  RestAPI.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/26/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

enum HttpMethod : String {
    case Get = "GET"
    case Post = "POST"
}

enum HttpContentType : String {
    case Json = "application/json"
    case Form = "application/x-www-form-urlencoded"
}

/* This class is intended to be like a java abstract class, it shouldn't be instantiated directly. It's meant to be used by a concrete subclass, it just provides the basic plumbing for session/cookie management for making network requests, with simplified doGet & doPost methods */
class RestAPI {
    
    let session : URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 300
        session = URLSession( configuration: config )        
    }
    
//    deinit {
        //todo: this is being called while the request is still active. Need to figure out WHY? originally had .invalidateAndCancel() here
//        session.finishTasksAndInvalidate()
//    }
    
    /* Function to perform the actual http request to the server. If the method is GET the bodyPayload & contentType are ignored, currently they are only used if they are included with a POST request (we don't have any need for param support on GET requests as of this writing). This method does not perform any processing on the results, it just invokes the completion handler with what came from the session.dataTask(). Note that a 4xx or 5xx returned from the server will NOT be populated in the Error object in the callback. You have to check the URLResponse.responseCode for that. The Error will only be set if there is an error in connecting to the resource, so something like no network, no route to host, etc. would result in the error being non nil */
    func performRequest( url urlString : String, httpMethod : HttpMethod, bodyPayload : String?, contentType : HttpContentType?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        guard let url = URL( string: urlString ) else {
            let errorMsg = "Error: cannot create URL: " + urlString
            print( errorMsg )
            completionHandler(nil, nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        var restRequest = URLRequest( url:  url )
        restRequest.addValue(HttpContentType.Json.rawValue, forHTTPHeaderField: NetworkConstants.acceptHeader)
        if httpMethod == .Post {
            restRequest.httpMethod = httpMethod.rawValue
            if let body = bodyPayload {
//                restRequest.httpBody = body.data( using: .utf8 )
                restRequest.httpBody = Data( body.utf8 )
            }

            // default is form, so we only need to set it if it's Json
            if contentType == .Json {
                restRequest.addValue(contentType!.rawValue, forHTTPHeaderField: NetworkConstants.contentTypeHeader)
            }            
        }
        
        print( "Request Type: " + restRequest.httpMethod! )
        if restRequest.httpBody != nil {
         print( "payload: " + String(data: restRequest.httpBody!, encoding: .utf8)!)
        }
        let task = session.dataTask(with: restRequest, completionHandler: completionHandler)
        
        task.resume()
    }
    
    func doGet( url : String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        performRequest(url: url, httpMethod: .Get, bodyPayload: nil, contentType: nil, completionHandler: completionHandler)
    }
    
    func doPost( url: String, params : [String:String]?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        let postBody = params == nil ? nil : RestAPI.toHttpParams( from: params! )

        performRequest(url: url, httpMethod: .Post, bodyPayload: postBody, contentType: .Form, completionHandler: completionHandler)
    }

    func doPost( url: String, bodyPayload : String?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        performRequest(url: url, httpMethod: .Post, bodyPayload: bodyPayload, contentType: .Json, completionHandler: completionHandler)
    }
    
    /* Checks if a response code is considered http success (basically 200-299) and returns true if it is */
    static func isSuccessResponse( _ responseCode : Int ) -> Bool {
        return responseCode >= 200 && responseCode < 300;
    }

    /* Checks if a response code is an http error (basically 4xx or 5xx) and returns true if it is */
    static func isErrorResponse( _ responseCode : Int ) -> Bool {
        return responseCode >= 400;
    }
    
    /* Helper method to convert a dictionary of key/value pairs to an http param string in the format of key=value&key2=val2 */
    static func toHttpParams( from params: [String:String] ) -> String {
        var paramString = ""
        for paramKey in params.keys {
            // since we accessing params[x] by looping through the keys it should be safe to ! the result. It's necessary because otherwise swift creates a string of "username=Optional[bob]" vs "username=bob"
            paramString.append( "\(paramKey)=\(params[paramKey]!)&" )
        }
        // strip the trailing &
        if !paramString.isEmpty {
            paramString.remove(at: paramString.index(before: paramString.endIndex))
        }
        return paramString

    }
    
}
