//
//  HTVTMemberParser.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 12/15/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import Foundation


public class HTVTMemberParser : MemberParser {
    
    let dateFormatter : DateFormatter
    let timeFieldSeparator = "T"
    
    init() {
        // HTVT dates should be in the format "1945-03-22T00:00:00.000-07:00" but we don't care about the time portion. To avoid the pitfalls around day boundaries and timezones we will attempt to strip off the time portion and only parse the date portion.
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
    }
    public func parseFamilyFrom( json: JSONObject ) -> [Member] {
        return parseFamilyFrom(json: json, includeChildren: false)
    }
    
    public func parseFamilyFrom( json: JSONObject, includeChildren : Bool ) -> [Member] {
        let members : [Member]
        var membersJson : [JSONObject] = []
        
        if let hoh = json[HTVTMemberJsonKeys.hoh] as? JSONObject {
            membersJson.append( hoh )
        }
        if let spouse = json[HTVTMemberJsonKeys.spouse] as? JSONObject {
            membersJson.append( spouse )
        }
        if let children = json[HTVTMemberJsonKeys.children] as? [JSONObject] {
            membersJson.append(contentsOf: children)
        }
        
        if membersJson.count > 0 {
            let householdPhone = json[HTVTMemberJsonKeys.householdPhone] as? String
            let householdEmail = json[HTVTMemberJsonKeys.householdEmail] as? String
            var address : [String] = []
            if let streetAddressJson = json[HTVTMemberJsonKeys.address] as? JSONObject {
                let street1 = streetAddressJson[HTVTMemberJsonKeys.streetAddress1] as? String
                let street2 = streetAddressJson[HTVTMemberJsonKeys.streetAddress2] as? String
                let city = streetAddressJson[HTVTMemberJsonKeys.city] as? String
                let state = streetAddressJson[HTVTMemberJsonKeys.state] as? String
                let postalCode = streetAddressJson[HTVTMemberJsonKeys.postal] as? String
                //There is not consistent uniformity with how street addresses are recorded. Generally street2 will be empty, but it could be City, State Postal so we're going to check if street 2 already contains the city, state or zip then we'll just use that, otherwise we'll add an address element that is made up of the combination of city, state, zip.
                // The reason we do this is to maintain flexibility between lds.org endpoints. Our current fallback endpoint doesn't have a city field, it has a desc1, desc2 and potentially a desc3. In most cases desc1 is the street1 and desc2 is city, state zip, but not always. But there isn't a discrete city field that we can store. So addresses have to be essentially for display only, we can't use city as a filter, or do anything intelligent with the discrete parts
                if street1 != nil {
                    address.append( street1! )
                }
                if street2 != nil {
                    address.append( street2! )
                    if ( city != nil && !(street2!.contains( city! ))) || ( state != nil && !(street2!.contains( state! )) ),
                        let combinedAddress = addressString(city: city, state: state, zip: postalCode){
                        address.append( combinedAddress )
                    }
                } else if let combinedAddress = addressString(city: city, state: state, zip: postalCode) {
                    address.append( combinedAddress )
                }
            }
            members = membersJson.map() { memberJSON -> Member? in
                let member = parseFrom( json: memberJSON, householdPhone: householdPhone, householdEmail: householdEmail, streetAddress: address )
                return member
                }.filter() {
                    // filter out any that are not valid members, or if we're limiting by age if they have an age then it must be greater than the min allowed. If there's not an age we include them (err on the side of caution)
                    $0 != nil && (includeChildren || $0!.age == nil || $0!.age! >= MemberConstants.minimumAge)
                } as! [Member]
            
        } else {
            members = []
        }
        
        return members
    }
    
    public func parseFrom( json : JSONObject, householdPhone : String? = nil, householdEmail : String? = nil, streetAddress : [String] = [] ) -> Member? {
        guard
            let indId = (json[ HTVTMemberJsonKeys.individualId ] as? NSNumber)?.int64Value
            else {
                return nil
        }
        let name = json[HTVTMemberJsonKeys.name] as? String
        let indEmail = json[HTVTMemberJsonKeys.indEmail] as? String
        let indPhone = json[HTVTMemberJsonKeys.indPhone] as? String
        var birthdate : Date? = nil
        
        if let birthdateStr = json[HTVTMemberJsonKeys.birthdate] as? String {
            let dateOnly = birthdateStr.components(separatedBy: timeFieldSeparator )
            birthdate = dateFormatter.date( from: dateOnly[0] )
        }
        let priesthood = Priesthood.init( optionalRaw: json[HTVTMemberJsonKeys.priesthood] as? String )
        
        let gender = Gender.init( optionalRaw: json[HTVTMemberJsonKeys.gender] as? String )
        
        return Member(indId: indId, name: name, indPhone: indPhone, housePhone: householdPhone, indEmail: indEmail, householdEmail: householdEmail, streetAddress: streetAddress, birthdate: birthdate, gender: gender, priesthood: priesthood, callings: [])
    }
    
    public func addressString( city : String?, state : String?, zip : String? ) -> String? {
        
        // todo - change to if
        guard city != nil || state != nil || zip != nil
            else {
                return nil
        }
        
        var result = ""
        if city != nil && !city!.isEmpty {
            result = city!
            if (state != nil && !state!.isEmpty)  || (zip != nil && !zip!.isEmpty) {
                result.append( ", " )
            }
        }
        result = state == nil || state!.isEmpty ? result : result + state! + " "
        result.append( zip ?? "" )
        return result
    }
    
    private struct HTVTMemberJsonKeys {
        // family level elements
        static let hoh = "headOfHouse"
        static let spouse = "spouse"
        static let children = "children"
        static let householdPhone = "phone"
        static let householdEmail = "emailAddress"
        static let address = "address"
        static let streetAddress1 = "streetAddress"
        static let streetAddress2 = "streetAddress2"
        static let city = "city"
        static let state = "state"
        static let postal = "postal"
        
        // individual level elements
        static let individualId = "individualId"
        static let name = "formattedName"
        static let priesthood = "priesthoodOffice"
        static let indEmail = "email"
        static let gender = "gender"
        static let indPhone = "phone"
        static let birthdate = "birthdate"
    }
    
}
