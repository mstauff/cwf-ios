//
//  DirectoryTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/4/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class DirectoryTableViewController: UITableViewController {

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
    
  
    // MARK: - Setup
    func setupData() {
        let newMember = Member(indId: 1, name: "John Doe", indPhone: "801-801-8018", housePhone: "8108108108", email: "jd@email.com", currentCall: "Sunbeam Teacher")
        members.append(newMember)
        
        let newMember2 = Member(indId: 123, name: "Adams, Steve", indPhone: "555-433-2222", housePhone: "555-433-1111", email: "steve@adams.com", currentCall: nil)
        members.append(newMember2)
    }
  
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return members.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: NameCallingProposedTableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NameCallingProposedTableViewCell
        let memberForCell = members[indexPath.row]
        
        cell.nameLabel?.text = memberForCell.formattedName
        
        if memberForCell.currentCalling != nil {
            cell.currentCallingLabel?.text = memberForCell.currentCalling
        }
        else {
            cell.currentCallingLabel?.text = nil
        }
        
        if let calling = getCallingForMemberWithId(memberId: memberForCell.individualId) {
            cell.callingInProcessLabel?.text = calling.position.name
        }
        else {
            cell.callingInProcessLabel?.text = nil
        }
        
        return cell
    }
    

    // MARK: - GetData
    
    func getCallingForMemberWithId(memberId: Int64) -> Calling? {
        
        let position = Position(id: 01, positionTypeId: 01, name: "Sunbeam Teacher", description: nil, hidden: false)
        
        
        let calling = Calling(id: 01, currentIndId: 1, proposedIndId: 123, status: "CONSIDERING", position: position, notes: nil, editableByOrg: true, parentOrg: nil)
        
        if calling.proposedIndId == memberId {
            return calling
        }
        else {
            return nil
        }
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
