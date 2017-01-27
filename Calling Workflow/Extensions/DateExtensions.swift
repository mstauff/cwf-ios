//
//  DateExtensions.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 12/14/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import Foundation

extension Date {
    static let lcrFormatter : DateFormatter = {
        var lcrFormatter = DateFormatter()
        lcrFormatter.locale = Locale(identifier: "US_en")
        lcrFormatter.dateFormat = "yyyyMMdd"
        return lcrFormatter
    }()

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

    init?( fromLCRString: String ) {
        // dateFormatter will return nil if the string doesn't match the expected format, except if it's "" then it will return a Date set to a default date, so we need to guard against that case and return nil rather than passing it to the formatter
        guard !fromLCRString.isEmpty, let date = Date.lcrFormatter.date(from: fromLCRString) else {
            return nil
        }
        self = date
    }

    func lcrDateString() -> String {
        return Date.lcrFormatter.string( from: self )
    }
    
}
