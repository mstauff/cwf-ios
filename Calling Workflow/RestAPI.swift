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

/* This class is intended to be like a java abstract class, it shouldn't be instantiated directly. It's meant to be used by a concrete subclass, it just provides the basic plumbing for session/cookie management for making network requests, with simplified doGet & doPost methods */
class RestAPI {
    
    let session : URLSession
    
    init() {
        let config = URLSessionConfiguration.default
        session = URLSession( configuration: config )        
    }
    
//    deinit {
        //todo: this is being called while the request is still active. Need to figure out WHY? originally had .invalidateAndCancel() here
//        session.finishTasksAndInvalidate()
//    }
    
    /* Function to perform the actual http request to the server. If the method is GET the paramaters are ignored, currently they are only used if they are included with a POST request (although it will be easy to add them if/when they become needed for a GET). This method does not perform any processing on the results, it just invokes the completion handler with what came from the session.dataTask(). Note that a 4xx or 5xx returned from the server will NOT be populated in the Error object in the callback. You have to check the URLResponse.responseCode for that. The Error will only be set if there is an error in connecting to the resource, so something like no network, no route to host, etc. would result in the error being non nil */
    func performRequest( url urlString : String, httpMethod : HttpMethod, params :[String:String]?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        guard let url = URL( string: urlString ) else {
            let errorMsg = "Error: cannot create URL: " + urlString
            print( errorMsg )
            completionHandler(nil, nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        
        var restRequest = URLRequest( url:  url )
        if httpMethod == .Post {
            restRequest.httpMethod = httpMethod.rawValue
            if params != nil && !params!.isEmpty {
                let postBody = RestAPI.toHttpParams( from: params! )
                restRequest.httpBody = postBody.data( using: .utf8 )
            }
        }
        
        let task = session.dataTask(with: restRequest, completionHandler: completionHandler)
        
        task.resume()
    }
    
    func doGet( url : String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        performRequest(url: url, httpMethod: .Get, params: nil, completionHandler: completionHandler)
    }
    
    func doPost( url: String, params : [String:String]?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        performRequest(url: url, httpMethod: .Post, params: params, completionHandler: completionHandler)
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
