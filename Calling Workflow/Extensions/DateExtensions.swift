//
//  DateExtensions.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 12/14/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import Foundation

extension Date {
    /** Formatter for reading/writing dates to JSON in the format that is used by LCR. This only deals with date, there is no time component */
    static let lcrFormatter : DateFormatter = {
        var lcrFormatter = DateFormatter()
        lcrFormatter.locale = Locale(identifier: "US_en")
        lcrFormatter.dateFormat = "yyyyMMdd"
        return lcrFormatter
    }()
    
    /** Formatter for storing/retrieving JSON data from cache */
    static let jsonFormatter : DateFormatter = {
        var jsonFormatter = DateFormatter()
        jsonFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return jsonFormatter
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
    
    init?( fromJSONString: String ) {
        guard !fromJSONString.isEmpty, let date = Date.jsonFormatter.date(from: fromJSONString) else {
            return nil
        }
        self = date
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
    
    func jsonDateString() -> String {
        return Date.jsonFormatter.string( from: self )
    }
    
}
