//
//  OrganizationTableViewController.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 9/21/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import UIKit

class OrganizationTableViewController: CWFBaseTableViewController {
    
    var organizationsToDisplay: [Org]?
    var organizationSelected: Org?

    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.navigationItem.title = appDelegate?.callingManager.appDataOrg?.orgName

        organizationsToDisplay = []
        organizationSelected = nil
        getOrgs()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        _ = appDelegate?.callingManager.loadOrgFromVC(orgToLoad: organizationSelected)
        let nextView = segue.destination as? OrgDetailTableViewController
        nextView?.rootOrg = organizationSelected
    }


}

