//
//  Org.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 8/17/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

/**
 An Org represents a CDOL org or sub org. In most cases a unit level org (i.e. EQ, RS, Primary, etc.) does not have callings associated directly with it. The callings will be in a sub org. So Primary Teachers are assigned to a specific class, that is an Org in the children of Primary. The Bishopric is the only exception we've found to this rule, there are no children for the bishopric org, it just has callings.
 */
public struct Org : JSONParsable  {
    
    /**
     The unique ID for this org - the equivalent of CDOL subOrgId. It has to be Int64 to ensure that it can hold a Java long value
     */
    let id : Int64
    
    /**
     The CDOL orgTypeId. We debated between making this an enum, or leaving it just the int. We went with int because although we do make use of the org type as an enum for the root level orgs within a unit (RS, EQ, Primary, etc.) we don't want to have to create an enum for all the sub orgs within those (EQ Pres., CTR 7, etc.). Since an Org represents both types of structures we decided to just use the int, and then in the cases where it's appropriate and necessary we can retrieve the corresponding UnitLevelOrgType for a given orgTypeId
     */
    let orgTypeId : Int
    
    /**
     The name of the org, which will be the customOrgName if it is set, or the defaultOrgName if there is not a custom name
     */
    let orgName : String
    
    /**
     This comes from LCR, just allows us to display the orgs in a consistent order
     */
    let displayOrder : Int
    
    /** Any child sub orgs. If this is a unit level org (like Primary) then it the callings array will be empty and the children array will be populated with all the classes, the presidency, the music, etc. If this is a sub org like a primary class then the children will be empty, and callings will be populated. The only top level org that we have observed that has callings directly, and no children, is the Bishopric org
     */
    var children : [Org] = []
    
    var callings : [Calling] = []
    
    var validPositions : [Position] = []
    
    var potentialNewPositions : [Position] {
        get {
            let existingPositionIds = callings.map() { $0.position.positionTypeId }
            return validPositions.filter() {
                // eventually this needs to account for hidden callins as well
                $0.multiplesAllowed || !existingPositionIds.contains(item: $0.positionTypeId)
            }
        }
    }

    var allOrgCallingIds : [Int64] {
        get {
            return allOrgCallings.map({ $0.id }).flatMap({$0})
        }
    }

    var allOrgCallings : [Calling] {
        get {
            var callings = self.callings;
            for subOrg in self.children {
                callings.append( contentsOf: subOrg.allOrgCallings )
            }
            return callings
        }
    }

    var allSubOrgs : [Org] {
        get {
            var subOrgs = self.children;
            for subOrg in self.children {
                subOrgs.append( contentsOf: subOrg.allSubOrgs )
            }
            return subOrgs
        }
    }

    var hasUnsavedChanges = false
    
    /// Indicates that this org is new to our data (i.e. the org was created in LCR). This enum will allow us to visually mark the org so the user can be aware of the change.
    var conflict : ConflictCause? = nil
    
    // Do we need these? Probably not for the app, but maybe we will to be able to send necessary data to LCR for calling updates
    //    var parentOrg : Org
    
    /** Function to create an array of Orgs from an array of JSON objects. When we get LCR data for a unit it comes as an array of all the root level orgs in a unit. It isn't contained in a parent Org structure, so this is a convenience method for processing those root level orgs in one call */
    static func orgArrays( fromJSONArray json: [JSONObject]) -> [Org] {
        let orgs : [Org] = json.flatMap() {
            Org(fromJSON: $0)
        }
        return orgs
        
    }

    public init?(fromJSON json: JSONObject) {
        guard
            // currently orgType is inlined with the org object, rather than a separate JSON piece
            // orgs can come from our google drive structure, or from LCR. Most of the google drive structure was designed based on the LCR org so fields are mostly named the same. OrgTypeId is the one exception. In the google drive object it's orgTypeId, in LCR there is an array of orgTypeIds, and then a convenience member var to get the first one named "firstOrgTypeId". If there were more differences we might look into subclassing & different impl's, but since this is the only one we just check for orgTypeId first and if it's not in the JSON then we check for firstOrgTypeId.
            let orgTypeId = json[ OrgJsonKeys.orgTypeId ] as? Int ?? json[ OrgJsonKeys.lcrOrgTypeId ] as? Int,
            let id = json[ OrgJsonKeys.id ] as? NSNumber,
            let displayOrder = json[OrgJsonKeys.displayOrder] as? Int
            else {
                return nil
        }
        let children = json[OrgJsonKeys.children] as? [JSONObject] ?? []
        let callings = json[OrgJsonKeys.callings] as? [JSONObject] ?? []
        var orgName = json[OrgJsonKeys.customOrgName] as? String ?? json[OrgJsonKeys.orgName] as? String
        orgName = orgName ?? ""
        let childOrgs : [Org] = children.map() { childOrgJSON -> Org? in
            return Org( fromJSON: childOrgJSON )
            }.flatMap() { $0 } // .flatMap() will remove any nil objects
        
        // This initializer is a bit unorthodox where it creates an org, then sets self to it, but we need to do that because the child callings need a reference to the containing org. Although we probably could make it work by making Calling.parentOrg optional, and then filling it in after everything else is initialized, this works, so we'll stick with this method unless it causes us some other issues
        var org = Org( id: id.int64Value, orgTypeId: orgTypeId, orgName: orgName!, displayOrder: displayOrder, children: childOrgs, callings: [] )
        let parsedCallings : [Calling] = callings.map() { callingJson -> Calling? in
            var calling = Calling( fromJSON: callingJson )
            // todo - at some point we need to deal with hidden callings
            calling?.parentOrg = org
            return calling
            }.flatMap() {$0} // .flatMap() will remove nil's

        org.callings = parsedCallings
        org.validPositions = Array.init( Set<Position>(parsedCallings.map() { $0.position }) )
        self = org
    }
    
    public init( id: Int64, orgTypeId: Int ) {
        self.init( id: id, orgTypeId: orgTypeId, orgName: "", displayOrder: 1, children: [], callings: [] )
    }
    
    public init( id: Int64, orgTypeId: Int, orgName : String, displayOrder : Int, children : [Org], callings : [Calling] ) {
        self.id = id
        self.orgTypeId = orgTypeId
        self.orgName = orgName
        self.displayOrder = displayOrder
        self.children = children
        self.callings = callings
    }
    
    public func toJSONObject() -> JSONObject {
        var jsonObj = JSONObject()
        jsonObj[OrgJsonKeys.id] = self.id as AnyObject
        jsonObj[OrgJsonKeys.orgTypeId] = self.orgTypeId as AnyObject
        jsonObj[OrgJsonKeys.orgName] = self.orgName as AnyObject
        jsonObj[OrgJsonKeys.displayOrder] = self.displayOrder as AnyObject
        let callingsJson : [JSONObject] = callings.map() { calling -> JSONObject in
            return calling.toJSONObject()
        }
        jsonObj[OrgJsonKeys.callings] = callingsJson as AnyObject
        
        let subOrgsJson : [JSONObject] = children.map() { childOrg -> JSONObject in
            return childOrg.toJSONObject()
        }
        jsonObj[OrgJsonKeys.children] = subOrgsJson as AnyObject
        
        return jsonObj;
    }

    public func getChildOrg( id: Int64 ) -> Org? {
        return self.allSubOrgs.first(where: { $0.id == id })
    }
    
    public func getCalling( _ calling: Calling ) -> Calling? {
        return self.allOrgCallings.first( where: { $0 == calling } )
    }
    
    /** Updates a suborg within this org, if the org is already a child of this org. If it's not a child this method does nothing (it doesn't add it) */
    public mutating func updateDirectChildOrg(org: Org ) {
        if let childOrgIdx = self.children.index(of: org) {
            self.children[childOrgIdx] = org
        }
    }
    
    /** Returns an optional int indicating 1) whether the given calling is a calling within this org, 2) Whether the calling is a calling of this org, or a calling of a child subOrg. If this method returns nil it indicates the calling is not found int this org at all. A return of 0 means it is a direct calling of the current org (it exists in org.callings[]). If it returns greater than 0 that indicates that it is a calling within one of the child suborgs of this org */
    public func getCallingDepth( calling: Calling ) -> Int? {
        var depth : Int? = nil
        if calling.parentOrg?.id == self.id || self.callings.contains( calling ) {
            depth = 0
        } else {
            for childOrg in self.children {
                if let childDepth = childOrg.getCallingDepth(calling: calling) {
                    depth = childDepth + 1
                    break;
                }
            }
        }
        
        return depth
    }
    
    /** Returns a new org with all callings within the org updated with any new metadata contained in the dictionary passed in to the method */
    public func updatedWith( positionMetadata: [Int:PositionMetadata] ) -> Org {
        var updatedOrg = self
        updatedOrg.callings = updatedOrg.callings.map() {
            // if nothing has changed with the metadata, then do nothing, just return the existing position
            if $0.position.metadata == positionMetadata[$0.position.positionTypeId] {
                return $0
            } else {
                // if the metadata has changed we have to create a new calling with the new details & return it
                var updatedPosition = $0.position
                updatedPosition.metadata = positionMetadata[$0.position.positionTypeId] ?? PositionMetadata()
                return Calling( $0, position: updatedPosition )
            }
        }
        
        updatedOrg.children = self.children.map( ) {$0.updatedWith( positionMetadata: positionMetadata )}
        
        return updatedOrg
    }
    
    /** Returns a new org with the original calling changed to the updated calling. Returns nil if the calling isn't in this Org.  */
    public func updatedWith( changedCalling: Calling ) -> Org? {
        return updatedWithCallingChange( updatedCalling: changedCalling, operation: .Update )
    }

    /** Returns a new org with the calling added to it's list of callings */
    public func updatedWith( newCalling: Calling ) -> Org? {
        return self.updatedWithCallingChange(updatedCalling: newCalling, operation: .Create )
    }
    
    /** Returns a new org with the given calling removed from it's list of callings */
    public func updatedWith( callingToDelete: Calling ) -> Org? {
        return self.updatedWithCallingChange(updatedCalling: callingToDelete, operation: .Delete )
    }
    
    /** Does the actual work of doing the CRUD operations with callings. Because Org is a struct we have to return a new copy with the updated data, we can't just make an inline change.*/
    func updatedWithCallingChange( updatedCalling: Calling, operation : CRUDOperation) -> Org? {
        // the calling has to be somewhere within this org for us to update it
        guard let callingDepth = self.getCallingDepth(calling: updatedCalling) else {
            return nil
        }

        var updatedOrg = self
        // if the calling exists in the current org (not a child org further down) then we go ahead and make a change, based on the operation
        if callingDepth == 0 {
            switch operation {
            case .Create, .Update:
                // look to find the match even on an add - could have been added by someone else
                if let callingIdx = self.callings.index(of: updatedCalling) {
                    updatedOrg.callings[callingIdx] = updatedCalling
                } else {
                    updatedOrg.callings.append( updatedCalling )
                }
            case .Delete:
                // if someone else has already deleted this will still function
                updatedOrg.callings = updatedOrg.callings.filter() { $0 != updatedCalling }
            }
        } else {
            // otherwise the calling is in a child org, so we go through all the children and attempt to update the calling. If the calling isn't in a given child org the method will return nil in which case we just use the org as it is. If the org does contain the calling then the method returns a new copy of the org and we will place that in the list of child orgs
            updatedOrg.children = self.children.map() { $0.updatedWithCallingChange(updatedCalling: updatedCalling, operation: operation) ?? $0 }
        }
        
        return updatedOrg
    }
    
    enum CRUDOperation {
        case Create
        case Update
        case Delete
    }

}

extension Org : Equatable {
    /* Verifies that they are the same CDOL org (same ID), not that the contents are the same) */
    public static func == ( lhs : Org, rhs: Org ) -> Bool {
        return lhs.id == rhs.id
    }
}


private struct OrgJsonKeys {
    static let id = "subOrgId"
    static let orgTypeId = "orgTypeId"
    static let displayOrder = "displayOrder"
    static let children = "children"
    static let callings = "callings"
    static let orgName = "defaultOrgName"
    static let customOrgName = "customOrgName"
    
    static let lcrOrgTypeId = "firstOrgTypeId"
}
