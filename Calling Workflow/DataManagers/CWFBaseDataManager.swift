//
//  CWFBaseDataManager.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/10/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation

class CWFBaseDataManager {
    
    var dataSource : RemoteDataSource
    
    init(initDataSource : RemoteDataSource) {
        dataSource = initDataSource
    }
}
