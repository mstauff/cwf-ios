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
    
    // the LCR calls all need to have a "position" field in them or the server returns a 500 error (even though the change still works ok). The text of the field doesn't matter, it just needs to be a non-empty string. Generally we'll use calling.position.name, but since that's optional if it is nil we'll fall back to this string.
    static let defaultPositionText = "unused"
    
    var appConfig : AppConfig
    
    private let jsonSerializer = JSONSerializerImpl()
    
    var sessionManager : SessionManager
    
    var userName: String? = nil
    
    var password: String? = nil
    
    init( appConfig : AppConfig ) {
        self.appConfig = appConfig
        // this creates a session manager, but by default the session is "expired" until we call sm.updateSession() which we only do after we login
        self.sessionManager = SessionManager(sessionTimeoutMinutes: 60)
        super.init()
    }
    
    func setAppConfig( appConfig : AppConfig ) {
        self.appConfig = appConfig
    }
    
    /** Override of RestAPI.doGet() that will check to see if the current session is valid before making the call. We don't add in the failsafe of handling a redirect to the signin page as all the GET calls are made at startup, so in reality we should never have a timeout issue on a GET. If usage of this call expands in the future it would be good to make this more robust */
    override func doGet( url : String, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        if sessionManager.isSessionValid() {
            super.doGet(url: url, completionHandler: completionHandler)
        } else {
            self.ldsSignin(username: userName!, password: password!) { error in
                guard error == nil else {
                    completionHandler( nil, nil, error )
                    return
                }
                super.doGet(url: url, completionHandler: completionHandler)
            }
        }
    }
    
    /** Override of RestAPI.doPost() that takes a JSON body payload (the version that takes key/val params is not affected, it only handles the login). This basically intercepts all the updates to LCR, it checks for an active session (and logs in and then makes the call if we know the session had expired). Additionally it inspects the response in case we lost the session without knowing it. It looks to see if the response was forwarded to the lds login, if so it logs in again and then re-attempts the call. */
    override func doPost( url: String, bodyPayload : String?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void ) {
        if sessionManager.isSessionValid() {
            super.doPost(url: url, bodyPayload: bodyPayload) { data, response, error in
                // check for redirect to login page due to loss of lds.org session. If it's a normal result the content type would be application/json. If it's a forward to login it's text/html
                if let httpResponse = response as? HTTPURLResponse, let responseUrl = httpResponse.url?.absoluteString, let contentType = httpResponse.allHeaderFields[NetworkConstants.contentTypeHeader] as? String, contentType.contains(NetworkConstants.contentTypeHtml) {
                    let responseCode = httpResponse.statusCode
                    // the session timeout will return a 200 OK, and the URL contains the sso/UI/Login
                    if RestAPI.isSuccessResponse( responseCode ) && responseUrl.contains("sso/UI/Login") {
                        // it was a session timeout, so login again and try again
                        self.ldsSignin(username: self.userName!, password: self.password!) { error in
                            guard error == nil else {
                                completionHandler( nil, nil, error )
                                return
                            }
                            super.doPost(url: url, bodyPayload : bodyPayload, completionHandler: completionHandler)
                        }
                    } else {
                        // it was some other type of error, not just a timed out session, so just pass the error along
                        completionHandler( data, response, error )
                    }
                } else {
                    // it was a normal response (not text/html). Update the session (you have an hour of no activity before it expires) then just pass it on up
                    self.sessionManager.updateSession()
                    completionHandler( data, response, error )
                }
            }
        } else {
            // we don't have a session, so re authenticate and attempt the POST
            self.ldsSignin(username: userName!, password: password!) { error in
                guard error == nil else {
                    completionHandler( nil, nil, error )
                    return
                }
                super.doPost(url: url, bodyPayload : bodyPayload, completionHandler: completionHandler)
            }
        }
    }

    /*
     Method to signin with the given username and password. The completion handler only includes an error. If this method was successful the error will be nil, there's nothing else returned. It stores the OBSSOCookie, which is basically what's required for authentication with the other lds.org services.
     */
    func ldsSignin(username: String, password: String,_ completionHandler: @escaping ( _ error:NSError? ) -> Void) {
        
        let loginCredentialParams = [ NetworkConstants.ldsOrgSignInUsernameParam : username, NetworkConstants.ldsOrgSignInPasswordParam: password ]
        // store the username/password for use later if we lose the lds.org session
        self.userName = username
        self.password = password
        
        // ok to use ! for endpointUrls. We start with default values, and the ones that come from the network only will override the default if they exist. We don't just replace the entire set of defaults with what came from the network, which could potentially be incomplete
        doPost( url: appConfig.ldsEndpointUrls[NetworkConstants.signInURLKey]!, params: loginCredentialParams ) {
            (data, response, error) -> Void in
            
            print( "Response: \(response.debugDescription) Data: " + data.debugDescription + " Error: " + error.debugDescription )
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler(error as NSError? )
                return
            }
            
            guard data != nil else {
                let errorMsg = "Error: No network error, but did not recieve data from \(NetworkConstants.ldsOrgEndpoints["SIGN_IN"]!)"
                print( errorMsg )
                completionHandler(NSError( domain: ErrorConstants.domain, code: 404, userInfo: [ "error" : errorMsg ] ) )
                return
            }
            // the obSSOCookie does not have an expires value, which means iOS will not persists the cookie beyond application life. Technically the cookie is good for 1 hour. We originally toyed with storing some cookie values in UserDefaults, but it would probably be more efficient to just read the cookie out of HTTPCookieStorage, and then use it to create a new cookie with an expires time of 1 hour (although we would need to extend it each time we interact with lds.org
            self.sessionManager.updateSession( )
            
            completionHandler(nil)
        }
        
    }
    
    /*
     Gets the current user. This method is so we can get the callings that the current user has to grant permissions.
     */
    func getCurrentUser( _ completionHandler: @escaping ( LdsUser?, Error? ) -> Void ) {
        let url = appConfig.ldsEndpointUrls[NetworkConstants.userDataURLKey]!
        // this method is only called at startup where we should always have a session, so not going to worry about checking it here
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
        // this method is only called at startup where we should always have a session, so not going to worry about checking it here. If we add a resync option that includes a new ward list then we may need to add session checking
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
            
            if let jsonMemberList = json?["families"] as? [JSONObject] {
                let htvtMemberParser = HTVTMemberParser()
                memberList = jsonMemberList.reduce( memberList ) {
                    $0 + htvtMemberParser.parseFamilyFrom(json: $1)
                }
                print( "Parsed \(memberList.count) members")
            } else {
                print( "no members" )
            }
            completionHandler( memberList, nil )
        }
    }
    
    func getOrgWithCallings( unitNum : Int64, _ completionHandler: @escaping ( Org?, Error? ) -> Void ) {
        // this method is only called at startup where we should always have a session, so not going to worry about checking it here. If we add a resync option that includes a new ward list then we may need to add session checking
        var url = appConfig.ldsEndpointUrls[NetworkConstants.callingsListURLKey]! + "?lang=eng"
        url = url.replacingOccurrences(of: ":unitNum", with: String(unitNum))
        doGet(url: url ) { data, response, error in
            guard error == nil else {
                print( "Error: attempting to read callings from lds.org " + error.debugDescription )
                completionHandler( nil, error )
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                let responseCode = httpResponse.statusCode
                if RestAPI.isErrorResponse( responseCode ) {
                    print( "response code: " + httpResponse.statusCode.description + " | response body: " + String(data: data!, encoding: .utf8)!)
                    let errorMsg = "Error: network error while trying to read callings from lds.org: \(responseCode)"
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
            
            // todo - where do we get the orgTypeId????
            var org : Org = Org(id: unitNum, unitNum: unitNum, orgTypeId: UnitLevelOrgType.Ward.rawValue, orgName: "", displayOrder: 1, children: [], callings: [])

            let childOrgsJson = responseData.jsonArrayValue
            org.children = childOrgsJson.flatMap() { Org( fromJSON: $0 ) }
            
            completionHandler( org, nil )
        }
    }
   
    func updateCalling( unitNum : Int64, calling : Calling, _ completionHandler: @escaping ( Calling?, Error? ) -> Void ) {
        /* update (change) a calling requires the following payload
         - payload: {
         "unitNumber": 56030,
         "subOrgTypeId": 1252,
         "subOrgId": 2081422,
         "positionTypeId": 216,
         "position": "any non-empty string"
         "memberId": 17767512672,
         "releaseDate": "20170801",
         "releasePositionIds": [
         38816970
         ]
         add is the same as update except you don't need releasePositionIds or releaseDate
         */
        guard let org = calling.parentOrg, let newMemberId = calling.proposedIndId else {
            // todo - need more message for case of no proposedIndId
            let orgDescription = calling.parentOrg?.orgTypeId.description ?? "no org type"
            let errorMsg = "Error: Invalid data - no owning org  org type=\(orgDescription)"
            print( errorMsg )
            completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        let todayAsLcrString = Date().lcrDateString()

        // we need to include the "position" field in the JSON payload. It doesn't appear to matter what the string is, it just has to be a non-empty string. We could just hard code it to "foo", but we'll at least try playing nice by using the position name (which should be just what we received from LCR in the first place), and then if it's nil for whatever reason we have a fall back value of "unused"
        let positionName = calling.position.name ?? LdsRestApi.defaultPositionText
        var payloadJsonObj : JSONObject = [ LcrCallingJsonKeys.unitNum : unitNum as AnyObject, LcrCallingJsonKeys.subOrgId : org.id as AnyObject, LcrCallingJsonKeys.orgTypeId : org.orgTypeId as AnyObject, LcrCallingJsonKeys.positionTypeId : calling.position.positionTypeId as AnyObject, LcrCallingJsonKeys.memberId : newMemberId as AnyObject, LcrCallingJsonKeys.activeDate : todayAsLcrString as AnyObject, LcrCallingJsonKeys.position: positionName as AnyObject ]
        
        if let callingId = calling.id {
            // there is someone already in the calling, so we need to release them
            payloadJsonObj[LcrCallingJsonKeys.releaseDate] = todayAsLcrString as AnyObject
            payloadJsonObj[LcrCallingJsonKeys.releasePositionIds] = [callingId] as AnyObject
        }
        
        // we have the payload all configured, now make the call to LCR
        if let json = jsonSerializer.serialize(jsonObject: payloadJsonObj ) {
            doPost( url: appConfig.ldsEndpointUrls[NetworkConstants.updateCallingURLKey]!, bodyPayload: json ) {
                (data, response, error) -> Void in
                
                print( "Response: \(response.debugDescription) Data: " + data.debugDescription + " Error: " + error.debugDescription )
                guard error == nil else {
                    print( "Error: " + error.debugDescription )
                    completionHandler(nil, error )
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, let data = data, let responseJson = data.jsonDictionaryValue else {
                    let errorMsg = "Error: No network error, but did not recieve data when updating calling. Payload= \(json)"
                    print( errorMsg )
                    completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.serviceError, userInfo: [ "error" : errorMsg ] ) )
                    return
                }
                    print( "response code: " + httpResponse.statusCode.description + " | response body: " + String(data: data, encoding: .utf8)!)

                if RestAPI.isSuccessResponse(httpResponse.statusCode), let newCallingId = responseJson[LcrCallingJsonKeys.positionId] as? NSNumber  {
                    // right now we're just checking for 200 OK. and that there is a positionId assigned. eventually we should also check that the memberId is what we passed up to ensure it happened.
                    
                    // extract the fields from the JSON that we care about
                    let existingIndIdFromJson = responseJson[LcrCallingJsonKeys.memberId] as? NSNumber
                    let newExistingIndId = existingIndIdFromJson?.int64Value ?? newMemberId
                    var activeDate = Date()
                    if let newActiveDateString = responseJson[LcrCallingJsonKeys.activeDate] as? String, let newActiveDate = Date(fromLCRString: newActiveDateString) {
                        activeDate = newActiveDate
                    }
                    // create the calling based on the returned json
                    let updatedCalling = Calling( id: newCallingId.int64Value, cwfId : nil, existingIndId : newExistingIndId, existingStatus: .Active, activeDate: activeDate, proposedIndId : nil, status: CallingStatus.None, position: calling.position, notes: nil, parentOrg : calling.parentOrg, cwfOnly: false )

                    completionHandler(updatedCalling, nil)
                } else {
                    // ok to ! data becuase we guard against it being nil above
                    let errorMsg = "Error: No 200 OK received on calling update. Response=\(httpResponse.debugDescription) Data=\(data.debugDescription). Request payload=\(payloadJsonObj.debugDescription)"
                    print( errorMsg )
                    completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.serviceError, userInfo: [ "error" : errorMsg ] ) )
                }
            }
        } else {
            let errorMsg = "Error: Unable to parse json object: \(payloadJsonObj.debugDescription)"
            print( errorMsg )
            completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [ "error" : errorMsg ] ) )
            return
        }
    }
    
    func releaseCalling( unitNum : Int64, calling : Calling, _ completionHandler: @escaping ( Bool, Error? ) -> Void ) {
        /* release from LCR requires the following payload:{
        "unitNumber": 56030,
        "subOrgTypeId": 1252,
        "subOrgId": 2081422,
         "position": "any non-empty string"
        "positionId": 38816967,
         "positionTypeId": 208,
        "releaseDate": "20170801"
    } */
        guard let org = calling.parentOrg, calling.id != nil else {
            let orgDescription = calling.parentOrg?.orgTypeId.description ?? "no org type"
            let errorMsg = "Error: Invalid data - no owning org or id for calling CallingId= \((calling.id?.description ?? "nil")) org type=\(orgDescription)"
            print( errorMsg )
            completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [ "error" : errorMsg ] ) )
            return
            
        }
        var payloadJsonObj = lcrJsonPayload( forCalling: calling, inOrg: org, unitNum: unitNum )
        // the positionTypeId cannot be added in the util method because it causes problems with release of a calling with a current holder, so we have to add it for the case of release (without it a release will actually delete the calling)
        payloadJsonObj[LcrCallingJsonKeys.positionTypeId] = calling.position.positionTypeId as AnyObject
        removeCalling(bodyPayload: payloadJsonObj, completionHandler)
        
    }
    
    func deleteCalling( unitNum : Int64, calling : Calling, _ completionHandler: @escaping ( Bool, Error? ) -> Void ) {
        /* delete from LCR requires the following payload if the calling has someone in it:
         {
         "unitNumber": 56030,
         "subOrgTypeId": 1252,
         "subOrgId": 2081422,
         "position": "any non-empty string"
         "positionId": 38816967,
         "releaseDate": "20170801",
         "hidden": true
         }

         and if it is empty:
         {
         "unitNumber": 56030,
         "subOrgTypeId": 1252,
         "subOrgId": 2081422,
         "positionTypeId" : 208,
         "position": "any non-empty string"
         "hidden" : true
         }

         */
        guard let org = calling.parentOrg else {
            let orgDescription = calling.parentOrg?.orgTypeId.description ?? "no org type"
            let errorMsg = "Error: Invalid data - no owning org or id for calling CallingId= \((calling.id?.description ?? "nil")) org type=\(orgDescription)"
            print( errorMsg )
            completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        var payloadJsonObj = lcrJsonPayload( forCalling: calling, inOrg: org, unitNum: unitNum )
        payloadJsonObj[LcrCallingJsonKeys.hide] = "true" as AnyObject
        removeCalling(bodyPayload: payloadJsonObj, completionHandler)
    }
    
    private func removeCalling( bodyPayload : JSONObject, _ completionHandler: @escaping ( Bool, Error? ) -> Void ) {
        // ok to use ! for endpointUrls. We start with default values, and the ones that come from
        // the network only will override the default if they exist. We don't just replace the entire
        // set of defaults with what came from the network, which could potentially be incomplete
        guard let json = jsonSerializer.serialize(jsonObject: bodyPayload ) else {
            let errorMsg = "Error: Unable to parse json object: \(bodyPayload.debugDescription)"
            print( errorMsg )
            completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        
        let url = appConfig.ldsEndpointUrls[NetworkConstants.updateCallingURLKey]!
        doPost( url: url, bodyPayload: json ) {
            (data, response, error) -> Void in
            
            print( "Response: \(response.debugDescription) Data: " + data.debugDescription + " Error: " + error.debugDescription )
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler(false, error )
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, data != nil else {
                let errorMsg = "Error: No network error, but did not recieve data when removing calling. Payload= \(bodyPayload.debugDescription)"
                print( errorMsg )
                completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.serviceError, userInfo: [ "error" : errorMsg ] ) )
                return
            }
            if let data = data {
                print( "response body: " + String(data: data, encoding: .utf8)!)
                
            }

            if RestAPI.isSuccessResponse(httpResponse.statusCode)  {
                // right now we're just checking for 200 OK. eventually we should check the response data for positionId is null to confirm that it worked
                completionHandler(true, nil)
            } else {
                // ok to ! data becuase we guard against it being nil above
                let errorMsg = "Error: No 200 OK received on calling update. Response=\(httpResponse.debugDescription) Data=\(data!.debugDescription). Request payload=\(bodyPayload.debugDescription)"
                print( errorMsg )
                completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.serviceError, userInfo: [ "error" : errorMsg ] ) )
            }
        }

    }
    
    func lcrJsonPayload( forCalling calling: Calling, inOrg org: Org, unitNum : Int64 ) -> JSONObject {
        // try to use the position name (should be what LCR sent down in the first place), use "unused" as a  fallback value
        let positionName = calling.position.name ?? LdsRestApi.defaultPositionText
        
        var jsonPayload = [ LcrCallingJsonKeys.unitNum : unitNum as AnyObject, LcrCallingJsonKeys.subOrgId : org.id as AnyObject, LcrCallingJsonKeys.orgTypeId : org.orgTypeId as AnyObject,  LcrCallingJsonKeys.position: positionName as AnyObject ]
        // if there's an existing calling then the release or delete needs the positionId & the release date
        if let posId = calling.id {
            jsonPayload[LcrCallingJsonKeys.positionId] = posId as AnyObject
            jsonPayload[LcrCallingJsonKeys.releaseDate] = Date().lcrDateString() as AnyObject
        } else {
            // this would basically be for deleting an empty calling - we need the positionTypeId. We have to split it out because in certain cases of release/delete having the positionTypeId in addition to the positionId causes problems (LCR throws an error if both are present for whatever reason)
            jsonPayload[LcrCallingJsonKeys.positionTypeId] = calling.position.positionTypeId as AnyObject
        }

        return jsonPayload
    }
}

private struct LcrCallingJsonKeys {
    static let subOrgId = "subOrgId"
    static let orgTypeId = "subOrgTypeId"
    static let position = "position"
    static let positionId = "positionId"
    static let positionTypeId = "positionTypeId"
    static let unitNum = "unitNumber"
    static let releaseDate = "releaseDate"
    static let activeDate = "activeDate"
    static let memberId = "memberId"
    static let releasePositionIds = "releasePositionIds"
    static let justCalled = "justCalled"
    static let hide = "hidden"
}
