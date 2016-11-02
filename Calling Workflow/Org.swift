//
//  Org.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

struct Org : JSONParsable  {
    
    var orgType : OrgType
    var orgName : String
    var positions : [Position]
    var subOrgs : [Org]
    // Do we need these? Probably not for the app, but maybe we will to be able to send necessary data to LCR for calling updates
    //    var parentOrg : Org
    //    var childOrgs : [Org]
    
    init( orgType: OrgType, orgName: String ) {
        self.init( orgType: orgType, orgName: orgName, positions: [] )
    }
    
    init( orgType: OrgType, orgName: String, positions: [Position] ) {
        self.orgType = orgType
        self.orgName = orgName
        self.positions = positions
        self.subOrgs = []
    }
    
//    func toJSON() -> String {
//        return String( JSONSerialization.data(withJSONObject: self ), encoding: UTF8() )
//    }
    
    
    static func parseFrom(_ json: JSONObject) -> Org? {
        guard
            let orgType = OrgType.parseFrom(json["orgType"] as! JSONObject),
            let orgName = json["orgName"] as? String,
            let positions = json["positions"] as? [JSONObject]
            else {
                return nil
        }
        var org = Org( orgType: orgType, orgName: orgName )
        let parsedPositions : [Position] = positions.map() { positionJson -> Position? in
            var position = Position.parseFrom( positionJson )
            position?.org = org
            return position
        }.filter() { $0 != nil } as! [Position]
        
        org.positions = parsedPositions
        return org
    }
    
}
