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
 */
extension Dictionary {
    func merged(withDictionary dict: Dictionary<Key, Value>) -> Dictionary<Key, Value> {
        var mutableCopy = self
        for (key, value) in dict {
            // If both dictionaries have a value for same key, the value of the other dictionary is used.
            mutableCopy[key] = value
        }
        return mutableCopy
    }
    
    func filteredDictionary( _ isIncluded: (Key, Value ) -> Bool ) -> [Key:Value] {
        return self.filter(isIncluded).toDictionary( {$0} )
    }
    
    /** Convert a Dictionary from one type to another type (the default .map() converts a dictionary to an array)*/
    func mapDictionary<K:Hashable, V>( _ transformer: ( _ : Element) -> (key: K, value : V)?) -> Dictionary<K, V> {
        var map = [K: V]()
        for element in self {
            if let (key, value) = transformer(element) {
                map[key] = value
            }
        }
        return map
    }
}

/** Extension of Dictionaries that are JSON Objects to convert from the generic JSON object to a specific type of Dictionary */
extension Dictionary where Key: ExpressibleByStringLiteral, Value: AnyObject {
    func mapToDictionary<K:Hashable, V>( _ transformer: ( _ : Element ) -> (key: K, value: V)?) -> Dictionary<K,V> {
        return mapDictionary(transformer)
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
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> T? {
        return indices.contains(index) ? self[index] : nil
    }
    
    func toDictionary<K:Hashable, V>( _ transformer: (_: Element) -> (key: K, value: V)?)
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
    func toDictionaryById<K>( _ transformer: (_: T) -> K?)
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

extension Array where Element : Equatable {
    typealias E = Element

    /** Convenience version of contains method that takes an actual object search for rather than requiring a predicate closure */
    func contains( item: E ) -> Bool {
        return self.contains() { $0 == item }
    }
    
    /** Array version of Set.subtracted */
    func without( subtractedItems: [E] ) -> [E] {
        return self.filter() { !subtractedItems.contains( item: $0 ) }
    }
}
