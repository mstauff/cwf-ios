//
//  MemberExtensions.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 6/2/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

extension Member {
    func getAddressForMemberAsString () -> String? {
        if self.streetAddress.count == 0 {
            return nil
        }
        else {
            var stringToReturn = ""
            for currentString in self.streetAddress {
                stringToReturn += "\(currentString), "
            }
            if stringToReturn != "" {
                return stringToReturn
            }
            else {
                return nil
            }
        }
    }

}
