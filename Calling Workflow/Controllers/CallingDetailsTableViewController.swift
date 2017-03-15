//
//  CallingDetailsTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/23/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class CallingDetailsTableViewController: CWFBaseTableViewController, MemberPickerDelegate, StatusPickerDelegate {
    
    
    var callingToDisplay : Calling? = nil {
        didSet {
            tableView.reloadData()
        }
    }

    var originalCalling : Calling? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        originalCalling = callingToDisplay

        navigationController?.title = callingToDisplay?.position.name
        let saveButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(saveAndReturn))
        navigationItem.setRightBarButton(saveButton, animated: true)
        
        tableView.register(LeftTitleRightLabelTableViewCell.self, forCellReuseIdentifier: "middleCell")
        tableView.register(OneRightTwoLeftTableViewCell.self, forCellReuseIdentifier: "oneRightTwoLeftCell")
        tableView.register(NotesTableViewCell.self, forCellReuseIdentifier: "noteCell")

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
        switch section {
        case 0:
            return 0
        default:
            return 25
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 3
        case 2:
            return 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return DataSubdataTableViewCell.calculateHeight()
        case 1:
            switch indexPath.row {
            case 0:
                return OneRightTwoLeftTableViewCell.calculateHeight()
            default:
                return LeftTitleRightLabelTableViewCell.calculateHeight()
            }
        case 2:
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
            switch indexPath.row {
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "oneRightTwoLeftCell", for: indexPath) as? OneRightTwoLeftTableViewCell
                
                cell?.titleLabel.text = "Current:"
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                if (callingToDisplay?.existingIndId) != nil {
                    let currentMember = appDelegate?.callingManager.getMemberWithId(memberId: (callingToDisplay?.existingIndId)!)
                    cell?.dataLabel.text = currentMember?.name
                    if let months : Int = callingToDisplay?.existingMonthsInCalling {
                        cell?.subdataLabel.text = "\(months) months"
                    }
                }
                return cell!

            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "middleCell", for: indexPath) as? LeftTitleRightLabelTableViewCell
                cell?.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                
                cell?.titleLabel.text = "Proposed:"
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                if (callingToDisplay?.proposedIndId) != nil {
                    let proposedMember = appDelegate?.callingManager.getMemberWithId(memberId: (callingToDisplay?.proposedIndId)!)
                    cell?.dataLabel.text = proposedMember?.name
                }
                return cell!

            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "middleCell", for: indexPath) as? LeftTitleRightLabelTableViewCell
                cell?.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                cell?.titleLabel.text = "Status:"
                
                if callingToDisplay?.proposedStatus != nil {
                    cell?.dataLabel.text = callingToDisplay?.proposedStatus.rawValue
                }
                else {
                    cell?.dataLabel.text = "None"
                }
                return cell!

            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                return cell

            }
            
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "noteCell", for: indexPath) as? NotesTableViewCell
            if (callingToDisplay?.notes != nil || callingToDisplay?.notes != "") {
                cell?.noteTextView.text = callingToDisplay?.notes
            }
            
            return cell!
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            
            case 1:
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                let nextVC = storyboard.instantiateViewController(withIdentifier: "MemberPickerTableViewController") as? MemberPickerTableViewController
                nextVC?.delegate = self
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    nextVC?.members = appDelegate.callingManager.memberList
                }
                navigationController?.pushViewController(nextVC!, animated: true)
            
            case 2:
                let statusActionSheet = getStatusActionSheet(delegate: self)
                self.present(statusActionSheet, animated: true, completion: nil)
                
            default:
                tableView.deselectRow(at: indexPath, animated: false)

            }
            
        default:
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    func setProspectiveMember(member: Member) {
        self.callingToDisplay?.proposedIndId = member.individualId
    }
    
    func setStatusFromPicker(status: CallingStatus) {
        self.callingToDisplay?.proposedStatus = status
        tableView.reloadData()
    }
    
    func saveAndReturn() {
        let saveAlert = UIAlertController(title: "Save Changes?", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("cancel")
        })
        let saveAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: {
            (alert: UIAlertAction!) -> Void in
            
            //todo -- add save to calling service
            if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                if (self.callingToDisplay != nil) {
                    appDelegate.callingManager.updateCalling(originalCalling: self.originalCalling!, updatedCalling: self.callingToDisplay!) {_,_ in }
                }
            }

            let _ = self.navigationController?.popViewController(animated: true)

        })
        saveAlert.addAction(cancelAction)
        saveAlert.addAction(saveAction)
        present(saveAlert, animated: true, completion: nil)
    }
}
