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
    let name : String?
    let individualPhone : String?
    let householdPhone : String?
    let individualEmail : String?
    let householdEmail : String?
    let streetAddress : [String]
    let birthdate : Date?
    let gender : Gender?
    let priesthood : Priesthood?
    var currentCallings : [Calling]
    
    var phone : String? {
        get  {
            return individualPhone ?? householdPhone
        }
    }
    
    var email : String? {
        get  {
            return individualEmail ?? householdEmail
        }
    }
    
    var age : Int? {
        get {
            guard (birthdate != nil)
                else {
                    return nil
            }
            return  Calendar.current.dateComponents([.year], from: birthdate!, to: Date()).year
        }
    }
    
    init (indId: Int64, name:String?, indPhone: String?, housePhone:String?, indEmail:String?, householdEmail:String?, streetAddress : [String], birthdate : Date?, gender : Gender?, priesthood : Priesthood?, callings : [Calling] ) {
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
        self.currentCallings = callings
    }
}

public enum Gender : String {
    case Male = "MALE"
    case Female = "FEMALE"
    
    public init?( optionalRaw: String? ) {
        guard optionalRaw != nil
            else {
                return nil
        }
        switch(optionalRaw!) {
        case  "MALE": self = .Male
        case "FEMALE" : self = .Female
        default: return nil
        }
    }
    
    // We have to write our own init as the default one apparently isn't visible outside the file the enum is declared in (everything worked fine when HTVTMemberParser was part of Member.swift, but as soon as we moved it to it's own file it could no longer use the default initializer. Since we had to write a manual one anyway I went ahead and created one to make the rawvalue optional
    public init?( rawValue: String ) {
        self.init( optionalRaw: rawValue )
    }
    
}

public enum Priesthood : String {
    case Deacon = "DEACON"
    case Teacher = "TEACHER"
    case Priest = "PRIEST"
    case Elder = "ELDER"
    case HighPriest = "HIGH_PRIEST"
    case Seventy = "SEVENTY"

    public init?( optionalRaw: String? ) {
        guard optionalRaw != nil
            else {
                return nil
        }
        switch(optionalRaw!) {
        case  "DEACON": self = .Deacon
        case "TEACHER" : self = .Teacher
        case  "PRIEST": self = .Priest
        case  "ELDER": self = .Elder
        case  "HIGH_PRIEST": self = .HighPriest
        case  "SEVENTY": self = .Seventy
        default: return nil
        }
    }
    
    // We have to write our own init as the default one apparently isn't visible outside the file the enum is declared in (everything worked fine when HTVTMemberParser was part of Member.swift, but as soon as we moved it to it's own file it could no longer use the default initializer. Since we had to write a manual one anyway I went ahead and created one to make the rawvalue optional
    public init?( rawValue: String ) {
        self.init( optionalRaw: rawValue )
    }
    
    
}

public enum MemberSource {
    case HTVT, Directory
}

public protocol MemberParser {
    func parseFrom( json : JSONObject,  householdPhone : String?, householdEmail : String?, streetAddress : [String] ) -> Member?
    func parseFamilyFrom( json : JSONObject ) -> [Member]
}

