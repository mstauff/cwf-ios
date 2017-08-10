//
//  LdsFileApi.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 1/13/17.
//  Copyright © 2017 colsen. All rights reserved.
//
import Foundation

/* Impl of LdsOrgApi using local test files to simulate data for LDS.org. This is just for ease of development purposes */
class LdsFileApi : LdsOrgApi {
    
    var appConfig : AppConfig
    
    private var signedIn = false
    private var memberJSON = JSONObject()
    private var orgJSON : [JSONObject] = []
    private var currentUserJSON = JSONObject()
    private let jsonFileReader = JSONFileReader()
    
    init( appConfig : AppConfig ) {
        self.appConfig = appConfig
    }
    func setAppConfig( appConfig : AppConfig ) {
        self.appConfig = appConfig
    }
    
    /* Simulate signin */
    func ldsSignin(username: String, password: String,_ completionHandler: @escaping ( _ error:NSError? ) -> Void) {
        
        memberJSON = jsonFileReader.getJSON( fromFile: "member-objects" )
        orgJSON = jsonFileReader.getJSONArray( fromFile: "org-callings" )
        currentUserJSON = jsonFileReader.getJSON( fromFile: "current-user" )
            signedIn = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            completionHandler(nil)
        }
        
    }
    
    /*
     Gets the current user. This method is so we can get the callings that the current user has to grant permissions.
     */
    func getCurrentUser( _ completionHandler: @escaping ( LdsUser?, Error? ) -> Void ) {
        let authenticated = signedIn
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            if authenticated {
                //todo: need current user JSON file data
                completionHandler( LdsUser( fromJSON: self.currentUserJSON), nil )
            } else {
                let errorMsg = "Error: Not signed in"
                completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.networkError, userInfo: [ "error" : errorMsg ] ) )
            }
        }
    }
    
    /* Returns a list of members (via callback) for the given unit. This will include all members age 11+. Family structure is not preserved. */
    func getMemberList( unitNum : Int64, _ completionHandler: @escaping ( [Member]?, Error? ) -> Void ) {
        let authenticated = signedIn
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            if authenticated {
                var memberList : [Member] = []
                let jsonMemberList = self.memberJSON["families"] as? [JSONObject]
                if jsonMemberList != nil {
                    let htvtMemberParser = HTVTMemberParser()
                    for jsonFamily in jsonMemberList! {
                        let members = htvtMemberParser.parseFamilyFrom(json: jsonFamily)
                        memberList.append( contentsOf: members )
                    }
                    
                }
                
                completionHandler( memberList, nil )
            } else {
                let errorMsg = "Error: Not signed in"
                completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.networkError, userInfo: [ "error" : errorMsg ] ) )
            }
        }
    }
    
    func getOrgWithCallings( unitNum : Int64, _ completionHandler: @escaping ( Org?, Error? ) -> Void ) {
        let authenticated = signedIn
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            if authenticated {
                var unitOrg = Org( id: unitNum, unitNum: unitNum, orgTypeId: UnitLevelOrgType.Ward.rawValue )
                    for jsonOrg in self.orgJSON {
                        if let childOrg = Org(fromJSON: jsonOrg) {
                            unitOrg.children.append( childOrg )
                        }
                    }
                
                completionHandler( unitOrg, nil )
            } else {
                let errorMsg = "Error: Not signed in"
                completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.networkError, userInfo: [ "error" : errorMsg ] ) )
            }
        }
    }
    
}
