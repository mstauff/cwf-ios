//
//  CallingDetailsTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/23/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class CallingDetailsTableViewController: CWFBaseTableViewController {
    
    var callingToDisplay : Calling? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.title = callingToDisplay?.position.name
        

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
        return 5
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 0
        default:
            return 25
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return nil
        case 1:
            return "Currently Called"
        case 2:
            return "Proposed"
        case 3:
            return "Status"
        case 4:
            return ""
        default:
            return nil
        }
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 60
        case 4:
            return 170
        default:
            return 44
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "dataSubdata", for: indexPath) as? DataSubdataTableViewCell

            cell?.mainLabel?.text = callingToDisplay?.position.name
            cell?.subLabel?.text = callingToDisplay?.parentOrg?.orgName
            
            return cell!
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            if (callingToDisplay?.currentIndId) != nil {
                let currentMember = appDelegate?.globalDataSource?.getMemberWithId(memberId: (callingToDisplay?.currentIndId)!)
                cell.textLabel?.text = currentMember?.name
            }
            return cell
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            if (callingToDisplay?.proposedIndId) != nil {
                let proposedMember = appDelegate?.globalDataSource?.getMemberWithId(memberId: (callingToDisplay?.proposedIndId)!)
                cell.textLabel?.text = proposedMember?.name
            }
            
            return cell

        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "statusCell", for: indexPath)
            if callingToDisplay?.status != nil {
                cell.textLabel?.text = callingToDisplay?.status
            }
            else {
                cell.textLabel?.text = "None"
            }
            return cell
            
        case 4:
            let cell = tableView.dequeueReusableCell(withIdentifier: "noteCell", for: indexPath)
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

            return cell
        }
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
