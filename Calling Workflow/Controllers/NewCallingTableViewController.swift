//
//  NewCallingTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/9/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class NewCallingTableViewController: UITableViewController, MemberPickerDelegate, StatusPickerDelegate {
    
    var parentOrg : Org?
    var proposedMember : Member?
    var proposedStatus : CallingStatus?
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Add New Calling"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(saveAndDismiss))
        
        tableView.register(SingleFieldTableViewCell.self, forCellReuseIdentifier: "SingleFieldTableViewCell")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return 2
        case 2:
            return 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        
        case 0:
            return setupFirstSectionCell(indexPath: indexPath)
        case 1:
            return setupSecondSectionCell(indexPath: indexPath)
        case 2:
            return setupThirdSectionCell(indexPath: indexPath)
        
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            return cell

        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                tableView.deselectRow(at: indexPath, animated: true)

            default:
                tableView.deselectRow(at: indexPath, animated: true)
            }
        case 1:
            switch indexPath.row {
            case 0:
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                let nextVC = storyboard.instantiateViewController(withIdentifier: "MemberPickerTableViewController") as? MemberPickerTableViewController
                nextVC?.delegate = self
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    nextVC?.members = (appDelegate.callingManager?.memberList)!
                }
                navigationController?.pushViewController(nextVC!, animated: true)
            
            case 1:
                let actionSheet = getStatusActionSheet(delegate: self)
                self.present(actionSheet, animated: true, completion: nil)

            default:
                tableView.deselectRow(at: indexPath, animated: true)
            }
        default:
            tableView.deselectRow(at: indexPath, animated: true)

        }
    }

    // MARK: - Setup Sections
    
    func setupFirstSectionCell(indexPath : IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = "Select Calling"
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SingleFieldTableViewCell", for: indexPath) as? SingleFieldTableViewCell
            cell?.textField.text = "Calling Name"
            
            return cell!
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SingleFieldTableViewCell", for: indexPath) as? SingleFieldTableViewCell
            cell?.textField.text = "Custom"
            
            return cell!
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            
            return cell
        }
    }
    
    func setupSecondSectionCell(indexPath : IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            if (proposedMember == nil) {
                cell.textLabel?.text = "Select Person for Calling"
            }
            else {
                cell.textLabel?.text = proposedMember?.name
            }
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            if let statusString = proposedStatus?.rawValue{
                cell.textLabel?.text = statusString
            }
            else {
                cell.textLabel?.text = "Status"
            }
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            
            return cell
        }
    }
    
    func setupThirdSectionCell(indexPath : IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            cell.textLabel?.text = "Notes"
            
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            
            return cell
        }
    }

    // MARK: - MemberPickerDelegate
    func setProspectiveMember(member: Member) {
        proposedMember = member
        tableView.reloadData()
    }
    
    // MARK: - StatusPickerDelegate
    func setStatusFromPicker(status: CallingStatus) {
        proposedStatus = status
        tableView.reloadData()
    }
    
    // MARK: - Business
    
    func saveAndDismiss() {
        let saveAlert = UIAlertController(title: "Save Changes?", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("cancel")
        })
        let saveAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            //todo -- add save to calling service
            self.navigationController?.popViewController(animated: true)
            
        })
        saveAlert.addAction(cancelAction)
        saveAlert.addAction(saveAction)
        present(saveAlert, animated: true, completion: nil)
    }
    
    

}
