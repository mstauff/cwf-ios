//
//  NewCallingTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/9/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class NewCallingTableViewController: UITableViewController, MemberPickerDelegate, StatusPickerDelegate, CallingPickerTableViewControllerDelegate {
    
    var parentOrg : Org?
    
    var newCalling : Calling?
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = NSLocalizedString("Add New Calling", comment: "Add New Calling")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(saveNewCalling))
        
        tableView.register(SingleFieldTableViewCell.self, forCellReuseIdentifier: "SingleFieldTableViewCell")
        tableView.register(NotesTableViewCell.self, forCellReuseIdentifier: "NoteTableViewCell")
        let positionMetadata = PositionMetadata()
        let newPostiton = Position(positionTypeId: 0, name: nil, hidden: false, multiplesAllowed: true, displayOrder: nil, metadata: positionMetadata)
        
        var newStatusArray = CallingStatus.userValues
        if let excludeStatuses = appDelegate?.callingManager.statusToExcludeForUnit {
            newStatusArray = CallingStatus.userValues.filter() { !excludeStatuses.contains(item: $0) }
        }
                
        newCalling = Calling(id: nil, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: nil, status: newStatusArray.first, position: newPostiton, notes: nil, parentOrg: parentOrg)
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
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 2
        case 2:
            return 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 44
        case 1:
            return 44
        case 2:
            return 150
            
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
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                let nextVC = storyboard.instantiateViewController(withIdentifier: "CallingPickerViewController") as? CallingPickerViewController
                if let org = parentOrg {
                    nextVC?.org = org
                }
                nextVC?.delegate = self
                navigationController?.pushViewController(nextVC!, animated: true)

            default:
                tableView.deselectRow(at: indexPath, animated: true)
            }
        case 1:
            switch indexPath.row {
            case 0:
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                let nextVC = storyboard.instantiateViewController(withIdentifier: "MemberPickerTableViewController") as? MemberPickerTableViewController
                nextVC?.delegate = self
                if appDelegate != nil {
                    nextVC?.members = (appDelegate?.callingManager.memberCallings)!
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
            if newCalling != nil && newCalling?.position.name != nil && newCalling?.position.name != "" {
                cell.textLabel?.text = newCalling?.position.name
            }
            else {
                cell.textLabel?.text = NSLocalizedString("Select Calling", comment: "Select Calling")
            }
            
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SingleFieldTableViewCell", for: indexPath) as? SingleFieldTableViewCell
            cell?.textField.text = NSLocalizedString("Calling Name", comment: "Calling Name")
            
            return cell!
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SingleFieldTableViewCell", for: indexPath) as? SingleFieldTableViewCell
            cell?.textField.text = NSLocalizedString("Custom", comment: "Custom")
            
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
            if (newCalling?.proposedIndId == nil) {
                
                cell.textLabel?.text = NSLocalizedString("Select Person for Calling", comment: "")
            }
            else {
                let proposedMember = appDelegate?.callingManager.getMemberWithId(memberId: (newCalling?.proposedIndId)!)
                cell.textLabel?.text = proposedMember?.name
            }
            cell.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
            
            return cell
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            if let statusString = newCalling?.proposedStatus.description{
                cell.textLabel?.text = statusString
            }
            else {
                cell.textLabel?.text = NSLocalizedString("Status", comment: "")
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoteTableViewCell", for: indexPath) as? NotesTableViewCell

            if (newCalling?.notes != nil || newCalling?.notes != "") {
                cell?.noteTextView.text = NSLocalizedString("Notes", comment: "")
            }
            else {
                cell?.noteTextView.text = newCalling?.notes
            }

            return cell!
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
            
            return cell
        }
    }

    // MARK: - MemberPickerDelegate
    func setProspectiveMember(member: Member?) {
        if let setMember = member {
            newCalling?.proposedIndId = setMember.individualId
        }
        else {
            newCalling?.proposedIndId = nil
        }
        tableView.reloadData()
    }
    
    // MARK: - StatusPickerDelegate
    func setStatusFromPicker(status: CallingStatus) {
        newCalling?.proposedStatus = status
        tableView.reloadData()
    }
    
    // MARK: - Business
    
    func saveNewCalling() {
       
        if (self.newCalling != nil) {
                appDelegate?.callingManager.addCalling(calling: self.newCalling!) {_,_ in }
            
        }
        
        let _ = self.navigationController?.popViewController(animated: true)

        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - CallingsTableViewControllerDelegate
    
    func setReturnedPostiton(position: Position) {
        newCalling = Calling(id: newCalling?.id, cwfId: newCalling?.cwfId, existingIndId: newCalling?.existingIndId, existingStatus: newCalling?.existingStatus, activeDate: newCalling?.activeDate, proposedIndId: newCalling?.proposedIndId, status: newCalling?.proposedStatus, position: position, notes: newCalling?.notes, parentOrg: newCalling?.parentOrg)
        tableView.reloadData()
    }

}
