//
//  Org.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

/**
 An Org represents a CDOL org or sub org. In most cases a unit level org (i.e. EQ, RS, Primary, etc.) does not have callings associated directly with it. The callings will be in a sub org. So Primary Teachers are assigned to a specific class, that is an Org in the children of Primary. The Bishopric is the only exception we've found to this rule, there are no children for the bishopric org, it just has callings.
 */
public struct Org : JSONParsable  {
    
    /**
     The unique ID for this org - the equivalent of CDOL subOrgId. It has to be Int64 to ensure that it can hold a Java long value
     */
    let id : Int64
    
    /**
     The CDOL orgTypeId. We debated between making this an enum, or leaving it just the int. We went with int because although we do make use of the org type as an enum for the root level orgs within a unit (RS, EQ, Primary, etc.) we don't want to have to create an enum for all the sub orgs within those (EQ Pres., CTR 7, etc.). Since an Org represents both types of structures we decided to just use the int, and then in the cases where it's appropriate and necessary we can retrieve the corresponding UnitLevelOrgType for a given orgTypeId
     */
    let orgTypeId : Int
    
    /**
     The name of the org, which will be the customOrgName if it is set, or the defaultOrgName if there is not a custom name
     */
    let orgName : String
    
    /**
     This comes from LCR, just allows us to display the orgs in a consistent order
     */
    let displayOrder : Int
    
    /** Any child sub orgs. If this is a unit level org (like Primary) then it the callings array will be empty and the children array will be populated with all the classes, the presidency, the music, etc. If this is a sub org like a primary class then the children will be empty, and callings will be populated. The only top level org that we have observed that has callings directly, and no children, is the Bishopric org
     */
    let children : [Org]
    
    var callings : [Calling]
    // Do we need these? Probably not for the app, but maybe we will to be able to send necessary data to LCR for calling updates
    //    var parentOrg : Org
    
    public init?(_ json: JSONObject) {
        guard
            // currently orgType is inlined with the org object, rather than a separate JSON piece
            let orgTypeId = json[ OrgJsonKeys.orgTypeId ] as? Int,
            let id = json[ OrgJsonKeys.id ] as? NSNumber,
            let displayOrder = json[OrgJsonKeys.displayOrder] as? Int
            else {
                return nil
        }
        let children = json[OrgJsonKeys.children] as? [JSONObject] ?? []
        let callings = json[OrgJsonKeys.callings] as? [JSONObject] ?? []
        var orgName = json[OrgJsonKeys.customOrgName] as? String ?? json[OrgJsonKeys.orgName] as? String
        orgName = orgName ?? ""
        let childOrgs : [Org] = children.map() { childOrgJSON -> Org? in
            return Org( childOrgJSON )
            }.filter() { $0 != nil } as! [Org]
        
        // This initializer is a bit unorthodox where it creates an org, then sets self to it, but we need to do that because the child callings need a reference to the containing org. Although we probably could make it work by making Calling.parentOrg optional, and then filling it in after everything else is initialized, this works, so we'll stick with this method unless it causes us some other issues
        var org = Org( id: id.int64Value, orgTypeId: orgTypeId, orgName: orgName!, displayOrder: displayOrder, children: childOrgs, callings: [] )
        let parsedCallings : [Calling] = callings.map() { callingJson -> Calling? in
            var calling = Calling( callingJson )
            calling?.parentOrg = org
            return calling
            }.filter() { $0 != nil } as! [Calling]
        
        org.callings = parsedCallings
        self = org
    }
    
    public init( id: Int64, orgTypeId: Int, orgName : String, displayOrder : Int, children : [Org], callings : [Calling] ) {
        self.id = id
        self.orgTypeId = orgTypeId
        self.orgName = orgName
        self.displayOrder = displayOrder
        self.children = children
        self.callings = callings
    }
    
    public func toJSONObject() -> JSONObject {
        var jsonObj = JSONObject()
        jsonObj[OrgJsonKeys.id] = self.id as AnyObject
        jsonObj[OrgJsonKeys.orgTypeId] = self.orgTypeId as AnyObject
        jsonObj[OrgJsonKeys.orgName] = self.orgName as AnyObject
        let callingsJson : [JSONObject] = callings.map() { calling -> JSONObject in
            return calling.toJSONObject()
        }
        jsonObj[OrgJsonKeys.callings] = callingsJson as AnyObject
        
        let subOrgsJson : [JSONObject] = children.map() { childOrg -> JSONObject in
            return childOrg.toJSONObject()
        }
        jsonObj[OrgJsonKeys.children] = subOrgsJson as AnyObject
        
        return jsonObj;
    }
    
}

private struct OrgJsonKeys {
    static let id = "subOrgId"
    static let orgTypeId = "orgTypeId"
    static let displayOrder = "displayOrder"
    static let children = "children"
    static let callings = "callings"
    static let orgName = "defaultOrgName"
    static let customOrgName = "customOrgName"
}
