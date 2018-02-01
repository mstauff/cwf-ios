//
//  SettingsTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/9/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class SettingsTableViewController: CWFBaseTableViewController {
    
    var callingMgr : CWFCallingManagerService? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clearsSelectionOnViewWillAppear = true
        
        tabBarController?.title = NSLocalizedString("Settings", comment: "")
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.callingMgr = appDelegate?.callingManager
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
        // Only unit admins get the 3rd option (Unit status settings)
        let roles = callingMgr?.userRoles ?? []
        let hasEditStatusPermission = callingMgr?.permissionMgr.hasPermission(unitRoles: roles, domain: .UnitGoogleAccount, permission: .Update) ?? false
        let numSections = hasEditStatusPermission ? 3 : 2
        return numSections
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
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        switch indexPath.row {
        case 0:
            if let nextVC = storyboard.instantiateViewController(withIdentifier: "LDSLogin") as? LDSCredentialsTableViewController {
                if let reinitDelegate = self.tabBarController as? RootTabBarViewController {
                    nextVC.reinitDelegate = reinitDelegate
                }
                navigationController?.pushViewController(nextVC, animated: true)
            }
        case 1:
            if let nextVC = storyboard.instantiateViewController(withIdentifier: "FirstViewController") as? GoogleSettingsViewController {
                if let reinitDelegate = self.tabBarController as? RootTabBarViewController {
                    nextVC.reinitDelegate = reinitDelegate
                }
                navigationController?.pushViewController(nextVC, animated: true)
            }
        case 2:
            if let nextVC = storyboard.instantiateViewController(withIdentifier: "StatusSettings") as? StatusSettingsViewController {
                navigationController?.pushViewController(nextVC, animated: true)
            }
            
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
}
