//
//  SettingsTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/9/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class SettingsTableViewController: CWFBaseTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = true
        
        tabBarController?.title = NSLocalizedString("Settings", comment: "")
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.title = NSLocalizedString("Settings", comment: "")
        self.tabBarController?.navigationItem.rightBarButtonItem = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = NSLocalizedString("LDS.org credentials", comment: "")
        case 1:
            cell.textLabel?.text = NSLocalizedString("Sharing/Sync Options", comment: "")
        case 2:
            cell.textLabel?.text = NSLocalizedString("Edit Calling Statuses", comment: "")
        case 3:
            cell.textLabel?.text = NSLocalizedString("Network Test", comment: "")
        default:
            cell.textLabel?.text = nil
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            performSegue(withIdentifier: "SettingsToLDSCredentials", sender: nil)
        case 1:
            performSegue(withIdentifier: "SettingsToNetTest", sender: nil)
        case 2:
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let nextVC = storyboard.instantiateViewController(withIdentifier: "StatusSettings") as? StatusSettingsViewController {
                navigationController?.pushViewController(nextVC, animated: true)
            }
            
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
