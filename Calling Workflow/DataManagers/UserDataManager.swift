//
//  UserDataManager.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/10/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

class UserDataManager : CWFBaseDataManager {
    
    
    func getUserData (completionHandler: @escaping ( _ orgData: String?, _ error: NSError? ) -> Void ){
        dataSource.fetchFileContents(fileName: getFileNameForCurrentUser()) { fileContents, error in
            guard error == nil else {
                print( "CallingDataManager.getOrgCallings() Error: " + error.debugDescription )
                completionHandler( nil, error )
                return
            }
            
            completionHandler( fileContents, nil )
        }
    }
    
    private func getFileNameForCurrentUser() -> String {
        return RemoteStorageConstants.dataFileName
    }
}
