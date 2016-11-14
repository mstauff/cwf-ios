//
//  Member.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/4/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import Foundation

class Member {
    
    var individualId : Int64
    var formattedName : String?
    var individualPhone : String?
    var householdPhone : String?
    var email : String?
    var currentCalling: String?
    
    init() {
        individualId = 0
        formattedName = nil
        individualPhone = nil
        householdPhone = nil
        email = nil
        currentCalling = nil
    }
    
    init (indId: Int64, name:String?, indPhone: String?, housePhone:String?, email:String?, currentCall:String? ) {
        individualId = indId
        formattedName = name
        individualPhone = indPhone
        householdPhone = housePhone
        currentCalling = currentCall
    }
    
    
}
