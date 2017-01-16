//
//  MemberDataManager.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/10/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

class MemberDataManager : CWFBaseDataManager {
    
    func getMemberData(forUnit : Org, completionHandler: @escaping ( _ orgData: String?, _ error: NSError? ) -> Void) {
        dataSource.fetchFileContents(fileName: getFileNameForMembersInOrg(org: forUnit)) { fileContents, error in
            guard error == nil else {
                print( "CallingDataManager.getOrgCallings() Error: " + error.debugDescription )
                completionHandler( nil, error )
                return
            }
            completionHandler(fileContents, nil)
        }

    }

    private func getFileNameForMembersInOrg( org: Org ) -> String {
        return RemoteStorageConstants.dataFileName
    }

}
