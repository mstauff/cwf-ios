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
        
        cell.nameLabel?.text = memberForCell.name
        
        if memberForCell.currentCallings.count > 0 {
            cell.currentCallingLabel?.text = memberForCell.currentCallings[0].position.name
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
        
        let position = Position(positionTypeId: 01, name: "Sunbeam Teacher", hidden: false, multiplesAllowed: true, metadata : PositionMetadata())
        
        
        let calling = Calling(id: 01, cwfId: nil, existingIndId: 1, existingStatus: .Active, activeDate: nil, proposedIndId: 123, status: CallingStatus(rawValue: "CONSIDERING"), position: position, notes: nil, editableByOrg: true, parentOrg: nil)
        
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
