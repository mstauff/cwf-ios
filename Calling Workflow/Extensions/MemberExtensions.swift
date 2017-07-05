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

}
