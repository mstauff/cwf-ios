//
//  PermissionResolver.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 5/16/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

/** Protocol for checking if a role is authorized for the data it's trying to access. A unit admin only has to validate that they're in the same unit as the data. An OrgAdmin has to validate the unit, and that they're part of the org type of the data */
public protocol PermissionResolver {
    func isAuthorized( role: UnitRole, targetData: Authorizable ) -> Bool
    
}

public class UnitPermResolver : PermissionResolver {
    public func isAuthorized(role: UnitRole, targetData: Authorizable) -> Bool {
        
        // in the case of an org permission resolver we default to false, unless we have a match of the org type to the role. 
        // For unit admins we're going to default to true essentially (they have to match the unit number, but based on the way the app works that should never be false) and then we look to see if the target data is associated with an org and if so if that org is excepted from their privileges
        // if it's an authorizableUnit, or something else added in the future then the only thing that comes into play is that the unit number matches
        var result =  role.unitNum == targetData.unitNum
        var targetOrgAuth : AuthorizableOrg? = nil
        
        if targetData is AuthorizableOrg {
            targetOrgAuth = targetData as? AuthorizableOrg
        } else if targetData is AuthorizableCalling {
            targetOrgAuth = (targetData as! AuthorizableCalling).owningAuthOrg
        }
        
        if let target = targetOrgAuth, target.orgTypeId == role.orgRightsException {
            result = false
        }
        
        return result
    }
}

public class OrgPermResolver : PermissionResolver {
    public func isAuthorized(role: UnitRole, targetData: Authorizable) -> Bool {
        var targetOrgAuth : AuthorizableOrg? = nil
        
        if targetData is AuthorizableOrg {
            targetOrgAuth = targetData as? AuthorizableOrg
        } else if targetData is AuthorizableCalling {
            targetOrgAuth = (targetData as! AuthorizableCalling).owningAuthOrg
        }
        
        var result = false
        
        if let target = targetOrgAuth, target.orgTypeId != role.orgRightsException {
            result = target.unitNum == role.unitNum && target.unitLevelOrgType == role.orgType
        }
        
        return result
    }
    
    
}

