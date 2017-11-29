//
//  MemberExtensions.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 6/2/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

extension Member {
    func getAddressAsString () -> String? {
        if self.streetAddress.count == 0 {
            return nil
        }
        else {
            let stringToReturn = self.streetAddress.joined(separator: ", ")
            return stringToReturn != "" ?  stringToReturn : nil
        }
    }
    
    static func nameSorter( mem1 : Member, mem2 : Member ) -> Bool {
        if let name1 = mem1.name, let name2 = mem2.name {
            return name1 <= name2
        } else {
            // if the first name is not nil then they're in the correct order, or if they're both nil then they're in the correct order
            return mem1.name != nil || mem1.name == mem2.name
        }
    }
}


