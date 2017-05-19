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
    func isAuthorized( role: UnitRole, domain: Domain, permission: Permission, targetData: Authorizable ) -> Bool
    
}

public class UnitPermResolver : PermissionResolver {
    public func isAuthorized(role: UnitRole, domain: Domain, permission: Permission, targetData: Authorizable) -> Bool {
        // eventually we may need to break this down into a switch based on the domain object, but current requirements just need to ensure they have rights for the unit
        return role.unitNum == targetData.unitNum
    }
}

public class OrgPermResolver : PermissionResolver {
    public func isAuthorized(role: UnitRole, domain: Domain, permission: Permission, targetData: Authorizable) -> Bool {
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

