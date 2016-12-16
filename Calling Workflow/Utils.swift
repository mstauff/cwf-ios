//
//  Utils.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 12/14/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import Foundation

public class Utils {
    
    /**
     Utility method to validate a string and treat nil & "" both as nil. If the string has any text then it is returned unchanged. If it is "" then we return nil. This was primarily created to deal with JSON parsing where sometimes a property would be null and sometimes it would be "". If it was "" then any code like if let foo = json["foo"] ... would either execute with an empty string or we might have to constantly check for both nil or "". This method was added to simplify the checks by just returning nil if the string was empty, so when we go to use it we just have to check for nil and not worry about ""
     */
    static func nilIfEmpty(_ prop : String? ) -> String? {
        return prop == nil || prop!.isEmpty ? nil : prop
    }
}
