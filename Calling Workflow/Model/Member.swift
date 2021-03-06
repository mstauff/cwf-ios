//
//  Member.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/4/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import Foundation

public struct Member {
    
    let individualId : Int64
    /* This could come from formattedName or preferredName, depending on the service providing it, but within the context of our app we just show one name, we don't need to break it into first/last components, just need to display it as we're given it. */
    let name : String?
    
    /* individual phone will override household phone if it's present */
    let individualPhone : String?
    
    /* a household phone to fall back to if the individual phone isn't set */
    let householdPhone : String?
    
    /* individual email will override household email if it's present */
    let individualEmail : String?
    
    /* household email to fall back to if the individual email isn't set */
    let householdEmail : String?
    
    /* Array of Strings containing the street address. This is just for display purposes. We don't necessarily know if street[0] is the number and street (though it usually will be), or if city, state are in street[1] or street[2]. We just display whatever is in the array as a convenience for the user. There are 2 reasons for this. 1 is that we don't have a use case or any need to do anything based on city or state, it's just for display. 2 is that depending on the service that we're pulling data from lds.org the data may just be generic strings. In the case of pulling data from HTVT we do have dedicated city, state fields, but if we have to fall back to ldstools/directory then it just comes as strings. So the model will support the lowest common denominator. */
    let streetAddress : [String]
    
    /* Birthdate that may or may not be provided by the service. We will probably not display it ever, but we may filter or group by age on occasion so if it came from the service we'll store it. Currently HTVT does include it, most other services do not.*/
    let birthdate : Date?
    
    /* Gender of the member is available from some lds.org sources, but not all. So if we have it we can make use of it in filtering, not sure if we will enforce any business rules with it*/
    let gender : Gender?
    
    /* Priesthood office of the member if they hold it, and if it is available from the service. HTVT includes it, some others do not.*/
    let priesthood : Priesthood?
    
    /* Class (Quorum, YW, RS, etc.) that the member is assigned to, if any. Although in LCR there are multiple course assingments those are for SS (2nd hour), and then quorum or RS/YW (3rd hour). For purposes of callings we only need the 3rd hour assignment, and they should be mutually exclusive (can't be assigned to EQ & HP at the same time, or Laurels & RS) so we're gonig to only store a single assignment. Could go with an array in the future if needed. */
    var classAssignment : Int64? = nil
    
    /* This is the property that should be queried for a user's phone number. Individual phone will be used if it has a value, if not we will fall back to the household phone */
    var phone : String? {
        get  {
            return individualPhone ?? householdPhone
        }
    }
    
    /* This is the property that should be queried for a user's email. Individual email will be used if it has a value, if not we will fall back to the household email */
    var email : String? {
        get  {
            return individualEmail ?? householdEmail
        }
    }
    
    /* Convenience property to calculate the person's age if their birthdate has been set */
    var age : Int? {
        get {
            guard (birthdate != nil)
                else {
                    return nil
            }
            return  Calendar.current.dateComponents([.year], from: birthdate!, to: Date()).year
        }
    }
    
    init (indId: Int64, name:String?, indPhone: String?, housePhone:String?, indEmail:String?, householdEmail:String?, streetAddress : [String], birthdate : Date?, gender : Gender?, priesthood : Priesthood?) {
        self.individualId = indId
        self.name = Utils.nilIfEmpty(name)
        self.individualPhone = Utils.nilIfEmpty( indPhone )
        self.householdPhone = Utils.nilIfEmpty( housePhone )
        self.individualEmail = Utils.nilIfEmpty( indEmail )
        self.householdEmail = Utils.nilIfEmpty( householdEmail )
        self.streetAddress = streetAddress
        self.birthdate = birthdate
        self.gender = gender
        self.priesthood = priesthood
    }
}


public enum MemberSource {
    case HTVT, Directory
}

public protocol MemberParser {
    func parseFrom( json : JSONObject,  householdPhone : String?, householdEmail : String?, streetAddress : [String] ) -> Member?
    func parseFamilyFrom( json : JSONObject ) -> [Member]
}
