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

protocol DataSource {
    func authenticate( currentVC : UIViewController, completionHandler: @escaping (UIViewController, GTMOAuth2Authentication, NSError?) -> Void  )
    
    var isAuthenticated : Bool {
        get
    }
    
}

// TODO - need to see what we can DI here - 
class RemoteDataSource : NSObject, DataSource {
    
    // This is all the permissions (scopes) that the app needs
    // If modifying these scopes, delete your previously saved credentials by
    // resetting the iOS simulator or uninstall the app.
    private let scopes = [kGTLAuthScopeDriveMetadataReadonly, kGTLAuthScopeDriveAppdata]
    
    private let driveService = GTLServiceDrive()
    private var remoteDataFile : GTLDriveFile? = nil
    // mapping of file names to ID's, so we only have to look them up once
    private var filesByName = [String:GTLDriveFile]()
    
    /*********** Completion Handler callbacks **************/
    // These methods get saved off by a method that calls google drive and has to pass a Selector. The method
    // that gets passed in as the selector will then invoke these callbacks when it completes. This allows us
    // to translate between the selectors used by google drive and Swift closure mechanisms used
    // by calling clients
    private var authCompletionHandler : ((UIViewController, GTMOAuth2Authentication, NSError?) -> Void)? = nil
    private var fileListCompletionHandler : (([GTLDriveFile]?,NSError? ) -> Void)? = nil
    
    
    /*************** computed props ******************/
    var isAuthenticated : Bool {
        guard let authorizer = driveService.authorizer, let canAuth = authorizer.canAuthorize  else {
            return false;
        }
        
        return canAuth
    }
    
    override init() {
        // TODO - this doesn't work locally, may be due to a bug when xcode debugger is attached to a sim.
        // Need to try it once we're working on a device, w/o xcode debugger
        if let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychain( forName: RemoteStorageConstants.authTokenKeychainId, clientID: RemoteStorageConstants.oauthClientId,clientSecret: nil) {
            if( auth.canAuthorize ) {
                driveService.authorizer = auth
            }
        }
        super.init()
    }
    
    func authenticate( currentVC : UIViewController, completionHandler: @escaping (UIViewController, GTMOAuth2Authentication, NSError?) -> Void ) {
        let scopeString = scopes.joined(separator: " ")
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
    
    // TODO - eventually this
    func getDataForOrg( org : Org, completionHandler : @escaping (_ fileContents : String?, _ error : NSError? ) -> Void ) {
        
    }
    
    // todo - this probably needs to return a GTLServiceTicket, but not sure how that works yet
    func addOrUpdateFile( fileName : String, fileContents : String, completionHandler : @escaping (_ fileContents : String?, _ error : NSError? ) -> Void ) {
        
        var originalFileContents : String? = nil
        
        self.getFile(fileName: fileName) { (file, error) in
            guard error == nil else {
                print( "Error: " + error.debugDescription )
                completionHandler( nil, error )
                return
            }
            
            if file == nil {
                self.createFile(fileName: fileName, fileContents: fileContents) { [weak weakSelf = self] (createdFile, createFileError) in
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
                self.updateFile( file: file!, fileContents: fileContents )
            }
        }
    }
    
    func getFile( fileName: String, completionHandler: @escaping ( _ file: GTLDriveFile?, _ error: NSError? ) -> Void ) {
        if let file = filesByName[ fileName ] {
            completionHandler( file, nil )
        } else {
            
            // otherwise we have to hit google drive to get the ID
            fetchFiles( name: fileName ) { [weak weakSelf = self] ( files, error ) in
                guard error == nil else {
                    completionHandler( nil, error )
                    return
                }
                
                // TODO - need to deal with multiple files
                if let file = files?.first {
                    // cache the ID so subsequent requests don't have to hit google drive again
                    weakSelf?.filesByName[ fileName ] = file
                    completionHandler( file, nil )
                } else {
                    completionHandler( nil, nil )
                }
            }
        }
        
    }
    
    func updateFile( file: GTLDriveFile, fileContents: String ) {
        let newFileHack = GTLDriveFile()
//        newFileHack.mimeType = file.mimeType ?? RemoteStorageConstants.dataFileMimeType
        
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
    
    func fetchFileContents( fileName: String, completionHandler: @escaping( _ fileContents:String?, _ error:NSError? ) -> Void ) {
        // if we've previously looked up the file and already have cached the ID then just
        // look it up from the cache
        if let file = filesByName[ fileName ] {
            self.fetchContents( forFile: file, completionHandler: completionHandler )
        } else {
            
            // otherwise we have to hit google drive to get the ID
            fetchFiles( name: fileName ) { [weak weakSelf = self] ( files, error ) in
                guard error == nil else {
                    completionHandler( nil, error )
                    return
                }
                
                // TODO - need to deal with multiple files
                if let file = files?.first {
                    // cache the ID so subsequent requests don't have to hit google drive again
                    weakSelf?.filesByName[ fileName ] = file
                    weakSelf?.fetchContents(forFile: file ) {( fileContents, error ) in
                        completionHandler( fileContents, error )
                    }
                } else {
                    completionHandler( nil, nil )
                }
            }
        }
    }
    
    /**
     Attempts to get the data for a file. If the file did not exist it should return nil for the contents.
     if the file exists it should return the contents. If the file is empty it should return an empty string
     not nil
     */
    func fetchContents( forFile file: GTLDriveFile, completionHandler : @escaping( _ fileContents:String?, _ error:NSError? ) -> Void ) {
        
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
                completionHandler( nil, NSError( domain: ErrorConstants.domain, code: 404, userInfo: [ "error" : errorMsg ] ) )
                return
            }
            
            completionHandler( String.init( data: responseData, encoding: String.Encoding.utf8 ), nil )
        }
    }
    
    private func fetchFiles( name: String, completionHandler: @escaping ([GTLDriveFile]?,NSError? ) -> Void) {
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
    
    func fileListComplete(ticket : GTLServiceTicket,
                                finishedWithObject response : GTLDriveFileList,
                                error : NSError?) {
        guard error == nil else {
            //            showAlert(title: "Error", message: error.localizedDescription)
            // if there's a completionHandler, call it, then set it to nil to avoid memory cycle
            self.fileListCompletionHandler?( nil, error )
            self.fileListCompletionHandler = nil
            return
        }
        
        let files = response.files as? [GTLDriveFile]
        
        self.fileListCompletionHandler?( files, nil )
        self.fileListCompletionHandler = nil
    }
    
    
    
}
