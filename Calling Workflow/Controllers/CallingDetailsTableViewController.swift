//
//  CallingDetailsTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/23/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class CallingDetailsTableViewController: CWFBaseViewController, UITableViewDelegate, UITableViewDataSource, MemberPickerDelegate, StatusPickerDelegate, UITextViewDelegate {
    
    //MARK: - Class Members
    var callingToDisplay : Calling? = nil {
        didSet {
            tableView.reloadData()
        }
    }
    var tableView = UITableView(frame: CGRect.zero, style: .grouped)
    var isDirty = false

    var originalCalling : Calling? = nil
    var memberDetailView : MemberInfoView? = nil
    
    var delegate : CallingsTableViewControllerDelegate?

    var debouncedNotesChange : Debouncer? = nil
    let textViewDebounceTime = 0.8
    
    var spinnerView : CWFSpinnerView? = nil
    weak var callingMgr : CWFCallingManagerService? = nil
    var isEditable = false
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        
        guard let calling = callingToDisplay else {
            return
        }
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.callingMgr = appDelegate?.callingManager

        originalCalling = calling
        navigationItem.title = calling.position.name
//        navigationController?.title = calling.position.name
        
        setupNavBarButtons()
        
        // check permissions to see if we need to display options to edit the calling
        if let parentOrg = calling.parentOrg, let callingMgr = self.callingMgr, let unitLevelOrg = callingMgr.unitLevelOrg(forSubOrg: parentOrg.id) {
            
            let authOrg = AuthorizableOrg(fromSubOrg: parentOrg, inUnitLevelOrg: unitLevelOrg)
            if callingMgr.permissionMgr.isAuthorized(unitRoles: callingMgr.userRoles, domain: .PotentialCalling, permission: .Update, targetData: authOrg ) {
                let saveButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(saveAndReturn))
                navigationItem.setRightBarButton(saveButton, animated: true)
                isEditable = true
            }
            
        }
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Setup
    
    func setupNavBarButtons() {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.init(named: "backButton"), for: .normal)
        button.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
        button.frame = CGRect(x: 0, y: 0, width: 53.0, height: 31.0)
        
//        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 53.0, height: 31.0))
//        label.font = UIFont(name: "Arial", size: 15)
//        label.textColor = UIColor.white
//        label.backgroundColor = UIColor.clear
//        label.textAlignment = .center
//        label.text = NSLocalizedString("Back", comment: "back button")
//        button.addSubview(label)
        
        let backButton = UIBarButtonItem(customView: button)
        
//        let backButton = UIBarButtonItem(image: UIImage.init(named:"backButton"), style:.plain, target: self, action: #selector(backButtonPressed) )
//        backButton.title = NSLocalizedString("Back", comment: "back button")
        
        navigationItem.setLeftBarButton(backButton, animated: true)

    }
    
    func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 0.1))
        
        
        self.view.addSubview(self.tableView)
        
        let xConstraint = NSLayoutConstraint(item: tableView, attribute: .left, relatedBy: .equal, toItem: self.view, attribute: .left, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
        let wConstraint = NSLayoutConstraint(item: tableView, attribute: .right, relatedBy: .equal, toItem: self.view, attribute: .right, multiplier: 1, constant: 0)
        let hConstraint = NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        
        self.view.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
        
        // initi these UI elements before we do the guard check to make sure we have a calling
        tableView.register(DataSubdataTableViewCell.self, forCellReuseIdentifier: "dataSubdata")
        tableView.register(LeftTitleRightLabelTableViewCell.self, forCellReuseIdentifier: "middleCell")
        tableView.register(OneRightTwoLeftTableViewCell.self, forCellReuseIdentifier: "oneRightTwoLeftCell")
        tableView.register(NotesTableViewCell.self, forCellReuseIdentifier: "noteCell")
        tableView.register(CWFButtonTableViewCell.self, forCellReuseIdentifier: "buttonCell")

    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        //Return 2 sections if the user only can view 4 if they can edit
        if isEditable {
            return 4
        }
        else{
            return 2
        }
    }
    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:// we don't want a header on the first section
            return 0.1
        default:// all other sections get a 25 px header
            return 25
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch section {
        case 0:
            return UIView(frame: CGRect(x: 0, y: 0, width: 0.1, height: 0.1))
        default:
            return UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 25.0))
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:// we don't want a header on the first section
            return 0.1
        default:// all other sections get a 25 px header
            return 25
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // return number of rows per section
        switch section {
        case 0: // header information
            return 1
        case 1: // calling details. If the user has permition to edit return more rows
            if isEditable {
                return 3
            }
            else {
                return 1
            }
        case 2: // notes section. Only needs one row
            return 1
        case 3: // LCR button section, only one row needed
            return 1
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: //Top header Section
            return DataSubdataTableViewCell.calculateHeight()
        case 1: // calling details section
            switch indexPath.row {
            case 0:
                return OneRightTwoLeftTableViewCell.calculateHeight()
            default:
                return LeftTitleRightLabelTableViewCell.calculateHeight()
            }
        case 2: // notes section
            return 170
        default:
            return 44
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0: // first section of the view is the title cell
            let cell = tableView.dequeueReusableCell(withIdentifier: "dataSubdata", for: indexPath) as? DataSubdataTableViewCell

            cell?.mainLabel.text = callingToDisplay?.position.name
            cell?.subLabel.text = callingToDisplay?.parentOrg?.orgName
            
            return cell!
            
        case 1: // second section of the view is the information
            switch indexPath.row {
            // this is the currently called cell
            case 0:
                let cell = tableView.dequeueReusableCell(withIdentifier: "oneRightTwoLeftCell", for: indexPath) as? OneRightTwoLeftTableViewCell
                
                cell?.titleLabel.text = NSLocalizedString("Current:", comment: "Current:")
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                if (callingToDisplay?.existingIndId) != nil {
                    let currentMember = appDelegate?.callingManager.getMemberWithId(memberId: (callingToDisplay?.existingIndId)!)
                    cell?.dataLabel.text = currentMember?.name
                    if let months : Int = callingToDisplay?.existingMonthsInCalling {
                        cell?.subdataLabel.text = NSLocalizedString("\(months) months", comment: "months")
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
                
                let accessoryButton = UIButton(type: .contactAdd)
                accessoryButton.setImage(UIImage.init(named: "disclosureArrow"), for: .normal)
                accessoryButton.addTarget(self, action: #selector(memberPickerButtonPressed), for: .touchUpInside)
                cell?.accessoryView = accessoryButton
                
                cell?.titleLabel.text = NSLocalizedString("Proposed:", comment: "Proposed")
                // look up the name of the proposed individual
                if let proposedIndId = callingToDisplay?.proposedIndId {
                    let appDelegate = UIApplication.shared.delegate as? AppDelegate
                    let proposedMember = appDelegate?.callingManager.getMemberWithId(memberId: proposedIndId)
                    // check to see if the member meets the position requiremenst (show a warning if they don't)
                    let meetsRequirements = self.meetsPositionRequirements(ofCalling: callingToDisplay, member: proposedMember)
                    // todo - add warning icon if the user doesn't meet the requirements for the position
                    if !meetsRequirements {
                        cell?.warningButton.isHidden = false
                        cell?.warningButton.addTarget(self, action: #selector(warningButtonPressed), for: .touchUpInside)
                        
                    }
                    else {
                        cell?.warningButton.isHidden = true
                    }
                    
                    cell?.dataLabel.text = proposedMember?.name
                }
                else {
                    cell?.dataLabel.text = nil
                    cell?.warningButton.isHidden = true
                }
                
                return cell!
                
            // this is the status cell
            case 2:
                let cell = tableView.dequeueReusableCell(withIdentifier: "middleCell", for: indexPath) as? LeftTitleRightLabelTableViewCell
                cell?.accessoryType = UITableViewCellAccessoryType.disclosureIndicator
                let accessoryButton = UIButton(type: .contactAdd)
                accessoryButton.setImage(UIImage.init(named: "disclosureArrow"), for: .normal)
                accessoryButton.addTarget(self, action: #selector(tappedTheStatus), for: .touchUpInside)
                cell?.accessoryView = accessoryButton

                cell?.titleLabel.text = NSLocalizedString("Status:", comment: "Status")
                
                if callingToDisplay?.proposedStatus != CallingStatus.Unknown {
                    cell?.dataLabel.text = callingToDisplay?.proposedStatus.description
                }
                else {
                    cell?.dataLabel.text = NSLocalizedString("None", comment: "None")
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
            cell?.cellButton.setTitle(NSLocalizedString("Calling Actions", comment: "Calling Actions"), for: UIControlState.normal)
            cell?.cellButton.addTarget(self, action: #selector(callingActionsButtonPressed), for: .touchUpInside)
            
            return cell!
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

            return cell
        }
    }
    
    // Tap handler for current/proposed/status options in calling details
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        switch indexPath.section {
        case 1:
            tableView.deselectRow(at: indexPath, animated: false)

            switch indexPath.row {
            case 0:
                // Tapped the current holder - need to display the bottom sheet with contact info for the current calling holder if there is one
                if let memberId = callingToDisplay?.existingIndId {
                    displayContactInfoForMember(member:  (appDelegate?.callingManager.getMemberCallings(forMemberId: memberId))!)
                }
            
            case 1:
                // Tapped the proposed calling holder. Transition to member contact info
                if let proposedId = callingToDisplay?.proposedIndId, let memberCallings = appDelegate?.callingManager.getMemberCallings(forMemberId: proposedId){
                    self.displayContactInfoForMember(member: memberCallings)
                }
                // if no proposedId go to the memberPicker
                else {
                    memberPickerButtonPressed()
                }
                
            case 2:
                // Tapped the status, show the selection screen for choosing a status
                tappedTheStatus()

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
            
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            var statusArray : [CallingStatus] = CallingStatus.userValues
            if let excludeArray = appDelegate?.callingManager.statusToExcludeForUnit {
                statusArray = statusArray.filter() { !excludeArray.contains(item: $0) }
            }
            if let first = statusArray.first {
                self.callingToDisplay?.proposedStatus = first
            }

        }
        else {
            self.callingToDisplay?.proposedIndId = nil
            self.callingToDisplay?.proposedStatus = .None
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
    
    //MARK: - Actions
    func tappedTheStatus () {
        let statusActionSheet = getStatusActionSheet(delegate: self)
        self.present(statusActionSheet, animated: true, completion: nil)
    }
    
    func memberPickerButtonPressed() {
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
    }
    
    func backButtonPressed() {
        if isDirty {
            let saveAlert = UIAlertController(title: NSLocalizedString("Discard Changes?", comment: "discard"), message: NSLocalizedString("You have unsaved changes that will be discarded if you continue.", comment: "discard message"), preferredStyle: UIAlertControllerStyle.alert)
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Continue", comment: "Continue"), style: UIAlertActionStyle.destructive, handler: {
                (alert: UIAlertAction!) -> Void in
                self.navigationController?.popViewController(animated: true)
            })
            let saveAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.default, handler: {
                (alert: UIAlertAction!) -> Void in
                print("cancel")
                
            })
            saveAlert.addAction(cancelAction)
            saveAlert.addAction(saveAction)
            present(saveAlert, animated: true, completion: nil)
            
            print("dismiss")
            // Back btn Event handler
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }

    }
    
    func warningButtonPressed() {
        print("Warning Pressed")
        let warningAlert = UIAlertController(title: NSLocalizedString("Warning", comment: "Warning"), message: NSLocalizedString("You have selected a member that does not meet the requirements for the calling selected. You may not be able to save these changes in LCR", comment: "warning to user about position requirements"), preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.default, handler: {
            (alert: UIAlertAction!) -> Void in
            print("ok")
        })

        warningAlert.addAction(okAction)
        present(warningAlert, animated: true, completion: nil)
    }
    
    func callingActionsButtonPressed() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let callingMgr = appDelegate.callingManager
        
        let actionSheet = UIAlertController(title: NSLocalizedString("LCR Actions", comment: "LCR Actions"), message: nil, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        //Only add Update option if there is a proposed individual
        if callingToDisplay?.proposedIndId != nil {
            let finalizeAction = UIAlertAction(title: NSLocalizedString("Finalize Change in LCR", comment: "Finalize"), style: UIAlertActionStyle.default, handler:  {
                (alert: UIAlertAction!) -> Void in
                
                //String to use as warning message when updating LCR
                var alertMessage : String = ""
                
                //If existingIndividual add release info to the alert message, otherwise add start of sentence
                if let existingId = self.callingToDisplay?.existingIndId, let currentlyCalled = callingMgr.getMemberWithId(memberId: existingId), let currentName = currentlyCalled.name {
                    alertMessage.append(NSLocalizedString("This will release \(currentName) and ", comment: "Conf beginning"))
                }
                else {
                    alertMessage.append(NSLocalizedString("This ", comment: "this"))
                }
                
                //Add the rest of the message with proposed individual name
                if let proposedId = self.callingToDisplay?.proposedIndId, let currentlyProposed = callingMgr.getMemberWithId(memberId: proposedId),let proposedName = currentlyProposed.name, let callingName = self.callingToDisplay?.position.name {
                    alertMessage.append(NSLocalizedString("will record \(proposedName) as \(callingName) in LCR. This will make the change offical and public.", comment: "update calling message"))
                }
                //Initialize the alert with the message created
                let updateAlert = UIAlertController(title: NSLocalizedString("Update Calling", comment: "Update Calling"), message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
                
                //Init the action that will run when OK is pressed
                let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.destructive, handler: {
                    (alert: UIAlertAction!) -> Void in
                    self.save()
                    self.startSpinner()
                    //Call to callingManager to update calling
                    callingMgr.updateLCRCalling(updatedCalling: self.callingToDisplay!) { (calling, error) in
                        let err = error?.localizedDescription ?? "nil"
                        print("Release result: \(calling.debugDescription) - error: \(err)")
                        
                    }
                })
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.cancel, handler: {
                    (alert: UIAlertAction!) -> Void in
                    print("Cancelled")
                })
                
                updateAlert.addAction(okAction)
                updateAlert.addAction(cancelAction)
                
                self.present(updateAlert, animated: true, completion: nil)
            })

            actionSheet.addAction(finalizeAction)
        }
        if callingToDisplay?.existingIndId != nil {
            let releaseAction = UIAlertAction(title: NSLocalizedString("Release Current in LCR", comment: "release"), style: UIAlertActionStyle.default, handler:  {
                (alert: UIAlertAction!) -> Void in
                
                var releaseWarningString : String = ""
                if let existingId = self.callingToDisplay?.existingIndId, let currentlyCalled = callingMgr.getMemberWithId(memberId: existingId), let name = currentlyCalled.name, let callingName = self.callingToDisplay?.position.name {
                    releaseWarningString = NSLocalizedString("This will release \(name) as \(callingName) on lds.org (LCR). This will make the release public (it will appear in lds.org sites, LDS Tools, etc.). Generally this should only be done after the individual has been released in Sacrament Meeting. Do you want to record the release on lds.org?", comment: "Release Warning")
                }
                let releaseAlert = UIAlertController(title: NSLocalizedString("Release From Calling", comment: "Release"), message: releaseWarningString, preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.destructive, handler: {
                    (alert: UIAlertAction!) -> Void in
                    //call to calling manager to release individual
                    self.startSpinner()
                    callingMgr.releaseLCRCalling(callingToRelease: self.callingToDisplay!) { (success, error) in
                        let err = error?.localizedDescription ?? "nil"
                        print("Release result: \(success) - error: \(err)")
                        DispatchQueue.main.async {
                            self.returnToAux(saveFirst: false)
                        }
                    }
                })
                
                let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.cancel, handler: {
                    (alert: UIAlertAction!) -> Void in
                    print("Cancelled")
                })
                
                releaseAlert.addAction(okAction)
                releaseAlert.addAction(cancelAction)
                self.present(releaseAlert, animated: true, completion: nil)
            })

            actionSheet.addAction(releaseAction)

        }
        
        //init delete option for the action sheet
        let deleteAction = UIAlertAction(title: NSLocalizedString("Delete Calling in LCR", comment: "delete calling"), style: UIAlertActionStyle.default, handler:  {
            (alert: UIAlertAction!) -> Void in
            
            //Message to use for the action conformation alert
            var deleteWarningMessage : String = ""
            
            //If there is an existing individual display release warning.
            if let existingId = self.callingToDisplay?.existingIndId, let existingIndividual = callingMgr.getMemberWithId(memberId: existingId), let existingName = existingIndividual.name, let callingName = self.callingToDisplay?.position.name {
                deleteWarningMessage.append(NSLocalizedString("This will release \(existingName) as \(callingName) on lds.org (LCR) and remove the calling from ward lists. Do you want to record the release on lds.org?", comment: "existingIndDelete"))
            }
            else {
                if let callingName = self.callingToDisplay?.position.name{
                    deleteWarningMessage.append(NSLocalizedString("This will remove \(callingName) from ward lists and directiories. Do you want to continue?", comment: "deleteWarning"))
                }
            }

            //Init the alert using the warning string
            let deleteAlert = UIAlertController(title: NSLocalizedString("Delete Calling", comment: "delete"), message: deleteWarningMessage, preferredStyle: .alert)
            
            //Init the ok button and the callback to execute
            let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.destructive, handler: {
                (alert: UIAlertAction!) -> Void in
                self.startSpinner()
                callingMgr.deleteLCRCalling(callingToDelete: self.callingToDisplay!) { (success, error) in
                    let err = error?.localizedDescription ?? "nil"
                    print("Delete result: \(success) - error: \(err)")
                    DispatchQueue.main.async {
                        self.returnToAux(saveFirst: false)
                    }
        
                }
            })
            
            //Init the cancel button for the delete calling alert
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                print("Cancelled")
            })
            
            //Add the buttons to the alert and display to the user.
            deleteAlert.addAction(okAction)
            deleteAlert.addAction(cancelAction)
            
            self.present(deleteAlert, animated: true, completion: nil)

            print("Delete Current pressed")
            
        })

        actionSheet.addAction(deleteAction)

        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.cancel, handler: {
            (alert: UIAlertAction!) -> Void in
            print("Cancelled")
        })
        
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func saveAndReturn() {
        returnToAux(saveFirst: true)
    }
    
    func returnToAux( saveFirst : Bool ) {
        if saveFirst {
            save()
        }
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
    
    /** Check if a member meets the position requirements for a calling, if there are any. Returns true if the member meets the requirements, false if there's a violation
     */
    func meetsPositionRequirements( ofCalling calling: Calling?, member: Member? ) -> Bool {
        guard let calling = calling, let member = member else {
            return true
        }
        
        var result = true
        if let requirements = calling.position.metadata.requirements {
            // just use all the existing filter code to see perform the check, so we don't have to rewrite the validation code
            let positionRequirementsFilter = FilterOptions( fromPositionRequirements: requirements )
             result = positionRequirementsFilter.passesFilter(member: member)
        }
        return result
    }
    
    
    //MARK: - Spinner
    func startSpinner() {
        self.navigationItem.leftBarButtonItem?.isEnabled = false
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        let spinView = CWFSpinnerView(frame: CGRect.zero, title: NSLocalizedString("Updating", comment: "Updating") as NSString)
        
        self.view.addSubview(spinView)
        self.spinnerView = spinView
        
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==0)-[spinnerView]-(==0)-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: ["spinnerView": spinView])
        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[spinnerView]-|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: ["spinnerView": spinView])
        
        self.view.addConstraints(hConstraint)
        self.view.addConstraints(vConstraint)
    }
    
    func removeSpinner () {
        self.navigationItem.leftBarButtonItem?.isEnabled = true
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        self.spinnerView?.removeFromSuperview()
    }

    
    //MARK: - Permissions
    func hasPermissionToView() -> Bool {
        if let appDelegete = UIApplication.shared.delegate as? AppDelegate, let parentOrg = callingToDisplay?.parentOrg, let unitLevelOrg = appDelegete.callingManager.unitLevelOrg(forSubOrg: parentOrg.id) {
            let authOrg = AuthorizableOrg(fromSubOrg: parentOrg, inUnitLevelOrg: unitLevelOrg)
            
            return appDelegete.callingManager.permissionMgr.isAuthorized(unitRoles: appDelegete.callingManager.userRoles, domain: .PotentialCalling, permission: .Update, targetData: authOrg)
        }
        else {
            return false
        }
    }
}
