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
    
    // MARK: - Setup
    
    func setupCallingsToDisplay() {
        
        let position = Position(positionTypeId: 2, name: "Primary Worker CTR 7", hidden: false)
        let calling1 = Calling(id: 01, currentIndId: 01, proposedIndId: 02, status: "Interviewed", position: position, notes: nil, editableByOrg: true, parentOrg: nil)
        callingsToDisplay.append(calling1)
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
        
        cell?.callingInProcessLabel.text = callingForRow.status

        // Configure the cell...

        return cell!
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
