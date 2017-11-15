//
//  ViewUtils.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/9/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

func getStatusActionSheet(delegate: StatusPickerDelegate?) -> UIAlertController {
   
    let actionSheet = UIAlertController(title: NSLocalizedString("Status", comment: ""), message: NSLocalizedString("Select calling status.", comment: "select status message"), preferredStyle: UIAlertControllerStyle.actionSheet)
    
    let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.cancel, handler: {
        (alert: UIAlertAction!) -> Void in
        print("Cancelled")
    })

    var statusArray = CallingStatus.userValues
    
    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
        statusArray = statusArray.filter() { !appDelegate.callingManager.statusToExcludeForUnit.contains($0) }
    }
    
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

func showAlertFromBackground(alert: UIAlertController, completion: (() -> Void)? ) {
    DispatchQueue.main.async {
        var rootViewController = UIApplication.shared.keyWindow?.rootViewController
        if let navigationController = rootViewController as? UINavigationController {
            rootViewController = navigationController.viewControllers.first
        }
        if let tabViewController = rootViewController as? UITabBarController {
            rootViewController = tabViewController.selectedViewController
        }

        rootViewController?.present(alert, animated: true, completion: completion)
    }
}

func CWFMarginFloat() -> CGFloat {
    return 15.0
}

