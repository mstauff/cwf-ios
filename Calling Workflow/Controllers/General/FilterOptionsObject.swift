//
//  FilterOptionsObject.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/22/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterOptionsObject {
    var minAge : Int?
    var maxAge : Int?
    var gender : Gender?
    var maxCallings : Int?
    var minMonthsInCalling : Int?
    var priesthood : [Priesthood: Bool]?
    var memberClass : [MemberClass: Bool]?
    
    init () {
        minAge = nil
        maxAge = nil
        gender = nil
        maxCallings = nil
        minMonthsInCalling = nil
        priesthood = nil
        memberClass = nil
    }
    
    func filterMemberData(unfilteredArray: [Member]) -> [Member] {
        var arrayToReturn = unfilteredArray
        
        arrayToReturn = filterForAge(unfilteredArray: arrayToReturn)
        arrayToReturn = filterForGender(unfilteredArray: arrayToReturn)
        arrayToReturn = filterForCallings(unfilteredArray: arrayToReturn)
        arrayToReturn = filterForTimeInCalling(unfilteredArray: arrayToReturn)
        arrayToReturn = filterForPriesthool(unfilteredArray: arrayToReturn)
        arrayToReturn = filterForClass(unfilteredArray: arrayToReturn)

        return arrayToReturn
    }
    
    private func filterForAge(unfilteredArray: [Member]) ->[Member] {
        var arrayToReturn = unfilteredArray
        if (minAge != nil) {
            arrayToReturn = arrayToReturn.filter() { $0.age! < minAge!}
        }
        if (maxAge != nil) {
            arrayToReturn = arrayToReturn.filter() { $0.age! > maxAge!}
        }
        
        return arrayToReturn
    }
    
    private func filterForGender (unfilteredArray: [Member]) -> [Member] {
        var arrayToReturn = unfilteredArray
        if (gender != nil) {
            if gender == Gender.Male {
                arrayToReturn = arrayToReturn.filter() { $0.gender == Gender.Male }
            }
            else {
                arrayToReturn = arrayToReturn.filter() { $0.gender == Gender.Female }
            }
        }
        return arrayToReturn
    }
    
    private func filterForCallings (unfilteredArray: [Member]) -> [Member] {
        var arrayToReturn = unfilteredArray
        
        if (maxCallings != nil) {
            arrayToReturn = arrayToReturn.filter() { $0.currentCallings.count <= maxCallings! }
        }
        
        return arrayToReturn
    }
    
    private func filterForTimeInCalling (unfilteredArray: [Member]) -> [Member] {
        var arrayToReturn = unfilteredArray
        
        if (minMonthsInCalling != nil) {
            arrayToReturn = arrayToReturn.filter() {
                var greaterThanTime = true
                for calling in $0.currentCallings {
                    if calling.existingMonthsInCalling < minMonthsInCalling! {
                        greaterThanTime = false
                    }
                }
                return greaterThanTime
            }
        }
        
        return arrayToReturn
    }
    
    private func filterForPriesthool (unfilteredArray: [Member]) -> [Member] {
        var arrayToReturn = unfilteredArray
        
        if (priesthood != nil) {
            arrayToReturn = arrayToReturn.filter() {
                if ($0.priesthood == nil) {
                    return false
                }
                
                if (priesthood?[$0.priesthood!])! || priesthood?[$0.priesthood!]! == false {
                    return false
                }
                else {
                    return true
                }
            }
        }
        
        return arrayToReturn
    }
    
    private func filterForClass (unfilteredArray: [Member]) -> [Member] {
        var arrayToReturn = unfilteredArray
        
        if memberClass != nil {
            arrayToReturn = arrayToReturn.filter() {
                
                var currentMemberClass : MemberClass? = nil
                if ($0.gender == Gender.Female && $0.age != nil) {
                    if $0.age! >= 18 {
                        currentMemberClass = MemberClass.ReliefSociety
                    }
                    else if ($0.age! < 18 && $0.age! >= 16) {
                        currentMemberClass = MemberClass.Laurel
                    }
                    else if ($0.age! < 16 && $0.age! >= 14) {
                        currentMemberClass = MemberClass.MiaMaid
                    }
                    else if ($0.age! < 14 && $0.age! >= 12) {
                        currentMemberClass = MemberClass.Beehive
                    }

                    if currentMemberClass != nil {
                        if let _ = memberClass?[currentMemberClass!]! {
                            return memberClass![currentMemberClass!]!
                        }
                    }
                    else {
                        return false
                    }
                }
                else{
                    return false
                }
                return false
            }
        }
        
        return arrayToReturn
    }
}
