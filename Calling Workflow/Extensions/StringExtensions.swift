//
//  StringExtensions.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 2/20/18.
//  Copyright © 2018 colsen. All rights reserved.
//

import Foundation

extension String {
    var boolValue: Bool {
        return NSString(string: self).boolValue
    }
}

