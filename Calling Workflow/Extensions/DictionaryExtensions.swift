//
//  DictionaryExtensions.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 12/7/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import Foundation

/**
 Dictionary extension to merge elements from one dictionary into another
 This could go somewhere else, but currently it's only used by json parsing, so it lives here
 */
extension Dictionary {
    func merge(withDictionary dict: Dictionary<Key,Value>) -> Dictionary<Key,Value> {
        var mutableCopy = self
        for (key, value) in dict {
            // If both dictionaries have a value for same key, the value of the other dictionary is used.
            mutableCopy[key] = value
        }
        return mutableCopy
    }
}
