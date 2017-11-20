//
//  SessionManager.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 11/13/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

struct SessionManager {
    
    static let secondsPerMinute = 60
    
    /* The number of minutes a session will remain active (for LDS.org this is generally 60 minutes)*/
    let sessionTimeoutMinutes : Int
    
    /* The actual time the session will expire. This will generally be the last time the session was used + sessionTimeoutMinutes */
    var sessionTimeout : Date
    
    init( sessionTimeoutMinutes timeout: Int ) {
        self.sessionTimeoutMinutes = timeout
        self.sessionTimeout = Date()
    }
    
    public func isSessionValid() -> Bool {
        return sessionTimeout > Date()
    }
    
    public mutating func updateSession() {
        self.sessionTimeout = Date(timeIntervalSinceNow: Double( self.sessionTimeoutMinutes * SessionManager.secondsPerMinute ))
    }
}

