//
//  Org.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

public struct Org : JSONParsable  {

    let id : Int64
    let orgType : OrgType
    let orgName : String
    let displayOrder : Int
    let children : [Org]

    var callings : [Calling]
    // Do we need these? Probably not for the app, but maybe we will to be able to send necessary data to LCR for calling updates
    //    var parentOrg : Org
    
    public func toJSON() -> String? {
        var jsonString : String? = nil
        do {
            jsonString = String( data: try JSONSerialization.data(withJSONObject: self ), encoding: .utf8 )
        } catch {
            // do nothing - leave nil
        }
        return jsonString
    }
    
    
    public static func parseFrom(_ json: JSONObject) -> Org? {
        guard
            // currently orgType is inlined with the org object, rather than a separate JSON piece
            let orgType = OrgType.parseFrom( json ),
            let id = json["subOrgId"] as? Int64,
            let displayOrder = json["displayOrder"] as? Int
            else {
                return nil
        }
        let children = json["children"] as? [JSONObject] ?? []
        let callings = json["callings"] as? [JSONObject] ?? []
        var orgName = json["customOrgName"] as? String ?? json["defaultOrgName"] as? String
        orgName = orgName ?? ""
        let childOrgs : [Org] = [] // todo - need to parse children from JSON
//        orgName = orgName?.isEmpty ?  json["orgName"] as? String
        var org = Org( id: id, orgType: orgType, orgName: orgName!, displayOrder: displayOrder, children: childOrgs, callings: [] )
        let parsedCallings : [Calling] = callings.map() { callingJson -> Calling? in
            var calling = Calling.parseFrom( callingJson )
            calling?.parentOrg = org
            return calling
        }.filter() { $0 != nil } as! [Calling]
        
        org.callings = parsedCallings
        return org
    }
    
}
