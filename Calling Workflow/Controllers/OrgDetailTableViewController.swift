//
//  OrgDetailTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/8/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit
import AccordionMenuSwift

class OrgDetailTableViewController: AccordionTableViewController {
    
    var organizationToDisplay : Org?
    
    // MARK: - Lyfecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = organizationToDisplay?.orgName
        if (organizationToDisplay != nil && (organizationToDisplay?.callings.count)! > 0) {
            //let addButton = UIBarButtonItem.init(image: UIImage(named: "add"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(addButtonPressed))
//            addButton.tintColor = UIColor.white
//            self.navigationItem.rightBarButtonItem = addButton
        }
        var items : [Parent] = []
        for suborg in (organizationToDisplay?.children)! {
            let tempItem = Parent(state: .collapsed, childs: getSubOrgNames(org: suborg), title: suborg.orgName)
            items.append(tempItem)
        }
        dataSource = items
        numberOfCellsExpanded = .one
        total = dataSource.count

        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func getSubOrgNames(org: Org) -> [String] {
        var strings: [String] = []
        for organization in (organizationToDisplay?.children)! {
            strings.append(organization.orgName)
        }
        return strings
    }

//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//
//    // MARK: - Table view data source
//
//    override func numberOfSections(in tableView: UITableView) -> Int {
//        var sectionCount = 1
//        
//        if ((organizationToDisplay?.callings.count)! > 0 && (organizationToDisplay?.children.count)! > 0) {
//            sectionCount += 1
//        }
//        
//        return sectionCount
//    }
//    
//    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        if ((organizationToDisplay?.callings.count)! > 0 && (organizationToDisplay?.children.count)! > 0) {
//
//            if section == 0 {
//                return "\((organizationToDisplay?.orgName)!) Callings"
//            }
//            else {
//                return "Suborganizations"
//            }
//        }
//        else {
//            return nil
//        }
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        
//        if (organizationToDisplay?.callings.count)! > 0 {
//            if section == 0 {
//                return (organizationToDisplay?.callings.count)!
//            }
//            else {
//                return (organizationToDisplay?.children.count)!
//            }
//        }
//        else {
//            return (organizationToDisplay?.children.count)!
//        }
//    }
//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
//        var nameString : String? = nil
//        if (organizationToDisplay?.callings.count)! > 0 {
//            if indexPath.section == 0 {
//                nameString = organizationToDisplay?.callings[indexPath.row].position.name
//            }
//            else {
//                nameString = organizationToDisplay?.children[indexPath.row].orgName
//            }
//        }
//        else {
//            nameString = organizationToDisplay?.children[indexPath.row].orgName
//        }
//        
//        cell.textLabel?.text = nameString
//        
//        return cell
//    }
//    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if (organizationToDisplay?.callings.count)! > 0 {
//            if indexPath.section == 0 {
//                let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                let nextVC = storyboard.instantiateViewController(withIdentifier: "CallingDetailsTableViewController") as? CallingDetailsTableViewController
//                nextVC?.callingToDisplay = organizationToDisplay?.callings[indexPath.row]
//                self.navigationController?.pushViewController(nextVC!, animated: true)
//            }
//            else {
//                let storyboard = UIStoryboard(name: "Main", bundle: nil)
//                let nextVC = storyboard.instantiateViewController(withIdentifier: "OrgDetailTableViewController") as? OrgDetailTableViewController
//                nextVC?.organizationToDisplay = organizationToDisplay?.children[indexPath.row]
//                self.navigationController?.pushViewController(nextVC!, animated: true)
//            }
//        }
//        else {
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            let nextVC = storyboard.instantiateViewController(withIdentifier: "OrgDetailTableViewController") as? OrgDetailTableViewController
//            nextVC?.organizationToDisplay = organizationToDisplay?.children[indexPath.row]
//            self.navigationController?.pushViewController(nextVC!, animated: true)
//        }
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
//    
//    func addButtonPressed() {
//        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
//        let nextVC = storyboard.instantiateViewController(withIdentifier: "NewCallingTableViewController") as? NewCallingTableViewController
//        nextVC?.parentOrg = organizationToDisplay
//        self.navigationController?.pushViewController(nextVC!, animated: true)
//    }

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
