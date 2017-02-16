 //
//  CallingsTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/4/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class CallingsTableViewController: CWFBaseTableViewController {
    
    var callingsToDisplay : [Calling] = []
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCallingsToDisplay()
        self.title = "Callings"

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        let addButton = UIBarButtonItem(title: "Add", style: UIBarButtonItemStyle.plain, target: self, action: nil)
        addButton.tintColor = UIColor.white
        self.navigationItem.rightBarButtonItem = addButton
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Setup
    
    func setupCallingsToDisplay() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if (appDelegate?.callingManager.ldsOrgUnit != nil) {
            callingsToDisplay = (appDelegate?.callingManager.ldsOrgUnit?.allOrgCallings)!
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return callingsToDisplay.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? NameCallingProposedTableViewCell
        
        let callingForRow = callingsToDisplay[indexPath.row]
        
        let newMember = Member(indId: 1, name: "John Doe", indPhone: "801-801-8018", housePhone: "8108108108", indEmail: "jd@email.com", householdEmail: "jd@email.com", streetAddress: [], birthdate: nil, gender: nil, priesthood: nil, callings: [])
        
        cell?.nameLabel.text = callingForRow.position.name
        
        cell?.currentCallingLabel.text = newMember.name
        
        cell?.callingInProcessLabel.text = callingForRow.proposedStatus.rawValue

        // Configure the cell...

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let nextVc = storyboard.instantiateViewController(withIdentifier: "CallingDetailsTableViewController") as? CallingDetailsTableViewController
        
        nextVc?.callingToDisplay = callingsToDisplay[indexPath.row]
        
        navigationController?.pushViewController(nextVc!, animated: true)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
