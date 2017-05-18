//
//  DirectoryTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/4/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class DirectoryTableViewController: CWFBaseTableViewController {

    var members : [Member]!

    override func viewDidLoad() {
        super.viewDidLoad()
        members = []
        setupData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationItem.title = "Directiory"
        setupData()
        tableView.reloadData()
    }
  
    // MARK: - Setup
    func setupData() {        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            members = appDelegate.callingManager.memberList
        }
    }
  
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: NameCallingProposedTableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NameCallingProposedTableViewCell
        let memberForCell = members[indexPath.row]
        
        cell.nameLabel?.text = memberForCell.name
        
        if memberForCell.currentCallings.count > 0 {
            cell.currentCallingLabel?.text = memberForCell.currentCallings[0].position.name
        }
        else {
            cell.currentCallingLabel?.text = nil
        }
       
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if let callingsString = appDelegate?.callingManager.getCallingsForMemberAsStringWithMonths(member: memberForCell) {
            cell.callingInProcessLabel?.text = callingsString
        }
        else {
            cell.callingInProcessLabel?.text = nil
        }
        
        return cell
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
