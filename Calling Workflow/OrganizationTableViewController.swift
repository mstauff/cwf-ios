//
//  OrganizationTableViewController.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 9/21/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import UIKit

class OrganizationTableViewController: UITableViewController {
    
    var organizationsToDisplay: [Org]?
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
    
    // MARK: - Setup
    
    func getOrgs() {
        let orgTypes = [OrgType(id: 7428354, name: "Primary"), OrgType(id: 2, name: "Young Mens"), OrgType(id: 3, name: "Young Womens")]
        
        var org1 = Org(orgType: orgTypes[0], orgName: orgTypes[0].name)
        
        var subOrg1 = Org(orgType: OrgType(id: 38432972, name:"CTR 7"), orgName: "CTR 7")
        subOrg1.positions.append(Position(id: 1, positionTypeId: 2, name: "Primary Worker CTR 7", description: "Primary Teacher", org: org1))
        org1.subOrgs.append(subOrg1)
        
        organizationsToDisplay?.append(org1)
        
        organizationsToDisplay?.append( Org(orgType: orgTypes[1], orgName: orgTypes[1].name) )
        organizationsToDisplay?.append( Org(orgType: orgTypes[2], orgName: orgTypes[2].name) )
        
    }
    
    // MARK: - Table View Delegate/DataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return organizationsToDisplay!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = organizationsToDisplay?[indexPath.row].orgName
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        organizationSelected = organizationsToDisplay?[indexPath.row]
        self.performSegue(withIdentifier: "OrgList to OrgDetails", sender: nil)
        print("selected \(indexPath.section) : \(indexPath.row)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let nextView = segue.destination as? OrgDetailTableViewController
        nextView?.organizationToDisplay = organizationSelected
    }


}

