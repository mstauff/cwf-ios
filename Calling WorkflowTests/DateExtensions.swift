//
//  DateExtensions.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 12/14/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import Foundation

/*
 This might be helpful in application code at some point if we need to create dates from year/month/day, but for now it's only used in the test code, so we'll keep it here and move it back to app code if and when we need it there
 */
extension Date {
    
    init(year: Int,
         month: Int,
         day: Int,
         hour: Int = 0,
         minute: Int = 0,
         second: Int = 0,
         timeZone: TimeZone? = nil) {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        components.timeZone = timeZone
        self = Calendar.current.date(from: components)!
    }
    
}
