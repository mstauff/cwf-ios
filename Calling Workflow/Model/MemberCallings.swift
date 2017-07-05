//
//  MemberCallings.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 7/3/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

struct MemberCallings {
    
    let member : Member
    var callings : [Calling]
    var proposedCallings : [Calling]
    
    init( member : Member ) {
        self.member = member
        self.callings = []
        self.proposedCallings = []
    }
    
    init( member : Member, callings : [Calling], proposedCallings : [Calling] ) {
        self.member = member
        self.callings = callings
        self.proposedCallings = proposedCallings
    }
    
    
}
