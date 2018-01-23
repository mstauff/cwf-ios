//
//  RemoteDataSource.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 10/4/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation
import GoogleAPIClient
import GTMOAuth2

class RemoteDataSource : NSObject, DataSource, GIDSignInDelegate {
    
    private let orgFileNamesMap : [UnitLevelOrgType:String] = [ .Bishopric : "BISHOPRIC", .BranchPresidency : "BRANCH_PRES", .HighPriests : "HP", .Elders : "EQ", .ReliefSociety : "RS", .YoungMen : "YM", .YoungWomen : "YW", .SundaySchool : "SS", .Primary : "PRIMARY", .WardMissionaries : "WARD_MISSIONARY", .Other : "OTHER"]
    private let orgNameDelimiter = "-"
    private let configFilePrefix = "settings-"
    
    // This is all the permissions (scopes) that the app needs
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let requiredScopes = [kGTLAuthScopeDriveMetadataReadonly, kGTLAuthScopeDriveAppdata]
    
    private let driveService = GTLServiceDrive()
    private var remoteDataFile : GTLDriveFile? = nil
    // mapping of file names to ID's, so we only have to look them up once
    private var filesByName = [String:GTLDriveFile]()

    private let jsonSerializer = JSONSerializerImpl()
    
    /*********** Completion Handler callbacks **************/
    // These methods get saved off by a method that calls google drive and has to pass a Selector. The method
    // that gets passed in as the selector will then invoke these callbacks when it completes. This allows us
    // to translate between the selectors used by google drive and Swift closure mechanisms used
    // by calling clients
    private var authCompletionHandler : ((Bool, Error?) -> Void)? = nil
    
    /*************** computed props ******************/
    var isAuthenticated : Bool {
        guard let authorizer = driveService.authorizer, let canAuth = authorizer.canAuthorize  else {
            return false;
        }
        
        return canAuth
    }

    /** The google userName. We keep a copy after login so we can parse the name for the unitNum*/
    private(set) var userName: String? = nil

    private var loggingInForUnitNum : Int64?

    var unitNum : Int64? {
        get {
            // this requires the username has the unit number as the last component. Something like "ldscd-cwf-557552@gmail.com"
            if let userNameDigits = userName?.components(separatedBy: orgNameDelimiter).last {
                return Int64(userNameDigits)
            } else {
                return nil
            }
        }
    }

    override init() {
        super.init()
        // Override point for customization after application launch.
    }
    
    /* Checks the keychain for an existing auth token, attempts to login if found */
    func hasValidCredentials( forUnit unitNum : Int64, completionHandler: @escaping (Bool, Error?) -> Void ) {

        // we don't have anyway to access the username of the google drive user at this point. We have to save this variable off so we can validate against it in the callback after the signin is successful (we have access to profile data at that point)
        self.loggingInForUnitNum = unitNum

        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError!)")
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().scopes = requiredScopes
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            self.authCompletionHandler = completionHandler
            // todo - do we need to do this every time?? Any way to search for existing session
            GIDSignIn.sharedInstance().signInSilently()
        } else {
            completionHandler( false, nil )
        }
        
    }
    
    func signOut() {
        GIDSignIn.sharedInstance().signOut()
        self.userName = nil
    }

    /** This is the callback for GIDSignIn signInSilently() attempt */
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            print("\(error.localizedDescription)")
            self.authCompletionHandler?( false, error )
            self.authCompletionHandler = nil
            return
        }
            // Perform any operations on signed in user here.
            //            let userId = user.userID                  // For client-side use only!
            //            let idToken = user.authentication.idToken // Safe to send to the server
            //            let fullName = user.profile.name
        driveService.authorizer = user.authentication.fetcherAuthorizer()
        self.userName = user.profile.email

        if AppConfig.validateRemoteDataAgainstLdsAccount {
            // ensures that the unit num we're using to hit lds.org is the same as our credentialled user
            if self.unitNum == self.loggingInForUnitNum {
                self.authCompletionHandler?(true, nil)
            } else {
                let errorMsg = "Google credentials don't match requested unit number"
                print(errorMsg)
                let error = NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [ "error" : errorMsg ])
                self.authCompletionHandler?( false, error )
            }
        } else {
            self.authCompletionHandler?(true, nil)
        }


        self.authCompletionHandler = nil
    }
    

    /* This method should be called after authenticate and before you try to retrieve the contents of any org. This is separate from auth or init because it needs to have the list of orgs that exist for a unit on lds.org to compare to what data we have in google drive and either create what's missing, or report what should be deleted. The callback will include a list of orgs that exist in google drive but were not passed in to the method and would be candidates for deletion. Any orgs that are passed in that don't exist in google drive will be silently created. */
    func initializeDrive(forOrgs orgs: [Org], completionHandler: @escaping(_ orgsToCreate: [Org], _ remainingOrgs: [Org], _ error: Error?) -> Void) {
        // although we could check if we already have filesByName then no need to hit goodrive, generally this should only be called once anyway so shouldn't matter. If it does get called a 2nd time then always checking goodrive allows us to grab any latest changes. Otherwise code might call this in an attempt to "refresh" but not get latest
        fetchFiles() { (driveFiles, error) in
            var orgFileNames: Set<String> = Set()
            var orgMap = [String: Org]()
            // capture the filenames of orgs from lds.org for diffing against the goodrive contents. Also create a map of orgs by file name
            // so if we need to create any files for them we have the needed orgs
            orgs.forEach() { org in
                if let fileName = self.getFileName(forOrg: org) {
                    // only insert if it doesn't already exist - this will ensure if by some accident we have duplicates for an org in google drive we always use the oldest file
                    if orgMap[fileName] == nil {
                        orgFileNames.insert(fileName)
                        orgMap[fileName] = org
                    } else {
                        // todo - we could at somepoint use delete the file if it's a duplicate
                        print( "RemoteDataSource.initializeDrive(forOrgs): Duplicate file found for \(fileName) - file will be ignored" )
                    }
                }
            }

            // put all the files from goodrive in a dictionary indexed by their name
            self.filesByName = driveFiles.toDictionaryById({$0.name})


            let gooDriveFileNameSet = Set<String>(self.filesByName.keys)

            // filesToCreate are those that were passed in but don't exist in gooDrive
            let filesToCreate = orgFileNames.subtracting( gooDriveFileNameSet )
            let orgsToCreate = filesToCreate.flatMap() { orgMap[$0] }

            let filesToRemove = gooDriveFileNameSet.subtracting( orgFileNames )
            // todo - test this - probably wrong, as any files that are not in lds.org will not be in orgMap, so trying to look them up by name will just result in a nil
            let orgsToRemove : [Org] = filesToRemove.flatMap() { fileName in
                // we only want to include files for orgs, not the config files. Eventually may want to filter this based on org being in the same unit as well
                return fileName.contains(RemoteStorageConstants.dataFileExtension) ? orgMap[fileName] : nil
            }
            
            completionHandler( orgsToCreate, orgsToRemove, nil )
        }
    }
    
    func createFiles( forOrgs orgs: [Org], completionHandler: @escaping(_ success : Bool, _ errors : [Error] )-> Void ) {
        
        if orgs.isEmpty {
            completionHandler( true, [] )
        } else {
            var creationErrors : [Error] = []
            let createFilesGroup = DispatchGroup()
            orgs.forEach() {
                createFilesGroup.enter()
                self.createOrg( org: $0 ) { _, error in
                    if let error = error {
                        creationErrors.append(error)
                    }
                    createFilesGroup.leave()
                }
            }
            createFilesGroup.notify(queue: DispatchQueue.main) {
                completionHandler( creationErrors.isEmpty, creationErrors )
            }
        }
    }

    /* Gets the contents for the org out of google drive. The org from lds.org is required as a param because we need both the org ID and the org type to get the correct data out of google drive */
    func getData(forOrg org : Org, completionHandler : @escaping (_ org : Org?, _ error : Error? ) -> Void ){
        if let orgFileName = getFileName( forOrg : org ) {
            fetchFileContents(fileName: orgFileName ) { fileContents, error in
                guard error == nil else {
                    print( "Error getting data for \(orgFileName): " + error.debugDescription )
                    completionHandler( nil, error )
                    return
                }
                do {
                    let orgJson = try JSONSerialization.jsonObject(with: fileContents!, options: [])
                    let orgResults = Org( fromJSON: orgJson as! JSONObject )
                    completionHandler( orgResults, nil )
                } catch {
                    completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.jsonParseError, userInfo: [:]) )
                }
            }
        } else {
            completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [:] ) )
        }
    }
    
    /* Creates an org if it doesn't exist. If the org already exists then we call the callback with an error (code is ErrorConstants.illegalArgument)*/
    func createOrg(org: Org, completionHandler: @escaping (Bool, Error?) -> Void) {
        if let orgFileName = getFileName(forOrg: org ) {
            let orgJSONObj = org.toJSONObject()
            if let orgJSON = jsonSerializer.serialize(jsonObject: orgJSONObj) {
                self.getFile(fileName: orgFileName) { (file, error) in
                    guard error == nil else {
                        print( "Error: " + error.debugDescription )
                        completionHandler( false, error )
                        return
                    }
                    
                    if file == nil {
                        self.createFile(fileName: orgFileName, fileContents: orgJSON) { (_, createFileError) in
                            guard createFileError == nil else {
                                print( "Error: " + error.debugDescription )
                                completionHandler( false, error )
                                return
                            }
                            
                            // createdFile does not have the google ID that all files have when we read them in initializeDrive, so we can't add it to the filesByName[:] here. It has to be added by the initializeDrive() method
                            // todo - at some point can we just do a getFile(byName) here to get the ID?
                            completionHandler( true, nil )
                        }
                    } else {
                        // file already existed - we can't create
                        completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.illegalArgument, userInfo: [:]) )
                    }
                }
            }
        }        
    }

    // todo - need to change the callback to take a conflict resolution object  - in case there were conflicts that had to be resolved
    func updateOrg( org: Org, completionHandler : @escaping (_ success : Bool, _ error: Error? ) -> Void ) {
        // todo - need to check for conflicts first
        var updateError : Error? = nil
        if let orgFileName = getFileName(forOrg: org ) {
            let orgJSONObj = org.toJSONObject()
            if let orgJSON = jsonSerializer.serialize(jsonObject: orgJSONObj) {

                updateFile(fileName: orgFileName, fileContents: orgJSON) { (fileContents, error) in
                    guard error == nil else {
                        print( "Error updating data for \(orgFileName): " + error.debugDescription )
                        completionHandler( false, error )
                        return
                    }
                    completionHandler( true, nil )
                }
            } else {
                let errorMsg = "Unable to serialize org: " + orgJSONObj.debugDescription
                updateError = NSError( domain: ErrorConstants.domain, code: ErrorConstants.jsonSerializeError, userInfo: [ "error" : errorMsg ])
            }
        } else {
            let errorMsg = "Unable to find file name for org type: \(org.orgTypeId)"
            updateError = NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [ "error" : errorMsg ])
        }

        if updateError != nil {
            completionHandler( false, updateError )
        }
    }
    
    func getUnitSettings( forUnitNum unitNum : Int64, completionHandler : @escaping( _ unitSettings : UnitSettings?, _ error : Error? ) -> Void ) {
        
        let fileName = getFileName(forUnitSettings: unitNum)
        
        fetchFileContents(fileName: fileName) { data, error in
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler( nil, error )
                return
            }
            
            guard let responseData = data else {
                let errorMsg = "Error: No network error, but did not recieve data from \(fileName)"
                print( errorMsg )
                completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [ "error" : errorMsg ] ) )
                return
            }
            do {
                let settingsJson = try JSONSerialization.jsonObject(with: responseData, options: [])
                let unitSettings = UnitSettings( fromJSON: settingsJson as! JSONObject )
                completionHandler( unitSettings, nil )
            } catch {
                let errorMsg = "Error: error parsing json: \(responseData.debugDescription)"
                print( errorMsg )
                completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.jsonParseError, userInfo:  [ "error" : errorMsg ] ) )
            }
        }
    }
    
    func updateUnitSettings( _ unitSettings : UnitSettings, completionHandler : @escaping( _ success : Bool, _ error : Error? ) -> Void ) {
        var updateError : Error? = nil
        guard let unitNum = unitSettings.unitNum else {
            let errorMsg = "Error: No unit number to update unit settings"
            print( errorMsg )
            completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [ "error" : errorMsg ] ) )
            return
        }
        
        let fileName = getFileName(forUnitSettings: unitNum )
        let settingsJSONObj = unitSettings.toJSONObject()
        if let settingsJSON = jsonSerializer.serialize(jsonObject: settingsJSONObj) {
            updateFile(fileName: fileName, fileContents: settingsJSON) { (fileContents, error) in
                // in this case we can't just guard against error, we need to look, if it's our own file not found error then we need to create it
                if let fileCreateError = error {
                    var errorHandled = false
                    // xcode gives a warning about "is" test is always true, but not sure why. It could be other error classes
                    if fileCreateError is NSError  {
                        let nsError = fileCreateError as NSError
                        if nsError.domain == ErrorConstants.domain && nsError.code == ErrorConstants.notFound {
                            errorHandled = true
                            // the file didn't exist, it needs to be created
                            self.createFile(fileName: fileName, fileContents: settingsJSON) { _, createFileError in
                                guard createFileError == nil else {
                                    print( "Error: " + error.debugDescription )
                                    completionHandler( false, error )
                                    return
                                }
                                completionHandler( true, nil )
                            }
                        }
                    }
                    if !errorHandled {
                        completionHandler( false, error )
                    }
                } else {
                    // error was nil, so update succeeded
                    completionHandler( true, nil )
                }
            }
        } else {
            let errorMsg = "Unable to serialize unit settings: " + settingsJSONObj.debugDescription
            updateError = NSError( domain: ErrorConstants.domain, code: ErrorConstants.jsonSerializeError, userInfo: [ "error" : errorMsg ])
        }
        
        if updateError != nil {
            completionHandler( false, updateError )
        }
        
    }

    /* returns the file name for a given org in the form of <ORG_TYPE>-<ORG_ID>.json. So EQ-394205.json or PRIMARY-2038800.json */
    func getFileName( forOrg org: Org ) -> String? {
        var orgFileName : String? = nil
        if let orgType = UnitLevelOrgType( rawValue: org.orgTypeId ), let orgTypeStr = orgFileNamesMap[ orgType ]  {
            let orgId = String( org.id )
            orgFileName = orgTypeStr + orgNameDelimiter + orgId + RemoteStorageConstants.dataFileExtension
        }
        return orgFileName
    }

    func getFileName( forUnitSettings unitNum: Int64 ) -> String {
        return configFilePrefix + String( unitNum ) + RemoteStorageConstants.configFileExtension
    }
    
    // todo - this probably needs to return a GTLServiceTicket, but not sure how that works yet
    /* Updates a file in google drive to contain the given string data (should be JSON). This is a lower level method that just performs the actual create/update. It doesn't do any diff'ing of contents, etc. That would need to be done prior to calling this method */
    func updateFile( fileName : String, fileContents : String, completionHandler : @escaping (_ success : Bool, _ error : Error? ) -> Void ) {
        
        self.getFile(fileName: fileName) { (gDriveFile, error) in
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler( false, error )
                return
            }
            guard let file = gDriveFile else {
                let errorMsg = "Error: No File to update for: \(fileName)"
                print( errorMsg )
                completionHandler( false, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [ "error" : errorMsg ] ) )
                return
            }
            
            // update the file
            let newFileHack = GTLDriveFile()
            
            let encodedData = Data(fileContents.utf8)
            let uploadParams = GTLUploadParameters(data: encodedData, mimeType: RemoteStorageConstants.dataFileMimeType)
            if let query = GTLQueryDrive.queryForFilesUpdate(withObject: newFileHack, fileId: file.identifier, uploadParameters: uploadParams) {
                self.driveService.executeQuery(query) { (ticket, response, error) in
                    guard error == nil else {
                        print( "Update Error: " + error.debugDescription )
                        completionHandler( false, error )
                        return
                    }
                    print( "Update Result:" + response.debugDescription )
                    completionHandler( true, nil )
                }
            }
        }
    }

    /* Gets the file object (not the contents, just the object with the ID & other metadata) that exists in google drive. If the file is in google drive it will be passed to the callback. If the file doesn't currently exist in google drive then the callback will be invoked with a nil file. Currently the error in the callback is unused, but it might be in the future if we make extra calls to google drive if we don't have a cached copy of the file */
    func getFile( fileName: String, completionHandler: @escaping ( _ file: GTLDriveFile?, _ error: Error? ) -> Void ) {
        if let file = filesByName[ fileName ] {
            completionHandler( file, nil )
        } else {
            // query google drive for any files with the given name (in case it does exist in google drive, just wasn't loaded at startup for whatever reason
            fetchFile(byName: fileName, completionHandler: completionHandler)
        }
    }

    /* creates a file in google drive */
    func createFile( fileName: String, fileContents: String, completionHandler:@escaping ( _ file: GTLDriveFile?, _ error: Error? ) -> Void) {
        let file = GTLDriveFile()
        
        file.name = fileName
        file.mimeType = RemoteStorageConstants.dataFileMimeType
        file.parents = [RemoteStorageConstants.dataFileFolder]
        
        let encodedData = Data(fileContents.utf8)
        let uploadParams = GTLUploadParameters(data: encodedData, mimeType: file.mimeType)
        let query = GTLQueryDrive.queryForFilesCreate(withObject: file, uploadParameters: uploadParams)
        driveService.executeQuery(query!, completionHandler: { (data, response, error) -> Void in
            
            print( "Response: \(response.debugDescription) Data: " + data.debugDescription + " Error: " + error.debugDescription )
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler( nil, error )
                return
            }
            
            completionHandler( file, nil )
        })
    }

    /* Looks up a file object from the cache and retrieves its' contents from google drive */
    func fetchFileContents( fileName: String, completionHandler: @escaping( _ fileContents:Data?, _ error:Error? ) -> Void ) {
        // if we've previously looked up the file and already have cached the ID then just
        // look it up from the cache
        if let file = filesByName[ fileName ] {
            self.fetchContents( forFile: file, completionHandler: completionHandler )
        } else {
            // this should never happen, but belt & suspenders
            let errorMsg = "Error: RemoteDataSource.fetchFileContents(): DataSource has not been properly initialized. No file \(fileName)"
            print( errorMsg )
            completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [ "error" : errorMsg ] ) )
        }
    }
    
    /**
     Attempts to get the data for a file. If the file did not exist it should return nil for the contents.
     if the file exists it should return the contents. If the file is empty it should return an empty string
     not nil
     */
    func fetchContents( forFile file: GTLDriveFile, completionHandler : @escaping( _ fileContents:Data?, _ error:Error? ) -> Void ) {
        
        let fileUrl = String.init(format: "https://www.googleapis.com/drive/v3/files/%@?alt=media", file.identifier)
        
        let fetcher = driveService.fetcherService.fetcher(withURLString: fileUrl)
        fetcher.beginFetch( ) { (data, error) -> Void in
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler( nil, error )
                return
            }
            
            guard let responseData = data else {
                let errorMsg = "Error: No network error, but did not recieve data from \(fileUrl)"
                print( errorMsg )
                completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [ "error" : errorMsg ] ) )
                return
            }
            
            completionHandler( responseData, nil )
        }
    }
    
    /* Fetches all the files from the google drive appDataFolder */
    private func fetchFiles( completionHandler: @escaping ([GTLDriveFile],Error? ) -> Void) {
        let query = GTLQueryDrive.queryForFilesList()
        query?.spaces = GoogleDriveConstants.storageFolder
        
        query?.pageSize = GoogleDriveConstants.pageSize
        query?.fields = GoogleDriveConstants.fields
        query?.orderBy = GoogleDriveConstants.orderByFirstCreated

        driveService.executeQuery(query!, completionHandler: {(ticket:GTLServiceTicket?, object: Any?, error: Error?)->Void in
            guard error == nil else {
                completionHandler( [], error )
                return
            }
            var files : [GTLDriveFile] = []
            if let driveFileList = object as? GTLDriveFileList {
                files = driveFileList.files as? [GTLDriveFile] ?? []
            }
            completionHandler( files, nil )
        })
    }
    
    /* Attempts to read a single file from google drive. We do this any time before creating a file to make sure it really needs to be created, and in an attempt to avoid creating duplicates. */
    private func fetchFile( byName fileName: String, completionHandler: @escaping (GTLDriveFile?,Error? ) -> Void) {
        let methodName = "RemoteDataSource.fetchFile(byName):"
        let query = GTLQueryDrive.queryForFilesList()
        query?.spaces = GoogleDriveConstants.storageFolder
        
        query?.fields = GoogleDriveConstants.fields
        query?.q = "name = '" + fileName + "'"
        print( methodName + "Looking for files with query: " + (query?.q)! )
        query?.orderBy = GoogleDriveConstants.orderByFirstCreated
        driveService.executeQuery(query!, completionHandler: {(ticket:GTLServiceTicket?, object: Any?, error: Error?)->Void in
                    guard error == nil else {
                        print( error.debugDescription )
                        completionHandler(nil, error )
                        return
                    }
            var file : GTLDriveFile? = nil
            if let driveFileList = object as? GTLDriveFileList {
                let files = driveFileList.files as? [GTLDriveFile] ?? []
                if files.count > 0 {
                    file = files[0]
                    if let fileName = file?.name, let fileId = file?.identifier {
                        print( methodName + "File name: " + fileName + " ID: " + fileId)
                    }
                }
            }
            completionHandler( file, nil )
        })
    }
    
}

struct GoogleDriveConstants {
    static let storageFolder = "appDataFolder"
    static let orderByFirstCreated = "createdTime desc"
    static let fields = "files(id, name)"
    static let pageSize = 100
}
