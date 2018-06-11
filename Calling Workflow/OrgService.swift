//
//  OrgService.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 4/2/18.
//  Copyright © 2018 colsen. All rights reserved.
//

import Foundation

class OrgService {
    
    /** Method to remove a child/grandchild suborg from a given org, if it exists somewhere in the org tree structure */
    private func pruneOrg( _ orgToPrune : Org, fromParentOrg parentOrg: Org ) -> Org {
        var result : Org = parentOrg
        // if updatedWith returns nil it means the orgToPrune wasn't a child, so we just return the original org unchanged. If it returns a result it means it removed the subOrg, so we'll return that version
        if let org = parentOrg.updatedWith(childOrgRemoved: orgToPrune) {
            result = org
            result.hasUnsavedChanges = true
        }
        return result
    }
    
    /** Shouldn't be called for an entire unit at once since root level orgs need to be handled differently, they need the whole file to be removed rather than just parts of it. Also, this requires that orgs that potetntially need to be removed have been marked as a conflict (ConflictCause.LdsEquivalentDeleted) */
    func resolveSuborgConflicts( inOrg org: Org ) -> Org {
        var updatedOrg = org
        // we want all the orgs that have been deleted from lds.org, that doen't have any in process callings
        let deletedSubOrgs = org.allSubOrgs.filter() { $0.conflict == .LdsEquivalentDeleted && $0.allInProcessCallings.isEmpty }
        deletedSubOrgs.forEach() {
            updatedOrg = pruneOrg($0, fromParentOrg: updatedOrg)
        }
        
        return updatedOrg
    }
 
    /** Takes an org from the application data source (currently google drive) and compares it to an org coming from lds.org (currently LCR) and reconciles any differences between the two. The lds.org version is authoritative, so we generally modify the application version to match that. But we try to be smart about it so if we have an actual calling from LCR for a CTR7 teacher without a match in google drive, we would check to see if we have a potential calling in google drive for that same calling and individual (basically it was started in the app, but then recorded officially directly in LCR). If there's a match we update the potential with the actual.
     
     As a general rule if there is an outstanding change that appears to be finalized in the LDS version, we don't delete, we mark it so the user can confirm deletion. The one pseudo-exception is a case where a calling had a potential change in the app, and then the LDS version has that change finalized. In that case we had an existing ID from LCR so we know it is a match and we don't really delete a record, we just remove the potential details. In other cases where there was a potential being considered (but didn't have an ID from LCR), and then in the LDS version it has been finalized we just mark the potential for the user to confirm.
     
     We follow a similar pattern with orgs, if the org is in the app but no loner in the LDS data we mark it for the user to confirm. If an org is in the LDS data and not in the app, we just add it.   */
    func reconcileOrg(appOrg: Org, ldsOrg: Org, unitLevelOrg: Org) -> Org {
        var updatedOrg = appOrg
        
        let appOrgIds = Set<Int64>(appOrg.children.map( { $0.id } ))
        let ldsOrgIds = Set<Int64>(ldsOrg.children.map( { $0.id } ))
        
        // get the IDs that are only in the app, no longer in LCR. These need to be marked for deletion
        let appUniqueIds = appOrgIds.subtracting( ldsOrgIds )
        // get the IDs that are only in LCR, these will need to be added to the app data
        let ldsUniqueIds = ldsOrgIds.subtracting( appOrgIds )
        var updatedChildren : [Org] = []
        for appOrgChild in appOrg.children {
            // if the child org is in the list of app only children, then it no longer exists in LCR, so we need to mark it as a conflict that should be removed
            if appUniqueIds.contains( appOrgChild.id ) {
                var updatedChild = appOrgChild
                updatedChild.conflict = .LdsEquivalentDeleted
                updatedChildren.append( updatedChild )
                updatedOrg.hasUnsavedChanges = true
            } else {
                // otherwise, it exists in both places, so we recursively call to reconcile the child orgs
                let reconciledChildOrg = reconcileOrg(appOrg: appOrgChild, ldsOrg: ldsOrg.getChildOrg(id: appOrgChild.id)!, unitLevelOrg: unitLevelOrg )
                updatedChildren.append( reconciledChildOrg )
                
                // if we've already marked that there are changes to this org then we don't want to overwrite that with false from a child that didn't change, so if it's already marked for this org we use that, if not we'll look to the child to see if it's changed
                updatedOrg.hasUnsavedChanges = updatedOrg.hasUnsavedChanges || reconciledChildOrg.hasUnsavedChanges
            }
        }
        
        // if it's only in the lds org structure it's a new org that needs to be added to the app
        for ldsOrgChildId in ldsUniqueIds {
            if let ldsOrgChild = ldsOrg.getChildOrg(id: ldsOrgChildId) {
                updatedChildren.append( ldsOrgChild )
                updatedOrg.hasUnsavedChanges = true
            }
        }
        // sort the child orgs by display order
        updatedOrg.children = updatedChildren.sorted(by: Org.sortByDisplayOrder)
        
        // now reconcile the callings in the current org
        updatedOrg = reconcileCallings(inSubOrg: updatedOrg, ldsOrgVersion: ldsOrg)
        
        // sort any callings in the org by display order
        updatedOrg.callings = updatedOrg.callings.sorted(by: Calling.sortByDisplayOrder)
        
        
        return updatedOrg
        
    }
    
    /**Takes an org from the app data source (currently google drive) and compares the callings in it to the callings in an org from LCR to look for any differences. LCR is the authoritative source so we're mostly looking to make the app data match it, but we try to do it smartly where we looking for corresponding proposed changes that might match actual changes, and either automatically update the proposed data, or if we're not sure if something in the app data should be removed we mark it as being in conflict so it can be displayed to the user and resolved by them */
    private func reconcileCallings(inSubOrg appOrg: Org, ldsOrgVersion ldsOrg: Org) -> Org {
        // we could take and return [Calling] as params and return objects, but we also need to indicate if there were any changes that were made (currently stored in org.hasUnsavedChanges). That would require we return a tuple of (Bool, [Calling]), so rather than do that we'll stick with the Org object as the params & return type
        var updatedOrg = appOrg
        let appCallingsById = updatedOrg.callings.toDictionaryById() { $0.id }
        let appCallingIds = appCallingsById.keys
        
        let ldsOrgCallingsById = ldsOrg.callings.toDictionaryById() { $0.id }
        let ldsOrgCallingIds = ldsOrgCallingsById.keys
        
        
        for (ldsCallingId, ldsCalling) in ldsOrgCallingsById {
            
            // If the ID from lcr is already in our DB then there's nothing that's changed about it (you can't change the person holding the calling without getting a new calling ID). We could have changes from the app (with proposed or notes) but there are no changes on the LDS.org side that would need to be merged in.
            if !appCallingIds.contains(ldsCallingId) {
                // it's not in the app org db so it needs to be added.
                // first check to see if there's a potential calling in the org with same position
                
                // get any callings of the same position type to see if there's a potential that this should replace.
                // we already know it's in the same parent org so only thing to check is if the position is the same.
                // If it has an ID that matches another lds.org calling then we can safely eliminate it as a potential match as well
                let matchingPotentialCallings = appOrg.callings.filter() {
                    $0.position == ldsCalling.position && ( $0.id == nil || !ldsOrgCallingIds.contains( $0.id! ) )
                }
                var mergedProposedIndId : Int64? = nil
                var mergedProposedStatus : CallingStatus? = nil
                var mergedNotes : String? = nil
                
                // xcode warning says this should be a let constant since it never gets changed, but if you make it a let then it won't compile with a "let pattern can't appear nested in already immutable context"
                for var potentialCalling in matchingPotentialCallings {
                    // if we have an exact match - based on position w/o multiples then delete the potential (the actual will be added below when we add new callings from LCR)
                    // todo - review this - may be a better way - detect that nothing has changed so don't delete the google drive version and add the LCR version
                    if potentialCalling == ldsCalling  {
                        // if it's a different person that holds the actual calling, we'll merge the proposed individual into the actual, before we remove the proposed calling. If they do match then we just want to remove the proposed without merging any details
                        if potentialCalling.proposedIndId != ldsCalling.existingIndId {
                            // it's a different person that was proposed, so we'll merge them into the actual
                            mergedProposedIndId = potentialCalling.proposedIndId
                            mergedProposedStatus = potentialCalling.proposedStatus
                            mergedNotes = potentialCalling.notes
                        }
                        updatedOrg = updatedOrg.updatedWith(callingToDelete: potentialCalling) ?? updatedOrg
                        updatedOrg.hasUnsavedChanges = true
                    } else {
                        // we don't have an exact match (probably a case where multiples are allowed)
                        // if any potentials have an indId that matches the new actual then delete the potential
                        // or if the potential is empty we also want to overwrite it
                        if potentialCalling.proposedIndId == ldsCalling.existingIndId || potentialCalling.proposedIndId == nil {
                            updatedOrg = updatedOrg.updatedWith(callingToDelete: potentialCalling) ?? updatedOrg
                            updatedOrg.hasUnsavedChanges = true
                        }
                    }
                }
                
                // Now need to add the existing calling from LCR
                if let ldsCallingOrg = ldsCalling.parentOrg, let appCallingOrg = appOrg.id == ldsCallingOrg.id ? appOrg : appOrg.getChildOrg(id: ldsCallingOrg.id) {
                    let callingFromLcr = Calling(id: ldsCalling.id, cwfId: nil, existingIndId: ldsCalling.existingIndId, existingStatus: .Active, activeDate: ldsCalling.activeDate, proposedIndId: mergedProposedIndId, status: mergedProposedStatus, position: ldsCalling.position, notes: mergedNotes, parentOrg: appCallingOrg, cwfOnly: false)
                    updatedOrg = updatedOrg.updatedWith(newCalling: callingFromLcr) ?? updatedOrg
                    updatedOrg.hasUnsavedChanges = true
                }
            }
        }
        
        // we've addressed any differences between callings that exist in LCR but weren't up to date in the app. Now we need to look for any that are still in the app but aren't in LCR. For this step we only care about callings with actual ID's (that means they were at one point in LCR, but are no longer). Any callings in the app without an ID are just proposed callings that shouldn't exist in LCR yet, so we ignore those
        let callingIDsToRemove = Set(appCallingIds).subtracting(Set(ldsOrgCallingIds))
        for callingId in callingIDsToRemove {
            if var appCallingNotInLcr = appCallingsById[callingId] {
                if let mergedCalling = updatedOrg.getCalling( withSameId: appCallingNotInLcr ) {
                    // if multiples are allowed and there's no potential data then just go ahead and delete it.
                    if mergedCalling.position.multiplesAllowed && mergedCalling.proposedIndId == nil{
                        updatedOrg = updatedOrg.updatedWith(callingToDelete: appCallingNotInLcr) ?? updatedOrg
                        updatedOrg.hasUnsavedChanges = true
                    } else {
                        // if multiples are not allowed, or there's potential data then we just need to remove the actual portion of the calling
                        
                        let releasedLcrCalling = mergedCalling.withActualReleased()
                        if mergedCalling.position.multiplesAllowed {
                            // if multiples are allowed we have to remove the calling with the ID, then add in the updated.
                            // We can't do a straight update with the released calling, because the released version doesn't have the ID, and there's no way to definitively match without that
                            updatedOrg = updatedOrg.updatedWith(callingToDelete: mergedCalling) ?? updatedOrg
                            updatedOrg = updatedOrg.updatedWith(newCalling: releasedLcrCalling) ?? updatedOrg
                        } else {
                            // if no multiples, we can difinitively match based on calling type, so we can just do an update
                            updatedOrg = updatedOrg.updatedWith(changedCalling: releasedLcrCalling) ?? updatedOrg
                        }
                        updatedOrg.hasUnsavedChanges = true
                    }
                }
                // if it's not in the updatedOrg, then nothing to worry about, nothing to remove
            }
        }
        
        let emptyLCRCustomCallingTypeIds = ldsOrg.allOrgCallings.filter(){$0.id == nil && $0.position.custom}.map() { $0.position.positionTypeId }
        let emptyCustomCallingsToRemove = appOrg.allOrgCallings.filter() {$0.id == nil && $0.position.custom && !emptyLCRCustomCallingTypeIds.contains(item: $0.position.positionTypeId)}
        if emptyCustomCallingsToRemove.isNotEmpty {
            for emptyCustomCalling in emptyCustomCallingsToRemove {
                updatedOrg = updatedOrg.updatedWith(callingToDelete: emptyCustomCalling) ?? updatedOrg
            }
            updatedOrg.hasUnsavedChanges = true
        }
        
        let emptyLCRCallings = ldsOrg.callings.filter() { $0.id == nil && $0.position.multiplesAllowed }
        // for the app callings we need any that id is nil, or any that have been marked as a conflict (that's a case where the id could potentially be nil, pending user response
        let emptyAppCallings = updatedOrg.callings.filter() { ($0.id == nil || $0.conflict != nil) && !$0.cwfOnly  && $0.position.multiplesAllowed }
        
        // reduce to map  by type, then look for equivalent amounts.
        let emptyLCRCallingsByType = MultiValueDictionary<Int, Calling>.initFromArray(array: emptyLCRCallings, transformer: {$0.position.positionTypeId}  )
        let emptyAppCallingsByType = MultiValueDictionary<Int, Calling>.initFromArray(array: emptyAppCallings, transformer: {$0.position.positionTypeId} )
        emptyLCRCallingsByType.dictionary.forEach() { (positionTypeId, callings) in
            let equivalentAppCallings = emptyAppCallingsByType.getValues(forKey: positionTypeId)
            // compare size
            let numCallingsDiff = abs(equivalentAppCallings.count - callings.count)
            
            
            if equivalentAppCallings.count < callings.count {
                // we need to add the empty from LCR to updated Org
                for _ in 1...numCallingsDiff {
                    updatedOrg.callings.append( Calling( forPosition: callings[0].position ) )
                }
                updatedOrg.hasUnsavedChanges = true
            } else if equivalentAppCallings.count > callings.count {
                // of the empty callings that are candidates to remove we need to make sure that they don't have any proposed data, and then we remove up to numCallingsDiff of completely empty callings.
                let cwfIdsToRemove = equivalentAppCallings.filter() {
                    $0.proposedIndId == nil && $0.proposedStatus == .None && $0.notes == nil
                    }.prefix(numCallingsDiff).flatMap() { $0.cwfId }
                if cwfIdsToRemove.isNotEmpty {
                    updatedOrg.callings = updatedOrg.callings.filter() { $0.cwfId != nil && !cwfIdsToRemove.contains(item: $0.cwfId!) }
                    updatedOrg.hasUnsavedChanges = true
                }
            }
            
        }
        
        return updatedOrg
    }
    /**
     Determines if a calling is eligible to be deleted. In order to determine this we need the other callings in the sub org (if it's a class with multiple teachers we can delete teachers until there is only one left, but we need the context to determine that. The org could be any parent org of the calling, including the entire unit org. We will return true if the calling is cwfOnly (that means it was added by the app, if it was added then multiples are allowed and it can be deleted), or if there are multiples of the same calling type within the org. Returns false otherwise.
     */
    func canDeleteCalling( callingToDelete : Calling?, fromUnitOrg : Org? ) -> Bool {
        
        var result = false
        if let calling = callingToDelete, let unitOrg = fromUnitOrg {
            result = calling.cwfOnly
            
            // if calling is cwfOnly then we don't need to validate anything else. Safe to delete
            if !result, let parentOrgId = calling.parentOrg?.id, let parentOrg = unitOrg.getChildOrg(id: parentOrgId ) {
                // if it's not then we look to see if multiples are allowed. If not, it can't be deleted, we're done.
                if calling.position.multiplesAllowed {
                    // If multiples are allowed then we need to look for all other callings of the same type within the sub-org, if there's more than one we can delete. If there's not we can't
                    let callings = parentOrg.callings.filter() { $0.position.positionTypeId == calling.position.positionTypeId }
                    result = callings.count > 1
                }
            }
        }
        return result
    }

    

}

protocol OrgServiceInjected { }

extension OrgServiceInjected {
    var orgService:OrgService { get { return InjectionMap.orgService } }
}

