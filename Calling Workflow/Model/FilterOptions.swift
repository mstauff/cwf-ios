//
//  FilterOptions.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/22/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

struct FilterOptions {
    var minAge : Int?
    var maxAge : Int?
    var gender : Gender?
    var callings : [Int:Bool]?
    var minMonthsInCalling : Int?
    var priesthood : [Priesthood]
    var memberClass : [MemberClass]
    
    var callingStatuses : [CallingStatus]
    var callingOrg : [Int : Bool]?
    
    init () {
        minAge = nil
        maxAge = nil
        gender = nil
        callings = nil
        minMonthsInCalling = nil
        priesthood = []
        memberClass = []
        callingStatuses = []
        callingOrg = nil
    }
    
    init( fromPositionRequirements positionRequirements: PositionRequirements ) {
        self.minAge = positionRequirements.adult ? FilterConstants.adultMinAge : nil
        self.gender = positionRequirements.gender
        self.priesthood = positionRequirements.priesthood
        self.memberClass = positionRequirements.memberClasses
        callingStatuses = []
    }
    
    //MARK: - Filter Member
    func filterMemberData(unfilteredArray: [MemberCallings]) -> [MemberCallings] {
        let filters = createFilters()
        
        return unfilteredArray.filter() { member in
            filters.reduce( true ) {
                $0 && $1.filter( member )
            }
        }
    }
    
    func createFilters() -> [MemberFilter] {
        var filters : [MemberFilter] = []
        if minAge != nil || maxAge != nil {
            filters.append(AgeFilter(minAge: minAge, maxAge: maxAge))
        }
        if gender != nil {
            filters.append(GenderFilter(gender: gender))
        }
        if callings != nil {
            filters.append(CallingsFilter(callings: callings))
        }
        if minMonthsInCalling != nil {
            filters.append( TimeInCallingFilter(minMonthsInCalling: minMonthsInCalling ) )
        }
        if priesthood.isNotEmpty {
            filters.append( PriesthoodFilter(priesthood: priesthood) )
        }
        if memberClass.isNotEmpty{
            filters.append( MemberClassFilter(memberClass: memberClass) )
        }
        
        return filters
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

protocol MemberFilter {
    func filter( _ member: MemberCallings) -> Bool
}

struct MemberClassFilter : MemberFilter {
    var memberClass : [MemberClass]
    
    
    func filter(_ member: MemberCallings) -> Bool {
        guard self.memberClass.isNotEmpty else {
            return true
        }
        
        var includeInList = false
        // todo - this eventually needs to change to use actual class assignments from and LCR service call
        var currentMemberClass : MemberClass? = nil
        if member.member.gender == Gender.Female, let age = member.member.age {
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
            if let memClass = currentMemberClass {
                includeInList = memberClass.contains(item: memClass)
            }
        }
        return includeInList
        
    }
}

struct PriesthoodFilter : MemberFilter {
    var priesthood : [Priesthood]
    
    func filter(_ member: MemberCallings) -> Bool {
        guard priesthood.isNotEmpty else {
            return true
        }
        guard let memberPriesthood = member.member.priesthood  else {
            return false
        }
        return priesthood.contains(memberPriesthood)
    }
    
}

struct TimeInCallingFilter : MemberFilter {
    let minMonthsInCalling : Int?
    
    func filter(_ member: MemberCallings) -> Bool {
        // ensure that the "months in calling" filter has been set & it's greater than 0, otherwise we just return the original array
        guard let minMonths = minMonthsInCalling, minMonths > 0 else {
            return true
        }
        
        var greaterThanTime = false
        // look through all the user's callings, see if we find a single calling that has been active longer than the selected time
        for calling in member.callings {
            if calling.existingMonthsInCalling > minMonths {
                greaterThanTime = true
                break
            }
        }
        return greaterThanTime
    }
}

struct CallingsFilter : MemberFilter {
    var callings : [Int:Bool]?
    
    func filter(_ memberCallings: MemberCallings ) -> Bool {
        
        guard let numCallingSelectors = callings else {
            return true
        }
        
        // set of the number of callings the member should have to be included in the list
        let numCallingsSet = Set<Int>( numCallingSelectors.filteredDictionary( {key, value in return value} ).keys )
        // The last option in the filter list is 3+ (as of 7/17). includeMaxPlus & maxCallings allow us to include anyone that has 3 or more callings, and also keeps it flexible, if more options get added to the UI then this should all just work (as long as the elements are sequential and the last element in the list is <x>+, which they should always be)
        var includeMaxPlus = false
        // we're relying on the largest element in the dictionary being the indicator of how many + callings to include.
        let maxCallings = numCallingSelectors.keys.max()
        if maxCallings != nil {
            includeMaxPlus = numCallingSelectors[maxCallings!] ?? false
        }
        
        return  numCallingsSet.contains( memberCallings.callings.count ) || (includeMaxPlus && memberCallings.callings.count > maxCallings!)
        
    }
}

struct AgeFilter : MemberFilter {
    var minAge : Int? = nil
    var maxAge : Int? = nil
    
    func filter(_ memberCallings: MemberCallings) -> Bool {
        // if there's not a min or max age then nothing for this filter to do
        guard self.minAge != nil || self.maxAge != nil else {
            return true
        }
        var includeMember = false
        
        // get either the age's specified, or just set them to edge values so we can safely compare (don't have to check is minage & maxage set, or just one or the other)
        let minAge = self.minAge ?? 0
        let maxAge = self.maxAge ?? 1000
        if let age = memberCallings.member.age  {
            // at this point the member has an age and the min & max are either set based on the UI, or the default edges, so just make sure we're within those ranges
            includeMember = age >= minAge && age <= maxAge
        }
        else {
            print("\(String(describing: memberCallings.member.name))")
            // member didn't have an age, so they don't get included in the filter
            includeMember = false
        }
        
        return includeMember
    }
}

struct GenderFilter : MemberFilter {
    var gender : Gender? = nil
    
    func filter(_ memberCallings: MemberCallings) -> Bool {
        // if there's not a gender then nothing for this filter to do
        guard let gender = self.gender else {
            return true
        }
        
        return memberCallings.member.gender == gender
    }
}


