//
//  CallingsBaseTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/16/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class CWFBaseTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = UIColor.CWFNavBarTintColor
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white ]
        navigationController?.navigationBar.tintColor = UIColor.white
    }
}
