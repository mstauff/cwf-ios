//
//  CallingsBaseTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/16/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class CallingsBaseTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barTintColor = UIColor.init(red: 0.07, green: 0.494, blue: 0.652, alpha: 1.0)
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white ]
    }
}
