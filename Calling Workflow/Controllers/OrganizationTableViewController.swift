//
//  OrganizationTableViewController.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 9/21/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

import UIKit

class OrganizationTableViewController: CallingsBaseTableViewController {
    
    var organizationsToDisplay: [Org]?
    var organizationSelected: Org?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString("Organizations", comment: "")
        
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
        let emptyChildrenArray : [Org] = []
        let emptyCallingArray : [Calling] = []
        
        var org1 = Org(id: 01, orgTypeId: UnitLevelOrgType.Primary.rawValue, orgName: "Primary", displayOrder: 700, children: emptyChildrenArray, callings: emptyCallingArray)
        
        var childOrg1 = Org(id: 3843972, orgTypeId: UnitLevelOrgType.Other.rawValue, orgName: "CTR 7", displayOrder: 701, children: emptyChildrenArray, callings: emptyCallingArray)
        
        let childOrg2 = Org(id: 123456, orgTypeId: UnitLevelOrgType.Other.rawValue, orgName: "Cub Scouts", displayOrder: 702, children: emptyChildrenArray, callings: emptyCallingArray)
        
        childOrg1.callings.append(Calling(id: 2, currentIndId: nil, proposedIndId: nil, status: "Interviewed", position:Position(positionTypeId: 2, name: "Primary Worker CTR 7", hidden: false), notes: nil, editableByOrg: true, parentOrg: childOrg1))
        
        org1.children.append(childOrg1)
        org1.children.append(childOrg2)
        
        organizationsToDisplay?.append(org1)
        
 
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

