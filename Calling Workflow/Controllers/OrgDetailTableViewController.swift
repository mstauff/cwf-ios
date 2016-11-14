//
//  OrgDetailTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/8/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class OrgDetailTableViewController: UITableViewController {
    
    var organizationToDisplay : Org?
    
    // MARK: - Lyfecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = organizationToDisplay?.orgName

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        var sectionCount = 1
        
        if ((organizationToDisplay?.positions.count)! > 0) {
            sectionCount += 1
        }
        
        return sectionCount
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if (organizationToDisplay?.positions.count)! > 0 {

            if section == 0 {
                return "\(organizationToDisplay?.orgName) Callings"
            }
            else {
                return "Suborganizations"
            }
        }
        else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (organizationToDisplay?.positions.count)! > 0 {
            if section == 0 {
                return (organizationToDisplay?.positions.count)!
            }
            else {
                return (organizationToDisplay?.subOrgs[section-1].subOrgs.count)!
            }
        }
        else {
            return (organizationToDisplay?.subOrgs.count)!
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var nameString : String? = nil
        if (organizationToDisplay?.positions.count)! > 0 {
            if indexPath.section == 0 {
                nameString = organizationToDisplay?.positions[indexPath.row].name
            }
            else {
                nameString = organizationToDisplay?.subOrgs[indexPath.section - 1].orgName
            }
        }
        else {
            nameString = organizationToDisplay?.subOrgs[indexPath.section].orgName
        }
        
        cell.textLabel?.text = nameString
        
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
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
