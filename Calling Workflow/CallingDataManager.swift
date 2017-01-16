//
//  CallingDataManager.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 10/18/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import Foundation

class CallingDataManager : CWFBaseDataManager {

    let fileContents = "{ foo: 1, bar: 2}"
    
    // TODO - this should be an Org in the completionHandler, but maybe do string for now just for testing
    // need to rework remoteData to return jsonObject rather than string
    func getOrgCallings( org: Org, completionHandler: @escaping ( _ orgData: Data?, _ error: NSError? ) -> Void ) {
        dataSource.fetchFileContents(fileName: getFileNameForOrg(org: org)) { fileContents, error in
            guard error == nil else {
                print( "CallingDataManager.getOrgCallings() Error: " + error.debugDescription )
                completionHandler( nil, error )
                return
            }
            
            completionHandler( fileContents, nil )
        }
    }
    
    func updateOrgCallings( org: Org, completionHandler: @escaping ( _ error: NSError? ) -> Void ) {
        dataSource.addOrUpdateFile(fileName: getFileNameForOrg(org: org), fileContents: self.fileContents ) { _, error in
            completionHandler( error )
        }
    }
    
    private func getFileNameForOrg( org: Org ) -> String {
        // likely will end up being org-id.json. For now it's all one file
        return RemoteStorageConstants.dataFileName
    }
    
}
