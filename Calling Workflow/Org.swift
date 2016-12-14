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
    let orgTypeId : Int
    let orgName : String
    let displayOrder : Int
    var children : [Org]
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
            let orgTypeId = json["orgTypeId"] as? Int,
            let id = json["subOrgId"] as? NSNumber,
            let displayOrder = json["displayOrder"] as? Int
            else {
                return nil
        }
        let children = json["children"] as? [JSONObject] ?? []
        let callings = json["callings"] as? [JSONObject] ?? []
        var orgName = json["customOrgName"] as? String ?? json["defaultOrgName"] as? String
        orgName = orgName ?? ""
        let childOrgs : [Org] = children.map() { childOrgJSON -> Org? in
            Org.parseFrom( childOrgJSON )
            }.filter() { $0 != nil } as! [Org]
        
        var org = Org( id: id.int64Value, orgTypeId: orgTypeId, orgName: orgName!, displayOrder: displayOrder, children: childOrgs, callings: [] )
        let parsedCallings : [Calling] = callings.map() { callingJson -> Calling? in
            var calling = Calling.parseFrom( callingJson )
            calling?.parentOrg = org
            return calling
        }.filter() { $0 != nil } as! [Calling]
        
        org.callings = parsedCallings
        return org
    }
    
}
