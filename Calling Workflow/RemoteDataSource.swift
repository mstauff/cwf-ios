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

class RemoteDataSource : NSObject, DataSource {
    
    private let orgFileNamesMap : [UnitLevelOrgType:String] = [ .Bishopric : "BISHOPRIC", .BranchPresidency : "BRANCH_PRES", .HighPriests : "HP", .Elders : "EQ", .ReliefSociety : "RS", .YoungMen : "YM", .YoungWomen : "YW", .SundaySchool : "SS", .Primary : "PRIMARY", .WardMissionaries : "WARD_MISSIONARY", .Other : "OTHER"]
    private let orgNameDelimiter = "-"
    
    // This is all the permissions (scopes) that the app needs
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLAuthScopeDriveMetadataReadonly, kGTLAuthScopeDriveAppdata]
    
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
    private var authCompletionHandler : ((UIViewController?, GTMOAuth2Authentication, NSError?) -> Void)? = nil
    private var fileListCompletionHandler : (([GTLDriveFile],NSError? ) -> Void)? = nil
    
    /*************** computed props ******************/
    var isAuthenticated : Bool {
        guard let authorizer = driveService.authorizer, let canAuth = authorizer.canAuthorize  else {
            return false;
        }
        
        return canAuth
    }
    
    /* Checks the keychain for an existing auth token */
    override init() {
        // TODO - this doesn't work locally, may be due to a bug when xcode debugger is attached to a sim.
        // Need to try it once we're working on a device, w/o xcode debugger
        
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychain( forName: RemoteStorageConstants.authTokenKeychainId, clientID: RemoteStorageConstants.oauthClientId,clientSecret: nil){
            if( auth.canAuthorize ) {
                driveService.authorizer = auth
            }
        }
        super.init()
    }

    /* Ensures the user is authenticated with google drive. It checks if it is already authenticated (via the keychain credentials that are queried at init), if not it presents its' own view controller to the user to authenticate with google drive.*/
    func authenticate( currentVC : UIViewController, completionHandler: @escaping (UIViewController?, GTMOAuth2Authentication, NSError?) -> Void ) {
        let scopeString = scopes.joined(separator: " ")
        if isAuthenticated {
            completionHandler( nil, driveService.authorizer as! GTMOAuth2Authentication, nil )
        } else {
            if let googleAuthVC = GTMOAuth2ViewControllerTouch(
                    scope: scopeString,
                    clientID: RemoteStorageConstants.oauthClientId,
                    clientSecret: nil,
                    keychainItemName: RemoteStorageConstants.authTokenKeychainId,
                    delegate: self,
                    finishedSelector: #selector( authComplete(vc:finished:error:)) ) {
                // store a reference to the completion handler so the authComplete() can reference it
                // this is so we can convert between using a selector which the google drive API requires
                // and a simple lambda from our swift code
                self.authCompletionHandler = completionHandler
                googleAuthVC.modalPresentationStyle = .overFullScreen
                currentVC.present(
                        googleAuthVC,
                        animated: true,
                        completion: nil
                )
            }

        }
    }

    /* Google Drive API makes use of #selector methods rather than callbacks, so this method is essentially the callback handler for the google drive authentication. All it basically does is caches the authentication result and then calls the completion handler that was passed in to the authenticate method. */
    func authComplete(vc : UIViewController, finished authResult : GTMOAuth2Authentication, error : NSError?) {
        if error != nil {
            driveService.authorizer = nil
        } else {
            driveService.authorizer = authResult
        }
        
        if authCompletionHandler != nil {
            authCompletionHandler!( vc, authResult, error )
            // once we've invoked it set it back to nil
            self.authCompletionHandler = nil
        }
    }

    /* This method should be called after authenticate and before you try to retrieve the contents of any org. This is separate from auth or init because it needs to have the list of orgs that exist for a unit on lds.org to compare to what data we have in google drive and either create what's missing, or report what should be deleted. The callback will include a list of orgs that exist in google drive but were not passed in to the method and would be candidates for deletion. Any orgs that are passed in that don't exist in google drive will be silently created. */
    func initializeDrive(forOrgs orgs: [Org], completionHandler: @escaping(_ remainingOrgs: [Org], _ error: NSError?) -> Void) {
        // although we could check if we already have filesByName then no need to hit goodrive, generally this should only be called once anyway so shouldn't matter. If it does get called a 2nd time then always checking goodrive allows us to grab any latest changes. Otherwise code might call this in an attempt to "refresh" but not get latest
        fetchFiles() { [weak weakSelf = self] (driveFiles, error) in
            var orgFileNames: Set<String> = Set()
            var orgMap = [String: Org]()
            // capture the filenames of orgs from lds.org for diffing against the goodrive contents. Also create a map of orgs by file name
            // so if we need to create any files for them we have the needed orgs
            orgs.forEach() { org in
                if let fileName = weakSelf?.getFileName(forOrg: org) {
                    orgFileNames.insert(fileName)
                    orgMap[fileName] = org
                }
            }

            // put all the files from goodrive in a dictionary indexed by their name
            var fileMap = [String: GTLDriveFile]()
            driveFiles.forEach() { file in
                fileMap[file.name] = file
            }

            weakSelf?.filesByName = fileMap

            let gooDriveFileNameSet = Set<String>(fileMap.keys)

            // filesToCreate are those that were passed in but don't exist in gooDrive
            let filesToCreate = orgFileNames.subtracting( gooDriveFileNameSet )
            filesToCreate.forEach() { fileName in
                if let org = orgMap[fileName] {
                    weakSelf?.updateOrg( org: org ) { _, _ in
                        // nothing to do - it will be created later
                    }
                }
            }

            let filesToRemove = gooDriveFileNameSet.subtracting( orgFileNames )
            let orgsToRemove : [Org] = filesToRemove.map() { fileName in
                return orgMap[fileName]
            }.flatMap() { $0 } // remove nils - shouldn't be any
            completionHandler( orgsToRemove, nil )
        }
    }

    /* Gets the contents for the org out of google drive. The org from lds.org is required as a param because we need both the org ID and the org type to get the correct data out of google drive */
    func getData(forOrg org : Org, completionHandler : @escaping (_ org : Org?, _ error : NSError? ) -> Void ){
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
            //TODO: make some standard keys - logMsg
            completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [:] ) )
        }
    }

    // todo - need to change the callback to take an conflict resolution object  - in case there were conflicts that had to be resolved
    func updateOrg( org: Org, completionHandler : @escaping (_ success : Bool, _ error: NSError? ) -> Void ) {
        // todo - need to check for conflicts first
        var updateError : NSError? = nil
        if let orgFileName = getFileName(forOrg: org ) {
            let orgJSONObj = org.toJSONObject()
            if let orgJSON = jsonSerializer.serialize(jsonObject: orgJSONObj) {

                addOrUpdateFile(fileName: orgFileName, fileContents: orgJSON) { (fileContents, error) in
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

    /* returns the file name for a given org in the form of <ORG_TYPE>-<ORG_ID>.json. So EQ-394205.json or PRIMARY-2038800.json */
    func getFileName( forOrg org: Org ) -> String? {
        var orgFileName : String? = nil
        if let orgType = UnitLevelOrgType( rawValue: org.orgTypeId ), let orgTypeStr = orgFileNamesMap[ orgType ]  {
            let orgId = String( org.id )
            orgFileName = orgTypeStr + orgNameDelimiter + orgId + RemoteStorageConstants.dataFileExtension
        }
        return orgFileName
    }

    // todo - this probably needs to return a GTLServiceTicket, but not sure how that works yet
    /* Updates a file in google drive to contain the given string data (should be JSON). If the file does not exist it will be created. This is a lower level method that just performs the actual create/update. It doesn't do any diff'ing of contents, etc. That would need to be done prior to calling this method */
    func addOrUpdateFile( fileName : String, fileContents : String, completionHandler : @escaping (_ fileContents : String?, _ error : NSError? ) -> Void ) {
        
        var originalFileContents : String? = nil
        
        self.getFile(fileName: fileName) { [weak weakSelf=self] (file, error) in
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler( nil, error )
                return
            }
            
            if file == nil {
                weakSelf?.createFile(fileName: fileName, fileContents: fileContents) { (createdFile, createFileError) in
                    guard error == nil else {
                        print( "Error: " + error.debugDescription )
                        completionHandler( nil, error )
                        return
                    }
                    weakSelf?.filesByName[fileName] = createdFile
                    completionHandler( fileContents, nil )
                }
            } else {
                // update the file
                weakSelf?.updateFile( file: file!, fileContents: fileContents )
            }
        }
    }

    /* Gets the file object (not the contents, just the object with the ID & other metadata) that exists in google drive. If the file is in google drive it will be passed to the callback. If the file doesn't currently exist in google drive then the callback will be invoked with a nil file & error */
    func getFile( fileName: String, completionHandler: @escaping ( _ file: GTLDriveFile?, _ error: NSError? ) -> Void ) {
        if let file = filesByName[ fileName ] {
            completionHandler( file, nil )
        } else {
            self.initializeDrive(forOrgs: [] ) { [weak weakSelf = self] _, error in
                if let file = weakSelf?.filesByName[ fileName ] {
                    completionHandler( file, nil )
                } else {
                    completionHandler( nil, error )
                }
            }
        }
        
    }

    /* Performs the actual update in google drive that will update the contents of the file with the JSON that is provided in this call */
    func updateFile( file: GTLDriveFile, fileContents: String ) {
        let newFileHack = GTLDriveFile()
        
        let encodedData = Data(fileContents.utf8)
        let uploadParams = GTLUploadParameters(data: encodedData, mimeType: RemoteStorageConstants.dataFileMimeType)
        if let query = GTLQueryDrive.queryForFilesUpdate(withObject: newFileHack, fileId: file.identifier, uploadParameters: uploadParams) {
            driveService.executeQuery(query) { (ticket, response, error) in
                guard error == nil else {
                    print( "Update Error: " + error.debugDescription )
                    return
                }
                print( "Update Result:" + response.debugDescription )
            }
        }
    }

    /* creates a file in google drive */
    func createFile( fileName: String, fileContents: String, completionHandler:@escaping ( _ file: GTLDriveFile?, _ error: NSError? ) -> Void) {
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
                completionHandler( nil, error as NSError? )
                return
            }
            
            completionHandler( file, nil )
            
            // todo - do we need to do anything with the data???
            //            guard let responseData = data else {
            //                let errorMsg = "Error: No network error, but did not recieve data"
            //                print( errorMsg )
            ////                completionHandler( nil, NSError( domain: ErrorConstants.domain, code: 404, userInfo: [ "error" : errorMsg ] ) )
            //                return
            //            }
            
            //            completionHandler( AppConfig.parseFrom( responseData.jsonDictionaryValue! ), nil )
        })
        
        
    }

    /* Looks up a file object from the cache and retrieves its' contents from google drive */
    func fetchFileContents( fileName: String, completionHandler: @escaping( _ fileContents:Data?, _ error:NSError? ) -> Void ) {
        // if we've previously looked up the file and already have cached the ID then just
        // look it up from the cache
        if let file = filesByName[ fileName ] {
            self.fetchContents( forFile: file, completionHandler: completionHandler )
        } else {
            // this should have already happened by the calling code, but just in case we'll read in what data is in google drive and see if we can find the ID of the file that we need
            self.initializeDrive(forOrgs: []) { [weak weakSelf=self] _, _ in
                if let file = weakSelf?.filesByName[ fileName ] {
                    weakSelf?.fetchContents(forFile: file, completionHandler: completionHandler)
                } else {
                    let errorMsg = "Error: No file found for \(fileName)"
                    print( errorMsg )
                    completionHandler( nil, NSError( domain: ErrorConstants.domain, code: ErrorConstants.notFound, userInfo: [ "error" : errorMsg ] ) )
                }
            }
        }
    }
    
    /**
     Attempts to get the data for a file. If the file did not exist it should return nil for the contents.
     if the file exists it should return the contents. If the file is empty it should return an empty string
     not nil
     */
    func fetchContents( forFile file: GTLDriveFile, completionHandler : @escaping( _ fileContents:Data?, _ error:NSError? ) -> Void ) {
        
        let fileUrl = String.init(format: "https://www.googleapis.com/drive/v3/files/%@?alt=media", file.identifier)
        let fetcher = driveService.fetcherService.fetcher(withURLString: fileUrl)
        fetcher.beginFetch( ) { (data, error) -> Void in
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler( nil, error as NSError? )
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
    
    /* Fetches all the files from the google drive appDataFolder and saves off the callback to be called by fileListComplete (since google drive api uses #selector methods for callbacks */
    private func fetchFiles( completionHandler: @escaping ([GTLDriveFile],NSError? ) -> Void) {
        let query = GTLQueryDrive.queryForFilesList()
        query?.spaces = "appDataFolder"
        
        query?.pageSize = 10
        query?.fields = "files(id, name)"
        // save off the completion handler so it can be referenced from the selector method
        self.fileListCompletionHandler = completionHandler
        
        driveService.executeQuery(
            query!,
            delegate: self,
            didFinish: #selector(fileListComplete(ticket:finishedWithObject:error:))
        )
    }
    
    /* Invoked by google drive when the fetching of files from appDataFolder is complete. This method just invokes the callback that was stored in fetchFiles with the result from the google drive operation */
    func fileListComplete(ticket : GTLServiceTicket,
                                finishedWithObject response : GTLDriveFileList,
                                error : NSError?) {
        guard error == nil else {
            //            showAlert(title: "Error", message: error.localizedDescription)
            // if there's a completionHandler, call it, then set it to nil to avoid memory cycle
            self.fileListCompletionHandler?( [], error )
            self.fileListCompletionHandler = nil
            return
        }
        
        let files : [GTLDriveFile] = response.files as? [GTLDriveFile] ?? []
        
        self.fileListCompletionHandler?( files, nil )
        self.fileListCompletionHandler = nil
    }
    
    
    
}
