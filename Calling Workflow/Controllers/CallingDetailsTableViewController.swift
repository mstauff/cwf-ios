//
//  CallingDetailsTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/23/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class CallingDetailsTableViewController: CWFBaseTableViewController, MemberPickerDelegate, StatusPickerDelegate, UITextViewDelegate {
    
    //MARK: - Class Members
    var callingToDisplay : Calling? = nil {
        didSet {
            tableView.reloadData()
        }
    }
    
    var isDirty = false

    var originalCalling : Calling? = nil
    var memberDetailView : MemberInfoView? = nil
    
    var delegate : CallingsTableViewControllerDelegate?

    var debouncedNotesChange : Debouncer? = nil
    let textViewDebounceTime = 0.8
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        originalCalling = callingToDisplay

        navigationController?.title = callingToDisplay?.position.name
        let saveButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(saveAndReturn))
        navigationItem.setRightBarButton(saveButton, animated: true)
        
        tableView.register(LeftTitleRightLabelTableViewCell.self, forCellReuseIdentifier: "middleCell")
        tableView.register(OneRightTwoLeftTableViewCell.self, forCellReuseIdentifier: "oneRightTwoLeftCell")
        tableView.register(NotesTableViewCell.self, forCellReuseIdentifier: "noteCell")
        tableView.register(CWFButtonTableViewCell.self, forCellReuseIdentifier: "buttonCell")


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func willMove(toParentViewController parent: UIViewController?)
    {
        if parent == nil && isDirty {
            let saveAlert = UIAlertController(title: "Save Changes?", message: nil, preferredStyle: UIAlertControllerStyle.alert)
    
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                print("cancel")
            })
            let saveAction = UIAlertAction(title: "Save", style: UIAlertActionStyle.default, handler: {
                (alert: UIAlertAction!) -> Void in
                self.save()
                
            })
            saveAlert.addAction(cancelAction)
            saveAlert.addAction(saveAction)
            present(saveAlert, animated: true, completion: nil)

            print("dismiss")
            // Back btn Event handler
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
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
        case 3:
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
        case 0: // first section of the view is the title cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "dataSubdata", for: indexPath) as? DataSubdataTableViewCell

            cell?.mainLabel?.text = callingToDisplay?.position.name
            cell?.subLabel?.text = callingToDisplay?.parentOrg?.orgName
            
            return cell!
            
        case 1: // second section of the view is the information
            switch indexPath.row {
            // this is the currently called cell
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
                    else {
                        cell?.subdataLabel.text = nil
                    }
                }
                return cell!
                
            // this is the proposed individual cell
            case 1:
                let cell = tableView.dequeueReusableCell(withIdentifier: "middleCell", for: indexPath) as? LeftTitleRightLabelTableViewCell
                cell?.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                
                cell?.titleLabel.text = "Proposed:"
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                if (callingToDisplay?.proposedIndId) != nil {
                    let proposedMember = appDelegate?.callingManager.getMemberWithId(memberId: (callingToDisplay?.proposedIndId)!)
                    cell?.dataLabel.text = proposedMember?.name
                }
                else {
                    cell?.dataLabel.text = nil
                }
                return cell!
                
            // this is the status cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "middleCell", for: indexPath) as? LeftTitleRightLabelTableViewCell
                cell?.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                cell?.titleLabel.text = "Status:"
                
                if callingToDisplay?.proposedStatus != nil {
                    cell?.dataLabel.text = callingToDisplay?.proposedStatus.description
                }
                else {
                    cell?.dataLabel.text = "None"
                }
                return cell!

            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                return cell

            }
            
        case 2: // third section is the notes
            let cell = tableView.dequeueReusableCell(withIdentifier: "noteCell", for: indexPath) as? NotesTableViewCell
            if (callingToDisplay?.notes != nil || callingToDisplay?.notes != "") {
                cell?.noteTextView.text = callingToDisplay?.notes
            }
            cell?.noteTextView.delegate = self
            debouncedNotesChange = Debouncer(delay: textViewDebounceTime) { [weak self] in
                self?.updateNotes( cell?.noteTextView )
            }
            
            return cell!
            
        case 3: // fourth section is the button for the lcr functions.
            let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath) as? CWFButtonTableViewCell
            cell?.cellButton.setTitle("Calling Actions", for: UIControlState.normal)
            cell?.cellButton.addTarget(self, action: #selector(callingActionsButtonPressed), for: .touchUpInside)
            
            return cell!
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

            return cell
        }
    }
    
    // Tap handler for current/proposed/status options in calling details
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            tableView.deselectRow(at: indexPath, animated: false)

            switch indexPath.row {
            case 0:
                // Tapped the current holder - need to display the bottom sheet with contact info for the current calling holder if there is one
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                if let memberId = callingToDisplay?.existingIndId {
                    displayContactInfoForMember(member:  (appDelegate?.callingManager.getMemberCallings(forMemberId: memberId))!)
                }
            
            case 1:
                // Tapped the proposed calling holder. Transition to member picker to select a proposed person for this calling
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                let nextVC = storyboard.instantiateViewController(withIdentifier: "MemberPickerTableViewController") as? MemberPickerTableViewController
                
                // register as the delegate for selecting a member to update the proposed person
                nextVC?.delegate = self
                nextVC?.currentlySelectedId = callingToDisplay?.proposedIndId
                
                if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                    // setup the members to display in the picker, along with any filter options that should be preset based on the calling requirements
                    nextVC?.members = appDelegate.callingManager.memberCallings
                    let requirements = callingToDisplay?.position.metadata.requirements
                    let filterOptions = requirements != nil ? FilterOptions( fromPositionRequirements: requirements! ) : FilterOptions()
                    nextVC?.filterViewOptions = filterOptions
                }
                
                navigationController?.pushViewController(nextVC!, animated: true)
            
            case 2:
                // Tapped the status, show the selection screen for choosing a status
                let statusActionSheet = getStatusActionSheet(delegate: self)
                self.present(statusActionSheet, animated: true, completion: nil)

            default:
                print("Default to do nothing")
            }
            
        default:
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    
    //MARK: - Member Picker Delegate
    func setProspectiveMember(member: Member?) {
        isDirty = true
        if let setMember = member {
            self.callingToDisplay?.proposedIndId = setMember.individualId
        }
        else {
            self.callingToDisplay?.proposedIndId = nil
        }
    }
    
    
    //MARK: - Status Picker Delegate
    func setStatusFromPicker(status: CallingStatus) {
        isDirty = true
        self.callingToDisplay?.proposedStatus = status
        tableView.reloadData()
    }
    
    //MARK: - UI Text View Delegate
    func textViewDidChange(_ textView: UITextView) {
        debouncedNotesChange?.call()
    }
    
    func updateNotes(_ textView : UITextView?) {
        if let validTextView = textView {
            isDirty = true
            self.callingToDisplay?.notes = validTextView.text
        }
    }

    //MARK: - Show Contact Info
    func displayContactInfoForMember(member: MemberCallings) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let memberDetailView = storyboard.instantiateViewController(withIdentifier: "MemberInfoView") as? MemberInfoView
        memberDetailView?.memberToView = member
        memberDetailView?.modalPresentationStyle = .overCurrentContext
        
        self.present(memberDetailView!, animated: true, completion: nil)
    }
    
    
    func callingActionsButtonPressed() {
        print("buttonPressed")
        let actionSheet = UIAlertController(title: "LCR Actions", message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        let deleteAction = UIAlertAction(title: "Delete Calling in LCR", style: UIAlertActionStyle.default, handler:  {
            (alert: UIAlertAction!) -> Void in
            
            print("update pressed")
            
        })
        let releaseAction = UIAlertAction(title: "Release Current in LCR", style: UIAlertActionStyle.default, handler:  {
            (alert: UIAlertAction!) -> Void in
            
            print("update pressed")
            
        })
        let finalizeAction = UIAlertAction(title: "Finalize Change in LCR", style: UIAlertActionStyle.default, handler:  {
            (alert: UIAlertAction!) -> Void in
            
            print("update pressed")
            
        })
        actionSheet.addAction(finalizeAction)
        actionSheet.addAction(releaseAction)
        actionSheet.addAction(deleteAction)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func saveAndReturn() {
//
        //todo -- add save to calling service
        save()
        isDirty = false
        delegate?.setReturnedCalling(calling: self.callingToDisplay!)
        let _ = self.navigationController?.popViewController(animated: true)
        
    }
    
    func save() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            if (self.callingToDisplay != nil) {
                appDelegate.callingManager.updateCalling(updatedCalling: self.callingToDisplay!) {_,_ in }
            }
        }

    }
}
