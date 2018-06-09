//
//  CWFDataSource.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/5/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation
import UIKit

class CWFCallingManagerService: DataSourceInjected, DataCacheInjected, LdsOrgApiInjected, LdscdApiInjected, OrgServiceInjected{
    
    var ldsOrgUnit: Org? = nil
    var appDataOrg: Org? = nil
    private(set) var memberList: [Member] = []
    var appConfig: AppConfig = AppConfig() {
        didSet {
            self.ldsOrgApi.setAppConfig(appConfig: self.appConfig )
        }
    }
    var positionMetadataMap : [Int:PositionMetadata] = [:]
    
    // implied ldscdApi  comes from LdscdApiInjected
    // implied ldsOrgApi  comes from LdsOrgApiInjected
    // implied dataSource  comes from DataSourceInjected
    // implied dataCache comes from DataCacheInjected
    // implied orgService comes from OrgServiceInjected
    
    var memberCallings : [MemberCallings] {
        get {
            return memberList.map() {
                MemberCallings(member: $0, callings: memberCallingsMap.getValues(forKey: $0.individualId), proposedCallings: memberPotentialCallingsMap.getValues(forKey: $0.individualId))
            }
        }
    }
    
    /// These are orgs that are in the app data store (goodrive) but not in lds.org. They likely need to be deleted, but may contain changes that the user will need to discard or merge to another org
    private var extraAppOrgs: [Org] = []
    
    /// Map of root level orgs in the current unit by their ID
    private var ldsUnitOrgsMap: [Int64: Org] = [:]
    
    /// Map of callings by member
    private var memberCallingsMap = MultiValueDictionary<Int64, Calling>()
    private var memberPotentialCallingsMap = MultiValueDictionary<Int64, Calling>()
    
    private var unitLevelOrgsForSubOrgs: [Int64: Int64] = [:]
    
    private let jsonFileReader = JSONFileReader()
    
    let permissionMgr : PermissionManager
    
    public private(set) var user : LdsUser? = nil
    
    public private(set) var userRoles : [UnitRole] = []
    
    var statusToExcludeForUnit : [CallingStatus] = []
    
    let maxLoadAttempts = 1
    
    //MARK: - Lifecycle
    
    init() {
        permissionMgr = PermissionManager()
    }
    
    init(org: Org?, iMemberArray: [Member], permissionMgr: PermissionManager) {
        self.ldsOrgUnit = org
        self.memberList = iMemberArray
        self.permissionMgr = permissionMgr
    }
    
    /** Loads metadata about the different positions from the local filesystem. Eventually we'll want to enhance this so there is a companion method to load it remotely as well (at a time interval). We don't want to slow down startup, so we just read locally and after startup we can periodically check for any updates */
    private func loadLocalPositionMetadata() {
        let positionsMD = PositionMetadata.positionArrays(fromJSONArray: jsonFileReader.getJSONArray( fromFile: "position-metadata" ) )
        positionMetadataMap = positionsMD.toDictionaryById( {$0.positionTypeId} )
    }
    
    public func getLdsUser( username: String, password: String, useCachedVersion fromCache: Bool, completionHandler: @escaping (LdsUser?, Error?) -> Void ) {
        let ldsApi = self.ldsOrgApi
        // if we have a local user already, and the calling function doesn't force a new signin, go ahead and just return the existing user
        if let ldsUser = self.user, fromCache {
            completionHandler( ldsUser, nil )
        } else {
            ldsApi.ldsSignin(forUser: username, withPassword: password, { (error) -> Void in
                if error != nil {
                    print(error!)
                    completionHandler( nil, error )
                } else {
                    ldsApi.getCurrentUser() { (ldsUser, error) -> Void in
                        
                        if AppConfig.devMode {
                            // todo - this is a workaround for getCurrentUser() being broken in test.lds.org
                            let bishopPos = Position(positionTypeId: 4, name: nil, unitNum: 56030, hidden: false, multiplesAllowed: false, displayOrder: nil, metadata: PositionMetadata())
                            let fakeUser = LdsUser(individualId: 111, positions: [bishopPos])
                            self.user = ldsUser == nil ? fakeUser : ldsUser
                            completionHandler( self.user, nil )
                        } else {
                            guard error == nil, let _ = ldsUser else {
                                let errorMsg = "Error getting LDS User details: " + error.debugDescription
                                print( errorMsg )
                                completionHandler(nil, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
                                return
                            }
                            self.user = ldsUser
                            completionHandler( self.user, nil )

                        }
                    }
                }
            })
        }
    }
    
    public func logoutLdsUser( completionHandler: @escaping() -> Void ) {
        self.ldsOrgApi.ldsSignout() {
            completionHandler()
        }
        removeAllData()
        
    }
    
    private func removeAllData() {
        self.appDataOrg = nil
        self.ldsOrgUnit = nil
        self.memberList = []
        self.memberCallingsMap.removeAllValues()
        self.memberPotentialCallingsMap.removeAllValues()
        self.user = nil
        self.userRoles = []
    }
    
    public func getUnits( forUser user: LdsUser ) -> [Int64] {
        return permissionMgr.authorizedUnits(forUser: user)
    }
    
    /** Utility method for wiping out the json in a google drive file in case we get in a bad state. This will overwrite what's in google drive with */
    public func resetAppData( forOrgIds orgIds : [Int64], completionHandler: @escaping (Bool, Error?) -> Void ) {
        // ensure they have permissions (only unit admins)
        guard permissionMgr.hasPermission(unitRoles: userRoles, domain: .UnitGoogleAccount, permission: .Update) else {
            let errorMsg = "No permission to reset google drive data "
            print( errorMsg )
            completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notAuthorized, userInfo: ["error": errorMsg]))
            return
        }
        // get the orgs from the lds.org data (we will use that to overwrite anything in google drive)
        let orgs = orgIds.flatMap() { ldsOrgUnit?.getChildOrg(id: $0) }
        let orgNames = orgs.map({$0.orgName}).joined(separator: ",")
        print("Resetting data for " + orgNames)
        
        let dataSourceGroup = DispatchGroup()
        
        orgs.forEach() { ldsOrg in
            dataSourceGroup.enter()
            // write the lds.org back to google drive
            dataSource.updateOrg(org: ldsOrg) { success, error in
                // todo - need to add in error handling
                // update the app data (in memory merged lds.org & google drive) with just lds.org data
                self.appDataOrg?.updateDirectChildOrg(org: ldsOrg)
                dataSourceGroup.leave()
            }
        }
        
        dataSourceGroup.notify(queue: DispatchQueue.main) {
            // once we're all done go through  the init process again to get all the hashtables of calling holders, etc. updated with the latest data
            self.initDatasourceData(fromOrg: self.appDataOrg!, extraOrgs: [])
            completionHandler(true, nil)
        }
        
    }
    
    public func reloadLdsData( forUser: LdsUser?, completionHandler: @escaping (Bool, Error?) -> Void ) {
        
        let cachedOrParamUser = forUser == nil ? self.user : forUser
        if let unitNum = self.ldsOrgUnit?.unitNum, let user = cachedOrParamUser {
            loadLdsData(forUnit: unitNum, ldsUser: user, useCachedVersion: false) { success, error in
                guard error == nil, success == true else {
                    completionHandler( success, error )
                    return
                }
                
                if let ldsUnit = self.ldsOrgUnit {
                    self.loadAppData(ldsUnit: ldsUnit) { success, _, error in
                        completionHandler( success, error )
                    }
                } else {
                    // shouldn't ever happen, should be handled by the guard, but just in case
                    let errorMsg = "Error during resync: No LDS.org data " + error.debugDescription
                    print( errorMsg )
                    completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
                }
            }
        } else {
            // shouldn't ever happen, should never get here if we didn't have a unit on initial load
            let errorMsg = "Error during resync: No initial LDS.org data "
            print( errorMsg )
            completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
        }
    }
    
    /** Performs the calls that need to be made to lds.org at startup, or unit transition. First it gets the application config from our servers (which contains the lds.org endpoints to use). Next it logs in to lds.org, then it retrieves user data which includes their callings (to verify unit permissions), the unit member list and callings. Once all those have completed then we call the callback. If any one of them fails we will return an error via the callback. The data is not returned via the callback, it is just maintained internally in this class. The callback just lets the calling function know that this method has successfully completed.
     This method needs to be called prior to calling the authenticate() or loadAppData() methods */
    public func loadLdsData(forUnit unitNum: Int64, ldsUser: LdsUser, useCachedVersion loadFromCache: Bool, completionHandler: @escaping (Bool, Error?) -> Void) {
        var members : [Member] = []
        var ldsOrg : Org? = nil
        loadLocalPositionMetadata()
        
        self.userRoles = self.permissionMgr.createUserRoles(forPositions: ldsUser.positions, inUnit: unitNum)
        
        if self.permissionMgr.hasPermission(unitRoles: self.userRoles, domain: .OrgInfo, permission: .View) {
            let ldsApi = self.ldsOrgApi
            var ldsApiError: Error? = nil
            let restCallsGroup = DispatchGroup()
            
            // If we have member data and if we can load from cache then just set the local var to the memberList (we need to do this so the initLdsOrgData method gets the correct data, otherwise instead of initing with data from cache, it has empty data)
            // todo - rename loadFromCache - loadFromMemory to avoid confusion with the DataCache added for member class assignment support
            if self.memberList.isNotEmpty && loadFromCache {
                members = self.memberList
            } else {
                // if we can't use cached data, or we don't have cached data for the member list, go ahead and retrieve it
                restCallsGroup.enter()
                ldsApi.getMemberList(unitNum: unitNum) { (memberList, error) -> Void in
                    if memberList != nil && memberList!.isNotEmpty {
                        members = memberList!.sorted(by: Member.nameSorter)
                    } else {
                        if error != nil {
                            ldsApiError = error
                        }
                    }
                    restCallsGroup.leave()
                }
            }
            
            // if we have calling data and we can load from cache, then use it, otherwise load it from lds.org
            if self.ldsOrgUnit != nil && loadFromCache {
                ldsOrg = self.ldsOrgUnit
            } else {
                restCallsGroup.enter()
                ldsApi.getOrgWithCallings(subOrgId: unitNum) { (org, error) -> Void in
                    if let validOrg = org, !validOrg.children.isEmpty {
                        ldsOrg = validOrg
                    } else {
                        print("no org")
                        if error != nil {
                            ldsApiError = error
                        }
                    }
                    restCallsGroup.leave()
                }
            }
            
            // this gets called if the group is empty, so if we used cache, instead of loading data from lds.org nothing ever enters the restCallsGroup, this will still get called
            restCallsGroup.notify(queue: DispatchQueue.main) {
                if let validOrg = ldsOrg {
                    self.initLdsOrgData(memberList: members, org: validOrg, positionMetadata: self.positionMetadataMap)
                    self.loadMemberClasses( forOrg: validOrg, nil )
                }
                // once all the calls have returned then call the callback
                completionHandler(ldsApiError == nil, ldsApiError)
            }
        } else {
            let errorMsg = "No app permissions for user: " + ldsUser.description
            print( errorMsg )
            completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notAuthorized, userInfo: ["error": errorMsg]))
        }
    }
    
    func initLdsOrgData( memberList : [Member], org : Org, positionMetadata : [Int:PositionMetadata] ) {
        var org = org
        org = org.updatedWith(positionMetadata: positionMetadata)
        // remove any orgs that we don't recognize (i.e. Full Time Missionaries - orgTypeId = -5)
        org.children = org.children.filter() { UnitLevelOrgType( rawValue:  $0.orgTypeId ) != nil }
        // need to put in dictionary by root level org for updating
        self.ldsUnitOrgsMap.removeAll()
        self.ldsUnitOrgsMap = org.children.toDictionaryById() { $0.id }
        self.ldsOrgUnit = org
        let includeChildren = false // for now we always exclude children. If we ever want to make that optional behavior we just need to push this up and expose it as a param
        self.memberList = memberList
            .filter() {
                // filter out any that are not valid members, or if we're limiting by age if they have an age then it must be greater than the min allowed. If there's not an age we include them (err on the side of caution)
                $0.individualId > 0 && (includeChildren || $0.age == nil || $0.age! >= MemberConstants.minimumAge)
        }
    }
    
    func loadMemberClasses( forOrg baseOrg : Org, _ completionHandler: (( Bool, Error? ) -> Void)? ) {
        // array of dictionaries returned from ldsApi.getOrgMembers - this is to hold data in a collection as it gets pulled out of cache, or from the network. Once we have all the data we eventually combine down into one dictionary.
        var memberAssignmentsMap : [Int64: Int64] = [:]
        let synchronizedQueue = DispatchQueue(label: "MemberAssignmentsQueue")
        
        // filter out any orgs that we don't need membership for (keep EQ, RS, YW, etc. filter out Bishopric, SS, etc.)
        let orgsToLoad = baseOrg.children.filter() {
            self.appConfig.classAssignmentOrgTypes.contains(item: $0.orgTypeId)
        }
        
        // start processing disk reads and network calls on a background thread
        DispatchQueue.global(qos: .background).async {
            // first try loading from cache
            let cachedChildOrgs = orgsToLoad.flatMap() {
                self.dataCache.retrieve(forKey: self.cacheKey(forOrg: $0))
            }
            
            // If they are in local cache then check if they've expired.
            let cacheDataExpired = cachedChildOrgs.reduce(false) { result, org in
                result || org.isExpired
            }
            
            let restCallsGroup = DispatchGroup()
            
            // if nothing was in the cache, or anything in the cache had expired then load from the network
            if cachedChildOrgs.isEmpty || cacheDataExpired  {
                print( "No class assignments in cache, or expired, loading from network" )
                orgsToLoad.forEach() { org in
                    restCallsGroup.enter()
                    // load the members for each org from LCR. It's the same call as we use to get the org, it's just you have to request them on an org level (rather than a ward level) to get the member assignments. If you request the entire ward the members field for each org is empty
                    self.ldsOrgApi.getOrgMembers( ofSubOrgId: org.id ) { classMembers, error in
                        
                        guard error == nil else {
                            restCallsGroup.leave()
                            return
                        }
                        // if there are any members that were returned then add them to the array of dictionaries (we'll combine all the dictionaries later)
                        if classMembers.count > 0 {
                            // need to add the results to the memberAssignmentsMap - wrap in queue to protect from threading issues when multiple getOrgs calls return at same time
                            synchronizedQueue.async {
                                memberAssignmentsMap = memberAssignmentsMap.merged(withDictionary: classMembers)
                            }
                            // convert the dictionary to a jsonobject (jsonobj. is a dictionary<String, AnyObject>, so just need the types to be correct)
                            let classMembersJson = classMembers.mapDictionary() {
                                (String( describing: $0 ), $1 as AnyObject )
                                } as JSONObject
                            // store the results in cache
                            self.dataCache.store(json: classMembersJson, forKey: self.cacheKey(forOrg: org), expiringIn: CacheObject.defaultExpiration)
                        }
                        restCallsGroup.leave()
                    }
                }
            } else {
                // the data was already in cache, so we just need to convert it from JSONObject to [Int64:Int64]
                print( "Loaded class assignments from Memory Cache")
                memberAssignmentsMap = cachedChildOrgs.flatMap() {
                    let cachedOrgJson = $0.data[0]
                    return cachedOrgJson.mapToDictionary() {
                        if let intKey = Int64( $0.key ), $0.value is Int64, let intVal = $0.value as? NSNumber {
                            return (intKey, Int64(intVal))
                        } else {
                            return nil
                        }
                    }
                    }.reduce( memberAssignmentsMap ){ // After we convert from jsonobjects to dictionaries, then we reduce to a single dictionary
                        $0.merged( withDictionary:$1 )
                }
            }
            
            // once we get back all the results from the network, or if we never made any network calls
            restCallsGroup.notify(queue: DispatchQueue.main) {
                // update member objects with results
                self.memberList = self.updateWithClassAssignments( members: self.memberList, fromClassAssignments: memberAssignmentsMap )
                if let callback = completionHandler {
                    callback( true, nil )
                }
            }
        }
    }
    
    private func cacheKey( forOrg org : Org ) -> String {
        return "class-assignments-\(org.id)"
    }
    
    /** Returns a new list of member objects with the classes they are assigned to updated in the member objects */
    private func updateWithClassAssignments( members: [Member], fromClassAssignments orgAssignmentByIndId: [Int64:Int64] ) -> [Member] {
        let updatedMembers = members.map() { (member) -> Member in
            var updatedMember = member
            updatedMember.classAssignment = orgAssignmentByIndId[ member.individualId ]
            return updatedMember
        }
        
        return updatedMembers
    }
    
    /** Authenticate with the application's data source (currently google drive). We need to pass in the current view controller because if the user isn't already authenticated the google API will display a login screen for the user to authenticate. This should always be called before calling loadAppData() */
    public func hasDataSourceCredentials( forUnit unitNum: Int64, completionHandler: @escaping (Bool, Error?) -> Void ) {
        dataSource.hasValidCredentials(forUnit: unitNum, completionHandler: completionHandler)
    }
    
    /** Reads all the unit data from the application data store (currently google drive), and also reconciles any difference between data previously retrieved from lds.org. This method should only be called after loadLDSData() & authorizeDataSource() have successfully completed. The data is not returned in the callback, it is just maintained within this service. The callback just indicates to the calling function when this method has succesfully completed.
     The parameters for the callback indicate if all the data was loaded successfully, and whether there were extra orgs in the application data that were not in the lds.org data that potentially need to be removed or merged. This would be rare, but in cases where there were multiple EQ or RS groups, and then one gets removed in LCR we would still have the extra in our application data store*/
    public func loadAppData( ldsUnit: Org, completionHandler: @escaping(_ success: Bool, _ hasExtraOrgs: Bool, _ error : Error?) -> Void) {
        self.loadAppData(ldsUnit: ldsUnit, numLoadAttempts: 0, completionHandler: completionHandler)
    }
    
    /** Private version of loading data, it includes the number of times it's been attempted so when it gets called recursively we can limit it based on the number of attempts. Generally it will only get called twice (first is the load, 2nd is after we create new orgs). As a failsafe in case there are just errors with creating orgs we don't want to get stuck in a reconcile in a recursive calling loop */
    func loadAppData( ldsUnit: Org, numLoadAttempts: Int, completionHandler: @escaping(_ success: Bool, _ hasExtraOrgs: Bool, _ error : Error?) -> Void) {
        
        var org = Org(id: ldsUnit.id, unitNum: ldsUnit.unitNum, orgTypeId: ldsUnit.orgTypeId, orgName: ldsUnit.orgName, displayOrder: ldsUnit.displayOrder, children: [], callings: [])
        dataSource.initializeDrive(forOrgs: ldsOrgUnit!.children) { orgsToCreate, extraAppOrgs, error in
            // if there's more orgs to create, and we haven't hit the limit of number of attempts, then try to create more.
            // We include an artificial cap to prevent us from looping forever if there's just a case where we aren't able to create the missing orgs.
            if orgsToCreate.isNotEmpty && numLoadAttempts < self.maxLoadAttempts {
                self.dataSource.createFiles( forOrgs: orgsToCreate ) { success, errors in
                    if success {
                        // we have to attempt a load again to get the file ID's. The create doesn't return the ID for the file, so we have to repeat the init process (read all the files in google drive and then map the file ID's by name)
                        self.loadAppData(ldsUnit: ldsUnit, numLoadAttempts: numLoadAttempts + 1, completionHandler: { success, extraOrgs, error in
                            completionHandler( success, extraOrgs, error )
                        })
                    } else {
                        let error : Error? = errors.isNotEmpty ? errors[0] : nil
                        completionHandler( false, false, error )
                    }                    
                }
            } else {
                let dataSourceGroup = DispatchGroup()
                
                var mergedOrgs: [Org] = []
                for ldsOrg in ldsUnit.children {
                    dataSourceGroup.enter()
                    self.getOrgData(forOrgId: ldsOrg.id) { org, error in
                        dataSourceGroup.leave()
                        
                        guard org != nil else {
                            print( error.debugDescription )
                            return // exits the callback, not loadAppData
                        }
                        var mergedOrg = self.orgService.reconcileOrg(appOrg: org!, ldsOrg: ldsOrg, unitLevelOrg: ldsOrg)
                        
                        // we need to look for any orgs that have been removed in LCR, and use the org service to remove them from the org if there are no outstanding calling changes
                        mergedOrg.children = mergedOrg.children.map() { self.orgService.resolveSuborgConflicts(inOrg: $0) }
                        
                        if mergedOrg.hasUnsavedChanges {
                            self.dataSource.updateOrg(org: mergedOrg, completionHandler: { _,_ in
                                /* do nothing - for now.
                                 Eventually we probably want to prompt the user to retry - but how????
                                 */
                            })
                        }
                        mergedOrg.hasUnsavedChanges = false
                        mergedOrgs.append(mergedOrg)
                    }
                }
                
                // also load the unit settings
                dataSourceGroup.enter()
                self.loadUnitSettings(forUnitNum: ldsUnit.unitNum) { unitSettings, error in
                    dataSourceGroup.leave()
                    if let settings = unitSettings {
                        self.statusToExcludeForUnit = settings.disabledStatuses
                    }
                }
                
                // these are the orgs that aren't in LCR and don't have any in process callings - they can be safely removed
                let orgsToDelete = extraAppOrgs.filter() { $0.allInProcessCallings.isEmpty }
                self.dataSource.deleteFiles(forOrgs: orgsToDelete, completionHandler: nil)
                
                // these are the orgs that aren't in LCR, but they still have in process callings, so we need to add them in to the rest of the orgs that have been merged between LCR & app data so they appear in the app. Here we need to mark them as being in conflict, as they don't get marked in reconcile orgs (they never actually go through that code since they don't exist in both places)
                let conflictOrgs = extraAppOrgs.filter() { $0.allInProcessCallings.isNotEmpty }.map() { orgIn -> Org in
                    var org = orgIn
                    org.conflict = .LdsEquivalentDeleted
                    return org
                }
                
                dataSourceGroup.notify(queue: DispatchQueue.main) {
                    // sort all the unit level orgs by their display order
                    org.children = mergedOrgs + conflictOrgs
                    self.initDatasourceData(fromOrg: org, extraOrgs: extraAppOrgs)
                    completionHandler(error == nil, extraAppOrgs.isNotEmpty, error)
                }
            }
        }
    }
    
    func initDatasourceData( fromOrg org: Org, extraOrgs: [Org] ) {
        self.appDataOrg = org
        self.appDataOrg!.children = org.children.sorted(by: Org.sortByDisplayOrder)
        // add all the child suborgs to a dictionary for lookup by ID
        for childOrg in org.children {
            var subOrgsMap = childOrg.allSubOrgs.toDictionary({ subOrg in
                return (subOrg.id, childOrg.id)
            })
            // need to add the actual owning org as well, just so we don't have to do special case handling later if the calling is directly on a root org (i.e. bishopric calling)
            subOrgsMap[childOrg.id] = childOrg.id
            self.unitLevelOrgsForSubOrgs = self.unitLevelOrgsForSubOrgs.merged(withDictionary: subOrgsMap)
        }
        
        updateCallingMaps(org: org)
        self.extraAppOrgs = extraOrgs
        
    }
    
    private func updateCallingMaps(org: Org) {
        // this is only actual callings.
        self.memberCallingsMap = MultiValueDictionary<Int64, Calling>.initFromArray(array: org.allOrgCallings) { $0.existingIndId }
        // Now proposed callings
        self.memberPotentialCallingsMap = MultiValueDictionary<Int64, Calling>.initFromArray(array: org.allOrgCallings) { $0.proposedIndId }
    }
    
    func loadUnitSettings( forUnitNum unitNum: Int64, completionHandler: @escaping( UnitSettings?, Error?) -> Void ) {
        dataSource.getUnitSettings(forUnitNum: unitNum) { unitSettings, error in
            if let settings = unitSettings {
                self.statusToExcludeForUnit = settings.disabledStatuses
            }
            completionHandler( unitSettings, error )
        }
    }
    
    func updateUnitSettings( unitSettings: UnitSettings, completionHandler: @escaping( Bool, Error? ) -> Void ) {
        self.statusToExcludeForUnit = unitSettings.disabledStatuses
        dataSource.updateUnitSettings(unitSettings, completionHandler: completionHandler)
    }
    
    func updateUnitSettings( withStatuses statuses : [CallingStatus], completionHandler: @escaping( Bool, Error? ) -> Void ) {
        updateUnitSettings(unitSettings: UnitSettings( unitNum: ldsOrgUnit?.unitNum, disabledStatuses: statuses ), completionHandler: completionHandler)
    }
    
    /** Reads the given Org from google drive, updates the internal memory cache for orgs and the calling maps */
    public func reloadOrgData( forOrgId orgId: Int64, completionHandler: @escaping (Org?, Error?) -> Void ){
        getOrgData(forOrgId: orgId) { org, error in
            guard error == nil else {
                completionHandler(nil, error)
                return
            }
            
            guard let validOrg = org, let _ = self.appDataOrg else {
                // shouldn't happen
                let errorMsg = "Error while attempting to load org " + orgId.description + ". The org from google drive, or the in memory org were nil"
                print( errorMsg )
                completionHandler(nil, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
                return
            }
            
            // guard above ensures that appDataOrg isn't nil, so safe to !
            self.appDataOrg!.updateDirectChildOrg(org: validOrg)
            self.updateCallingMaps(org: self.appDataOrg!)
            completionHandler(validOrg, nil)
        }
    }
    
    /** Reads the given Org from google drive and calls the callback with the org converted from JSON. This doesn't update the internal org in memory or the calling maps. This should generally only be used during the startup */
    private func getOrgData(forOrgId orgId: Int64, completionHandler: @escaping (Org?, Error?) -> Void) {
        // we look for the org in appData first, and then use LCR orgs as a fallback. First time we go through this method there will not be any data in appDataOrg, since it hasn't been initialized yet, so in those cases it will use lds data. On subsequent attempts (when the user selects an org to view details) we need the appData copy of the org because that is the only one that has any potential conflicts.
        if let org = appDataOrg?.getChildOrg(id: orgId) ?? self.ldsUnitOrgsMap[orgId], let orgType = UnitLevelOrgType(rawValue: org.orgTypeId) {
            let orgAuth = AuthorizableOrg(unitNum: org.unitNum, unitLevelOrgId:org.id , unitLevelOrgType: orgType, orgTypeId: org.orgTypeId)
            guard permissionMgr.isAuthorized(unitRoles: userRoles, domain: .OrgInfo, permission: .View, targetData: orgAuth ) else  {
                completionHandler(org, nil)
                return
            }
            
            // the new data coming out of google drive will not have the conflicts that were found between the app and LCR data. We don't want to remerge against LCR because it may be stale, so we just want to get any callings that were found to be in conflict and update them once we pull latest out of google drive
            let conflictOrgIdMap : [Int64:ConflictCause] = org.allSubOrgs.filter({ $0.conflict != nil }).toDictionary() { return ( $0.id, $0.conflict! ) }
            dataSource.getData(forOrg: org) { org, error in
                if error != nil {
                    completionHandler(nil, error)
                } else if org == nil {
                    let errorMsg = "Error: No Org data found for ID: \(orgId)"
                    completionHandler(nil, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
                } else {
                    // add in position meta data, and any conflicts
                    let updatedOrg = org!.updatedWith(positionMetadata: self.positionMetadataMap).updatedWith( conflictOrgIds: conflictOrgIdMap )
                    completionHandler(updatedOrg, nil)
                }
            }
            
        } else {
            let errorMsg = "Error: No Org with ID: \(orgId)"
            completionHandler(nil, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
        }
    }
    
    /**
     utility method to combine existing calling data and proposed calling data into a single calling object
     */
    private func mergeCallingData( fromActualCalling existingCalling: Calling, andProposedCalling proposedCalling: Calling ) -> Calling {
        return Calling(id: existingCalling.id, cwfId: nil, existingIndId: existingCalling.existingIndId, existingStatus: .Active, activeDate: existingCalling.activeDate, proposedIndId: proposedCalling.proposedIndId, status: proposedCalling.proposedStatus, position: existingCalling.position, notes: proposedCalling.notes, parentOrg: existingCalling.parentOrg, cwfOnly: false)
        
    }
    
    
    // MARK: - Get Callings/Member data
    // Used to get a member from the memberlist by memberId
    func getMemberWithId(memberId: Int64) -> Member? {
        var member: Member? = nil
        for currentMember in memberList {
            if currentMember.individualId == memberId {
                member = currentMember
            }
        }
        return member
    }
    
    func getMemberCallings( forMemberId memberId: Int64 ) -> MemberCallings? {
        var memberCallings : MemberCallings? = nil
        if let member = getMemberWithId(memberId: memberId) {
            memberCallings = MemberCallings(member: member, callings: getCallings(forMember: member), proposedCallings: getPotentialCallings(forMember: member))
        }
        return memberCallings
    }
    
    func getCallings(forMember member: Member) -> [Calling] {
        return self.memberCallingsMap.getValues(forKey: member.individualId)
    }
    
    func getPotentialCallings( forMember member: Member ) -> [Calling] {
        return self.memberPotentialCallingsMap.getValues(forKey: member.individualId)
    }
    
    //MARK: - Update data in app data store
    /** Remove an org/sub-org from the data store */
    public func removeOrg( org orgToDelete: Org, completionHandler: @escaping(Bool, Error?) -> Void ) {
        var completionHandlerCalled = false
        // this should always be true, we shouldn't be able to have an org that doesn't exist in appDataOrg, but err on the side of caution
        if var unit = self.appDataOrg,  let orgDepth = unit.getOrgDepth(subOrg: orgToDelete) {
            if orgDepth == 0 {
                completionHandlerCalled = true
                // it's a root level org, so we need to remove the entire file
                self.dataSource.deleteFiles(forOrgs: [orgToDelete] ) { success, errors in
                    // also remove from in-memory org structure & update cache of member callings
                    unit = unit.updatedWith(childOrgRemoved: orgToDelete) ?? unit
                    self.initDatasourceData(fromOrg: unit, extraOrgs: [])
                    completionHandler( success, errors[safe: 0] )
                }
            } else if orgDepth > 0 {
                completionHandlerCalled = true
                // it's a sub-org, so we need to update a file
                let parentOrg = unit.children.first(where: { $0.getOrgDepth(subOrg: orgToDelete) != nil })
                if let updatedParentOrg = parentOrg?.updatedWith(childOrgRemoved: orgToDelete) {
                    unit.updateDirectChildOrg(org: updatedParentOrg)
                    self.initDatasourceData(fromOrg: unit, extraOrgs: [])
                    self.dataSource.updateOrg(org: updatedParentOrg, completionHandler: completionHandler )
                }
            }
        }
        if !completionHandlerCalled {
            // just to cover our bases. Shouldn't ever happen.
            completionHandler( false, nil )
        }
    }

    /** Adds a potential calling in the app's data store */
    public func addCalling(calling: Calling, completionHandler: @escaping(Bool, Error?) -> Void) {
        self.storeCallingChange(changedCalling: calling, operation: .Create, completionHandler: completionHandler)
    }
    
    /** deletes a potential calling in the app's data store */
     func deleteCalling(calling: Calling, completionHandler: @escaping(Bool, Error?) -> Void) {
        self.storeCallingChange(changedCalling: calling, operation: .Delete, completionHandler: completionHandler)
    }
    
    /** updates a potential calling in the app's data store */
    public func updateCalling(updatedCalling: Calling, completionHandler: @escaping (Bool, Error?) -> Void) {
        self.storeCallingChange(changedCalling: updatedCalling, operation: .Update, completionHandler: completionHandler)
    }
    
    /** "releases" a calling in the data store. This should never be called externally, it should only be used by releaseLCRCalling (after it completes successfully it calls this method to update google drive with the change) */
    func releaseCalling(updatedCalling: Calling, completionHandler: @escaping (Bool, Error?) -> Void) {
        // this should be the calling before it's released (still contains the positionId and the existing ind id so we can successfully identify it in the org structure)
        self.storeCallingChange(changedCalling: updatedCalling, operation: .Release, completionHandler: completionHandler)
    }
    
    /** Deletes a calling from either the remote data source, or from LCR (which in turn deletes it from the remote data source). All the other calling actions the change destination is determined by the action (calling actions->update or release is by definition an LCR update. Delete is the one exception where it could be a delete from the datasource, or a delete from LCR. So this method determines whether the calling can simply be deleted from the datasource or if we need to go to LCR */
    func deleteFromLCROrApp( calling: Calling, completionHandler: @escaping( Bool, Error?) -> Void ) {
        // if it's been created by cwf then we delete locally, if not then we attempt to delete from LCR. If it doesn't exist in LCR they will return an error, but we'll still delete locally as well.
        if calling.cwfOnly  {
            self.deleteCalling(calling: calling, completionHandler: completionHandler)
        } else {
            self.deleteLCRCalling(callingToDelete: calling, completionHandler: completionHandler )
        }
    }
    
    //MARK: - LCR API Calls
    
    public func updateLCRCalling( updatedCalling: Calling, completionHandler: @escaping(Calling?, Error?) -> Void ) {
        guard let unitNum = updatedCalling.parentOrg?.unitNum, let newIndId = updatedCalling.proposedIndId else {
            let errorMsg = "Error: calling didn't have a parent org, or there was not proposed calling"
            print( errorMsg )
            completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        
        self.ldsOrgApi.updateCalling(unitNum: unitNum, calling: updatedCalling) { callingFromLcr, error in
            guard error == nil, let validCallingFromLcr = callingFromLcr else {
                completionHandler( callingFromLcr, error )
                return
            }
            // todo - need to update ldsOrg copy of data -
            // If it's a position where duplicates are not allowed (i.e. Primary Pres.) then they will evaluate as == regardless of the ID's being different, so we can just do an update.
            if updatedCalling == validCallingFromLcr {
                self.updateCalling(updatedCalling: validCallingFromLcr) { success, error in
                    completionHandler( validCallingFromLcr, nil )
                }
            } else {
                // this is a situation where we have duplicates allowed (i.e. a primary teacher) so we need to release/add
                // todo - would be better to eventually combine this into a single update operation, but would need an update method that takes original & updated calling to be able to support changing in one operation
                self.deleteCalling(calling: updatedCalling) { success, error in
                    // todo - what if we get an error at this point?? Can't really roll back
                    self.addCalling(calling: validCallingFromLcr) { success, error in
                        completionHandler( validCallingFromLcr, nil )
                    }
                }
            }
        }
    }
    
    public func releaseLCRCalling( callingToRelease: Calling, completionHandler: @escaping(Bool, Error?) -> Void ) {
        guard let unitNum = callingToRelease.parentOrg?.unitNum else {
            let errorMsg = "Error: calling didn't have a parent org"
            print( errorMsg )
            completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        
        self.ldsOrgApi.releaseCalling(unitNum: unitNum, calling: callingToRelease ) { success, error in
            guard error == nil, success == true else {
                print( "Error trying to release calling in LCR: " + error.debugDescription )
                completionHandler( success, error )
                return
            }
            
            self.releaseCalling(updatedCalling: callingToRelease ) { success, error in
                print( "Successfully released: " + (callingToRelease.position.name?.description ?? "" ))
                completionHandler( success, error )
            }
        }
    }
    
     func deleteLCRCalling( callingToDelete: Calling, completionHandler: @escaping(Bool, Error?) -> Void ) {
        guard let unitNum = callingToDelete.parentOrg?.unitNum else {
            let errorMsg = "Error: calling didn't have a parent org"
            print( errorMsg )
            completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        
        self.ldsOrgApi.deleteCalling(unitNum: unitNum, calling: callingToDelete) { success, error in
            guard error == nil, success == true else {
                print( "Error trying to delete calling in LCR: " + error.debugDescription )
                completionHandler( success, error )
                return
            }
            
            self.deleteCalling(calling: callingToDelete ) { success, error in
                print( "Successfully deleted: " + (callingToDelete.position.name?.description ?? "" ))
                completionHandler( success, error )
            }
        }
    }
    
    //MARK: - Cached Data
    
    /** Performs the actual CRUD operations by reading the file for the org that the calling is in from google drive, performing the update, writing the entire org back to google drive, then updating the copy of the data that is cached locally. When this is all done we call the completion handler with the results */
    private func storeCallingChange(changedCalling: Calling, operation: Calling.ChangeOperation, completionHandler: @escaping (Bool, Error?) -> Void) {
        if let callingOrg = changedCalling.parentOrg, let unitLevelOrgId = self.unitLevelOrgsForSubOrgs[callingOrg.id], let unitLevelOrg = appDataOrg?.getChildOrg(id: unitLevelOrgId), let rootOrgType = UnitLevelOrgType(rawValue: unitLevelOrg.orgTypeId) {
            
            let orgAuth = AuthorizableOrg(fromSubOrg: callingOrg, inUnitLevelOrg: unitLevelOrg)
            
            let perm = getPermission(forCRUDOperation: operation)
            guard permissionMgr.isAuthorized(unitRoles: userRoles, domain: .PotentialCalling, permission: perm, targetData: orgAuth) else {
                let errorMsg = "Error: No Permission to make changes in : \(rootOrgType)"
                completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notAuthorized, userInfo: ["error": errorMsg]))
                return
            }
            
            let originalCalling = appDataOrg?.getCalling( changedCalling )
            // need to update appDataOrg with changes before we make asynch call - so whatever view gets drawn will have the changes
            
            var shouldRevert = false
            // update the cached copy of the org, as well as the calling maps where we keep track of the callings that individuals hold. We do this before going to google drive because we need the data to be updated in the UI. If we get an error we'll revert.
            // todo - this all needs to be changed to using original & changed calling consistently rather than the operation. Currently we end up checking the operation to determine behavior in several different methods, would be better to centralize that
            if let updatedRootOrg = unitLevelOrg.updatedWithCallingChange(updatedCalling: changedCalling, operation: operation) {
                self.appDataOrg!.updateDirectChildOrg(org: updatedRootOrg)
                // update any changed potential calling data
                self.memberPotentialCallingsMap = self.updateProposedCachedCallingData(originalCalling: originalCalling, updatedCalling: changedCalling, proposedCallingsMap: self.memberPotentialCallingsMap, operation: operation)
                
                // if there was an old calling, or if there's an actual calling in the updated version then update actual calling data
                if originalCalling != nil || changedCalling.existingIndId != nil {
                    self.memberCallingsMap = self.updateExistingCallingsData(originalCalling: originalCalling, updatedCalling: changedCalling, existingCallingsMap: self.memberCallingsMap, operation: operation )
                }
                shouldRevert = true
            }
            
            // read the org file fresh from google drive (to make sure we have the latest data before performing the change). This reduces the chance of clobbering another change in the org recorded by another user
            // we are intentionally using getOrgData rather than loadOrgData, which also updates internal cache. Since this is asynch we don't want to get in a case of the UI rendering, then we change the model in the background and cause it to change mysteriously
            self.getOrgData(forOrgId: unitLevelOrgId) { org, error in
                guard error == nil else {
                    if shouldRevert {
                        self.revertCachedCallingData(unitLevelOrg: unitLevelOrg, originalCalling: originalCalling, changedCalling: changedCalling, originalOperation: operation)
                    }
                    completionHandler(false, error)
                    return
                }
                guard let validOrg = org else {
                    if shouldRevert {
                        self.revertCachedCallingData(unitLevelOrg: unitLevelOrg, originalCalling: originalCalling, changedCalling: changedCalling, originalOperation: operation)
                    }
                    let errorMsg = "Error: No Org data found for ID: \(callingOrg.id)"
                    completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: ["error": errorMsg]))
                    return
                }
                // todo - eventually we'll need to make this a queueing mechanism to handle the case where multiple updates may be called before earlier ones return. For now we're keeping it simple
                if let updatedOrg = validOrg.updatedWithCallingChange(updatedCalling: changedCalling, operation: operation) {
                    self.dataSource.updateOrg(org: updatedOrg) { success, error in
                        
                        // we've already updated with the user change, but this will integrate any changes that have happened by other users outside the app. Not critical, but we have the data so might as well update. This won't change anything in the user's current view, but will show up next time they change a view
                        if success {
                            self.appDataOrg!.updateDirectChildOrg(org: updatedOrg)
                        } else {
                            if shouldRevert {
                                self.revertCachedCallingData(unitLevelOrg: updatedOrg, originalCalling: originalCalling, changedCalling: changedCalling, originalOperation: operation)
                            }
                            
                        }
                        // if it wasn't a success we just propogate the result and any errors on to the callback
                        completionHandler(success, error)
                    }
                } else {
                    // updatedOrg came back nil (either the calling wasn't really in the org, or originalCalling was nil on an update, Shouldn't ever happen).
                    if shouldRevert {
                        self.revertCachedCallingData(unitLevelOrg: unitLevelOrg, originalCalling: originalCalling, changedCalling: changedCalling, originalOperation: operation)
                    }
                    let errorMsg = "Error: Calling data incomplete, unable to update. Calling was not found in org."
                    completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: ["error": errorMsg]))
                }
            }
            
            
        } else {
            // either there was an error with the calling object (didn't have a parent), or the org data is wrong (i.e. the root org isn't in the dictionary) - shouldn't really happen outside of testing env.
            let errorMsg = "Error: Calling data incomplete, unable to update. Problem with containing org: " + (changedCalling.parentOrg?.id.description ?? " no org")
            completionHandler(false, NSError(domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: ["error": errorMsg]))
            
        }
    }
    
    func revertCachedCallingData(unitLevelOrg: Org, originalCalling: Calling?, changedCalling: Calling, originalOperation: Calling.ChangeOperation) {
        if self.appDataOrg != nil {
            self.appDataOrg!.updateDirectChildOrg(org: unitLevelOrg)
        }
        // update potential Callings map -  switch on operation. Although we could have a copy of this same calling object in the memberCallingsMap, the only thing we display from that map is the name of the calling and duration, so doesn't matter if any actual details are stale, we never read any potentially stale data from the callings in member callings map.
        
        switch originalOperation {
        case .Create:
            // if it was a create then we need to remove the added calling
            if let newProposedIndId = changedCalling.proposedIndId {
                self.memberPotentialCallingsMap.removeValue(forKey: newProposedIndId, value: changedCalling)
            }
        case .Delete:
            // if it was a delete then need to add the calling back in
            if let newProposedIndId = changedCalling.proposedIndId {
                self.memberPotentialCallingsMap.addValue(forKey: newProposedIndId, value: changedCalling)
            }
        case .Update:
            // the existing ID can't change on any proposed calling changes - we just need to update the cache of the propsed callings with the changes
            if let newProposedIndId = changedCalling.proposedIndId {
                self.memberPotentialCallingsMap.removeValue(forKey: newProposedIndId, value: changedCalling)
            }
            if let oldProposedIndId = originalCalling?.proposedIndId {
                self.memberPotentialCallingsMap.addValue(forKey: oldProposedIndId, value: originalCalling!)
            }
        case .Release:
            // do nothing
            break
        }
        
    }
    
    /** Currently this method just updates the org for the unit with the updated root level org (Primary, EQ, etc.). We don't change the map of actual callings because this is currently just for potential calling changes. The update of actual callings would only be after we've made a change in LCR */
    func updateProposedCachedCallingData(originalCalling: Calling?, updatedCalling: Calling, proposedCallingsMap : MultiValueDictionary<Int64, Calling>, operation: Calling.ChangeOperation) -> MultiValueDictionary<Int64, Calling> {
        var callings = proposedCallingsMap
        
        // In some cases of operations the "updatedCalling" isn't what you would expect (it still has some of the old data like the ID so we can find the original in the calling method). We could in the calling method change the updatedCalling to 
        // if there was an existing calling then remove it from the map
        if (operation == .Delete || operation == .Update), let originalCalling = originalCalling, let originalIndId = originalCalling.proposedIndId {
            callings.removeValue(forKey: originalIndId, value: originalCalling )
        }
        // if someone got a new calling then we need to add the calling to their list
        if (operation == .Create || operation == .Update ), let updatedIndId = updatedCalling.proposedIndId {
            callings.addValue(forKey: updatedIndId, value: updatedCalling)
        }
        
        return callings
    }
    
    /**
     Update the cache data of actual callings
     */
    func updateExistingCallingsData(originalCalling: Calling?, updatedCalling: Calling, existingCallingsMap existingCallings : MultiValueDictionary<Int64, Calling>, operation: Calling.ChangeOperation) -> MultiValueDictionary<Int64, Calling> {
        var callings = existingCallings
        
        // if there was an existing calling then remove it from the map
        if ([.Release, .Update, .Delete].contains( operation )), let originalCalling = originalCalling, let originalIndId = originalCalling.existingIndId {
            callings.removeValue(forKey: originalIndId, value: originalCalling)
        }
        // if someone got a new calling then we need to add the calling to their list
        if (operation == .Create || operation == .Update ),  let updatedIndId = updatedCalling.existingIndId, let _ = updatedCalling.id {
            var memberCallings = callings.getValues(forKey: updatedIndId)
            memberCallings.append(updatedCalling)
            callings.setValues(forKey: updatedIndId, values: memberCallings)
        }
        
        return callings
    }
    
    
    
    /** converts a CRUD operation into a permission of the same type */
    private func getPermission( forCRUDOperation crudOp : Calling.ChangeOperation ) -> Permission {
        switch crudOp {
        case .Create:
            return .Create
        case .Update, .Release:
            return .Update
        case .Delete:
            return .Delete
        }
    }
    
    /** Looks up a unit level org by its' ID and returns the type of the org. Returns nil if the org id is not in the list of unit level orgs */
    func unitLevelOrgType( forOrg rootOrgId: Int64 ) -> UnitLevelOrgType? {
        var orgType : UnitLevelOrgType? = nil
        if let rootOrgTypeId = self.ldsUnitOrgsMap[rootOrgId]?.orgTypeId {
            orgType = UnitLevelOrgType(rawValue: rootOrgTypeId)
        }
        return orgType
    }
    
    func unitLevelOrg( forSubOrg subOrgId: Int64) -> Org? {
        var org : Org? = nil
        if let orgId = unitLevelOrgsForSubOrgs[subOrgId] {
            if let rootOrg = ldsUnitOrgsMap[orgId] {
                org = rootOrg
            } else {
                // the org may not be in the map if it's one that is no longer in LCR, so try looking it up from appData
                org = appDataOrg?.getChildOrg(id: orgId)
            }
        }
        
        return org
    }
}

