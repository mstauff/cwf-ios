//
//  CWFDataSource.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/5/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

class CWFCallingManagerService {
    
    var rootOrg:Org?
    var memberArray:Array<Member>?
    
    init() {
        rootOrg = nil
        memberArray = nil
    }
    
    init(org: Org?, iMemberArray: Array<Member>?) {
        rootOrg = org
        memberArray = iMemberArray
    }
    
    // Adding orgs to the org array
    func setRootOrg(org : Org) {
        rootOrg = org
    }
    
    
    func addMemberToMemberArray(member : Member) {
        if (memberArray != nil){
            memberArray?.append(member)
        }
        else {
            memberArray = Array()
            memberArray?.append(member)
        }
    }

    
}
