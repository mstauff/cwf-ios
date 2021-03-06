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
    private var orgMembersJSON : [JSONObject] = []
    private var currentUserJSON = JSONObject()
    private let jsonFileReader = JSONFileReader()
    
    init( appConfig : AppConfig ) {
        self.appConfig = appConfig
    }
    func setAppConfig( appConfig : AppConfig ) {
        self.appConfig = appConfig
    }
    
    /* Simulate signin */
    func ldsSignin(forUser: String, withPassword: String,_ completionHandler: @escaping ( _ error:NSError? ) -> Void) {
        
        memberJSON = jsonFileReader.getJSON( fromFile: "member-objects" )
        orgJSON = jsonFileReader.getJSONArray( fromFile: "org-callings" )
        orgMembersJSON = jsonFileReader.getJSONArray(fromFile: "org-members")
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
    
    func getOrgWithCallings( subOrgId : Int64, _ completionHandler: @escaping ( Org?, Error? ) -> Void ) {
        let authenticated = signedIn
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            if authenticated {
                var unitOrg = Org( id: subOrgId, unitNum: subOrgId, orgTypeId: UnitLevelOrgType.Ward.rawValue )
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
    func releaseCalling( unitNum : Int64, calling : Calling, _ completionHandler: @escaping ( Bool, Error? ) -> Void ) {
        // todo - need to implement this - just find the calling in org-callings json and remove the active ID
        let authenticated = signedIn
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            if authenticated {
                
                completionHandler( true, nil )
            } else {
                let errorMsg = "Error: Not signed in"
                completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.networkError, userInfo: [ "error" : errorMsg ] ) )
            }
        }

    }
    func deleteCalling( unitNum : Int64, calling : Calling, _ completionHandler: @escaping ( Bool, Error? ) -> Void ){
        let authenticated = signedIn
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            if authenticated {
                
                completionHandler( true, nil )
            } else {
                let errorMsg = "Error: Not signed in"
                completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.networkError, userInfo: [ "error" : errorMsg ] ) )
            }
        }

    }

    func updateCalling( unitNum : Int64, calling : Calling, _ completionHandler: @escaping ( Calling?, Error? ) -> Void ){
        // todo - need to implement this - just find the calling in org-callings json and update it
        let authenticated = signedIn
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            if authenticated {
                
                completionHandler( calling, nil )
            } else {
                let errorMsg = "Error: Not signed in"
                completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.networkError, userInfo: [ "error" : errorMsg ] ) )
            }
        }
}

    func getOrgMembers( ofSubOrgId subOrgId : Int64, _ completionHandler: @escaping([Int64:Int64], Error?) -> Void ) {
        let authenticated = signedIn
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            let orgParser = LCROrgParser()
            if authenticated {
                var orgAssignmentByIndId : [Int64:Int64] = [:]
                for currOrgJson in self.orgMembersJSON {
                    if currOrgJson[ "subOrgId" ] as? Int == Int( subOrgId ) {
                        orgAssignmentByIndId = orgParser.memberOrgAssignments(fromJSON: currOrgJson)
                        break
                    }
                }
                completionHandler(orgAssignmentByIndId, nil)
            } else {
                let errorMsg = "Error: Not signed in"
                completionHandler( [:], NSError( domain: ErrorConstants.domain, code: ErrorConstants.networkError, userInfo: [ "error" : errorMsg ] ) )
            }
        }
    }


    func ldsSignout(_ completionHandler: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            completionHandler()
        }
    }
}
