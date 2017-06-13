//
//  MultiValueDictionary.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 2/14/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

/* A dictionary that can store multiple values (as an array) for any given key */

public struct MultiValueDictionary<K:Hashable, V> {

    var dictionary: [K: [V]]

    init() {
        self.dictionary = [:]
    }

    init(dictionary: [K: V]) {
        self.dictionary = Dictionary(minimumCapacity: dictionary.count)

        for (k, v) in dictionary {
            self.dictionary[k] = [v]
        }

    }

}

extension MultiValueDictionary {
   
    /* Adds a single value to the dictionary for a given key. If the key already has existing values this will be added to the end of the list. If this is the first element for the key a new array is created with the given value */
    mutating func addValue( forKey key: K, value: V ){
        if self.dictionary[key] == nil {
            var keyValues : [V] = []
            keyValues.append(value)
            self.dictionary[key] = keyValues
        } else {
            self.dictionary[key]!.append( value )
        }
    }
    
    /* Replaces all the values for a given key with the values passed in. The previous values are returned by the method, or an empty array if there weren't any values */
    mutating func setValues( forKey key: K, values: [V] ) -> [V] {
        let previousValues = self.dictionary[key] ?? []
        self.dictionary[key] = values
        return previousValues
    }
    
    mutating func removeValues( forKey key : K ) {
        self.dictionary.removeValue(forKey: key)
    }
    
    mutating func removeAllValues(  ) {
        self.dictionary.removeAll()
    }

    func getValues( forKey key: K ) -> [V] {
        return self.dictionary[key] ?? []
    }

    /* Convenience method to get a single value for a given key. It returns just the first value from the list if the key is in the dictionary, nil otherwise */
    func getSingleValue( forKey key: K ) -> V? {
        var result : V? = nil
        if let values = self.dictionary[key], values.isNotEmpty {
            result = values[0]
        }
        return result
    }

    func contains( key: K ) -> Bool {
        return self.dictionary[key] != nil && self.dictionary[key]!.isNotEmpty
    }
}

extension MultiValueDictionary where V : Equatable {
    mutating func removeValue( forKey key : K, value : V ) {
        if let valsForKey = self.dictionary[key] {
            self.setValues(forKey: key, values: valsForKey.filter({ $0 != value }) )
        }
    }
    
    
}


