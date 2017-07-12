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
    var callings : [Int:Bool]?
    var minMonthsInCalling : Int?
    var priesthood : [Priesthood: Bool]?
    var memberClass : [MemberClass: Bool]?
    
    var callingStatuses : [CallingStatus: Bool]?
    var callingOrg : [Int : Bool]?
    
    init () {
        minAge = nil
        maxAge = nil
        gender = nil
        callings = nil
        minMonthsInCalling = nil
        priesthood = nil
        memberClass = nil
        callingStatuses = nil
        callingOrg = nil
    }
    
    //MARK: - Filter Member
    func filterMemberData(unfilteredArray: [MemberCallings]) -> [MemberCallings] {
        var arrayToReturn = unfilteredArray
        
        arrayToReturn = filterForAge(unfilteredArray: arrayToReturn)
        arrayToReturn = filterForGender(unfilteredArray: arrayToReturn)
        arrayToReturn = filterForCallings(unfilteredArray: arrayToReturn)
        arrayToReturn = filterForTimeInCalling(unfilteredArray: arrayToReturn)
        arrayToReturn = filterForPriesthood(unfilteredArray: arrayToReturn)
        arrayToReturn = filterForClass(unfilteredArray: arrayToReturn)

        return arrayToReturn
    }
    
    private func filterForAge(unfilteredArray: [MemberCallings]) ->[MemberCallings] {
        var arrayToReturn = unfilteredArray
        // if there's not a min or max age then nothing for this filter to do
        guard self.minAge != nil || self.maxAge != nil else {
            return arrayToReturn
        }
        
        // get either the age's specified, or just set them to edge values so we can safely compare (don't have to check is minage & maxage set, or just one or the other)
        let minAge = self.minAge ?? 0
        let maxAge = self.maxAge ?? 1000
        arrayToReturn = arrayToReturn.filter() {
            
            if let age = $0.member.age  {
                // at this point the member has an age and the min & max are either set based on the UI, or the default edges, so just make sure we're within those ranges
                return age >= minAge && age <= maxAge
            }
            else {
                print("\(String(describing: $0.member.name))")
                // member didn't have an age, so they don't get included in the filter
                return false
            }
        }
        
        return arrayToReturn
    }
    
    private func filterForGender (unfilteredArray: [MemberCallings]) -> [MemberCallings] {
        var arrayToReturn = unfilteredArray
        if (gender != nil) {
            arrayToReturn = arrayToReturn.filter() { $0.member.gender == gender }
        }
        return arrayToReturn
    }
    
    private func filterForCallings (unfilteredArray: [MemberCallings]) -> [MemberCallings] {
        var arrayToReturn = unfilteredArray
        
        guard let numCallingSelectors = callings else {
            return arrayToReturn
        }
        
        // set of the number of callings the member should have to be included in the list
        var numCallingsSet = Set<Int>()
        // The last option in the filter list is 3+ (as of 7/17). includeMaxPlus & maxCallings allow us to include anyone that has 3 or more callings, and also keeps it flexible, if more options get added to the UI then this should all just work (as long as the elements are sequential and the last element in the list is <x>+, which they should always be)
        var includeMaxPlus = false
        var maxCallings = 0
        // loop through all the options and add them to the set if the user has selected them (val == true)
        for (callingSelector, val) in numCallingSelectors {
            if val {
                numCallingsSet.insert(callingSelector)
            }
        }
        // we're relying on the last element in the list being the indicator of how many + callings to include. If that ever changes this algorithm would just need to be modified to have the max value hard coded somewhere and draw from that.
        maxCallings = numCallingSelectors.count - 1
        includeMaxPlus = numCallingSelectors[maxCallings] ?? false
        
        arrayToReturn = arrayToReturn.filter() {
            numCallingsSet.contains( $0.callings.count ) || (includeMaxPlus && $0.callings.count > maxCallings)
        }
        
        return arrayToReturn
    }
    
    private func filterForTimeInCalling (unfilteredArray: [MemberCallings]) -> [MemberCallings] {
        var arrayToReturn = unfilteredArray
        
        // ensure that the "months in calling" filter has been set & it's greater than 0, otherwise we just return the original array
        guard let minMonths = minMonthsInCalling, minMonths > 0 else {
            return arrayToReturn
        }
        
        arrayToReturn = arrayToReturn.filter() {
            var greaterThanTime = false
            // look through all the user's callings, see if we find a single calling that has been active longer than the selected time
            for calling in $0.callings {
                if calling.existingMonthsInCalling > minMonths {
                    greaterThanTime = true
                    break
                }
            }
            return greaterThanTime
        }
        
        return arrayToReturn
    }
    
    private func filterForPriesthood (unfilteredArray: [MemberCallings]) -> [MemberCallings] {
        var arrayToReturn = unfilteredArray
        
        guard let priesthood = self.priesthood else {
            return arrayToReturn
        }
        
        arrayToReturn = arrayToReturn.filter() {
            guard let memberPriesthood = $0.member.priesthood  else {
                return false
            }
            
            return priesthood[memberPriesthood] ?? false
        }
        
        return arrayToReturn
    }
    
    private func filterForClass (unfilteredArray: [MemberCallings]) -> [MemberCallings] {
        var arrayToReturn = unfilteredArray
        
        guard let memberClass = self.memberClass else {
            return arrayToReturn
        }
        arrayToReturn = arrayToReturn.filter() {
            
            var includeInList = false
            // todo - this eventually needs to change to use actual class assignments from and LCR service call
            var currentMemberClass : MemberClass? = nil
            if $0.member.gender == Gender.Female, let age = $0.member.age {
                if age >= 18 {
                    currentMemberClass = .ReliefSociety
                }
                else if age < 18 && age >= 16 {
                    currentMemberClass = .Laurel
                }
                else if age < 16 && age >= 14 {
                    currentMemberClass = .MiaMaid
                }
                else if age < 14 && age >= 12 {
                    currentMemberClass = .Beehive
                }
                
                // if they fit into one of the age based groups, then lookup whether that age based group was selected in the UI
                if let memClass = currentMemberClass, let memberClassSelected = memberClass[memClass] {
                    includeInList = memberClassSelected
                }
            }
            return includeInList
        }
        
        return arrayToReturn
    }
    
    //MARK: - Filter Org
    func filterOrgData(unfilteredArray: [Calling]) -> [Calling] {
        var arrayToReturn = unfilteredArray
        if (callingOrg != nil) {
            arrayToReturn = arrayToReturn.filter() {
                if ($0.parentOrg != nil && (callingOrg?[Int(($0.parentOrg?.id)!)])! == true) {
                    return true
                }
                else {
                    return false
                }
            }
        }
        return arrayToReturn
    }
    
    private func filterForCallingStatus() {
        
    }
    
    private func filterForCallingOrg() {
        
    }
}
