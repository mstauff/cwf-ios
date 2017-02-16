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
    func merge(withDictionary dict: Dictionary<Key, Value>) -> Dictionary<Key, Value> {
        var mutableCopy = self
        for (key, value) in dict {
            // If both dictionaries have a value for same key, the value of the other dictionary is used.
            mutableCopy[key] = value
        }
        return mutableCopy
    }
}

extension Array {

    typealias T = Element

/* convenience method since we usually are doing something if an array is not empty */
    var isNotEmpty: Bool {
        get {
            return !self.isEmpty
        }
    }

    func toDictionary<K, V>(transformer: (_: T) -> (key: K, value: V)?)
                    -> Dictionary<K, V> {
        var map = [K: V]()
        for element in self {
            if let (key, value) = transformer(element) {
                map[key] = value
            }
        }
        return map

    }

    /* Create a dictionary from an array given a transforming function that returns the data element to be used as the key. The object from the array will be used as the value. If there is no key for a given object then the object will not be included in the dictionary */
    func toDictionaryById<K>(transformer: (_: T) -> K?)
                    -> Dictionary<K, T> {
        var map = [K: T]()
        for element in self {
            if let key = transformer(element) {
                map[key] = element
            }
        }
        return map
    }
}
