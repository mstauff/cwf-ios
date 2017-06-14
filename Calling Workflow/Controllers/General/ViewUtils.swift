//
//  ViewUtils.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/9/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

func getStatusActionSheet(delegate: StatusPickerDelegate?) -> UIAlertController {
   
    let actionSheet = UIAlertController(title: "Status", message: "Select calling status.", preferredStyle: UIAlertControllerStyle.actionSheet)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
        (alert: UIAlertAction!) -> Void in
        print("Cancelled")
    })
    
    let statusArray = CallingStatus.userValues
    
    for status in statusArray {
        let statusAction = UIAlertAction(title: status.description, style: UIAlertActionStyle.default, handler:  {
            (alert: UIAlertAction!) -> Void in
            if (delegate != nil){
                delegate?.setStatusFromPicker(status: status)
            }
        })
        actionSheet.addAction(statusAction)
    }
    
    actionSheet.addAction(cancelAction)
    return actionSheet
}
