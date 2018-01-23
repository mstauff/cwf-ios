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
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = organizationsToDisplay?[indexPath.row].orgName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        organizationSelected = organizationsToDisplay?[indexPath.row]
        self.performSegue(withIdentifier: "OrgList to OrgDetails", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        let nextView = segue.destination as? OrgDetailTableViewController
        appDelegate?.callingManager.reloadOrgData(forOrgId: organizationSelected!.id ) { (org, error) in
            guard error == nil else {
                // we couldn't get the latest org from google drive. We can use the one we have in memory rather than giving the user nothing
                nextView?.rootOrg = self.organizationSelected
                // todo - do we need a warning for the user?
                return
            }
            
            nextView?.rootOrg = org
        }
    }


}

