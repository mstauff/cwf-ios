//
//  UnitSettings.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/28/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

struct UnitSettings : JSONParsable {
    
    var unitNum : Int64?
    
    let disabledStatuses : [CallingStatus]
    
    init() {
        disabledStatuses = []
    }
    
    init( unitNum : Int64?, disabledStatuses : [CallingStatus]) {
        self.unitNum = unitNum
        self.disabledStatuses = disabledStatuses
    }
    
    init?( fromJSON json: JSONObject) {
        let statusStrings = json[UnitSettingsJsonKeys.disabledStatuses] as? [String] ?? []
        disabledStatuses = statusStrings.flatMap() { CallingStatus(rawValue: $0) }
    }
    
    func toJSONObject() -> JSONObject {
        var jsonObj = JSONObject()
        let statusJson : [String] = disabledStatuses.map() {
            $0.rawValue
        }
        jsonObj[UnitSettingsJsonKeys.disabledStatuses] = statusJson as AnyObject
        return jsonObj
    }

    
}

private struct UnitSettingsJsonKeys {
    static let disabledStatuses = "disabledStatuses"
}

