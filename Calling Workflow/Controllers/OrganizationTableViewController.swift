//
//  OrganizationTableViewController.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 9/21/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import UIKit

class OrganizationTableViewController: CWFBaseTableViewController {
        
    var organizationsToDisplay: [Org]?{
        didSet {
            tableView.reloadData()
        }
    }
    var organizationSelected: Org?


    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(CWFButtonTableViewCell.self, forCellReuseIdentifier: "ButtonCell")
        
        organizationsToDisplay = []
        organizationSelected = nil
        getOrgs()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.tabBarController?.title = appDelegate?.callingManager.appDataOrg?.orgName

        self.tabBarController?.navigationItem.rightBarButtonItem = nil

        if self.organizationsToDisplay == nil {
            organizationsToDisplay = []
        }

        getOrgs()
        tableView.reloadData()
    }
        
    // MARK: - Setup
    
    func getOrgs() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        organizationsToDisplay = appDelegate?.callingManager.appDataOrg?.children
    }
    
    // MARK: - Table View Delegate/DataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if organizationsToDisplay != nil {
            return organizationsToDisplay!.count
        }
        else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let orgs = organizationsToDisplay {
            let org = orgs[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? OrgTableViewCell
            cell?.titleLabel?.text = org.orgName
            
            if let _ = org.conflict {
                cell?.conflictButton.addTarget(self, action: #selector(conflictButtonPressed(sender:)), for: .touchUpInside)
                cell?.conflictButton.isHidden = false
                cell?.conflictButton.buttonOrg = org
            }
            else {
                cell?.conflictButton.isHidden = true
            }
            return cell!
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as? CWFButtonTableViewCell
            cell?.buttonTitle = NSLocalizedString("Retry Loading Data", comment: "retry loading from server")
            cell?.cellButton.addTarget(self, action: #selector(reloadData), for: .touchUpInside)

            return cell!
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        organizationSelected = organizationsToDisplay?[indexPath.row]
        self.performSegue(withIdentifier: "OrgList to OrgDetails", sender: nil)
    }
    
    //MARK: - Actions
    func conflictButtonPressed (sender : UIButtonWithOrg) {
        var orgName : String = "Organization"
        if let name = sender.buttonOrg?.orgName {
            orgName = name
        }
        let alert = UIAlertController(title: NSLocalizedString("Missing Organization", comment: ""), message: NSLocalizedString("\(orgName) no longer exists on lds.org and should be removed, but there are outstanding changes in some callings. If these proposed changes are no longer needed you can remove the organization with the 'Remove' button. If you want to review the callings with outstanding changes you can choose 'keep for now'", comment: "Deleted org error message"), preferredStyle: .alert)
        let removeAction = UIAlertAction(title: NSLocalizedString("Remove", comment: "Remove"), style: UIAlertActionStyle.destructive, handler: nil)
        let keepAction = UIAlertAction(title: NSLocalizedString("Keep For Now", comment: "Keep For Now"), style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(removeAction)
        alert.addAction(keepAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func reloadData () {
        if let rootController = self.tabBarController as? RootTabBarViewController {
            rootController.loadLdsAndAppData(useCache: true)
        }
    }
    
    //MARK: - Exit segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let orgId = organizationSelected?.id {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            let nextView = segue.destination as? OrgDetailTableViewController
            
            appDelegate?.callingManager.reloadOrgData(forOrgId: orgId ) { (org, error) in
                guard error == nil else {
                    // we couldn't get the latest org from google drive. We can use the one we have in memory rather than giving the user nothing. We'll try to pull from the calling manager service if we can as it will be most up to date (in case of failed update attempts, etc.). If we can't get that version then we use the version we have in the controller.
                    nextView?.rootOrg = appDelegate?.callingManager.appDataOrg?.getChildOrg(id: orgId ) ?? self.organizationSelected
                    // todo - do we need a warning for the user?
                    return
                }
                
                nextView?.rootOrg = org
            }

        }
    }


}

