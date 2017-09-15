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
    
    var userPermission : Permission? = nil
    
    var isDirty = false

    var originalCalling : Calling? = nil
    var memberDetailView : MemberInfoView? = nil
    
    var delegate : CallingsTableViewControllerDelegate?

    var debouncedNotesChange : Debouncer? = nil
    let textViewDebounceTime = 0.8
    
    var spinnerView : CWFSpinnerView? = nil
    
    //MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        originalCalling = callingToDisplay
        userPermission = Permission.Update

        navigationController?.title = callingToDisplay?.position.name
        
        let backButton = UIBarButtonItem(image: UIImage.init(named:"backButton"), style:.plain , target: self, action: #selector(backButtonPressed) )
        navigationItem.setLeftBarButton(backButton, animated: true)
        
        if userPermission != Permission.View {
            let saveButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(saveAndReturn))
            navigationItem.setRightBarButton(saveButton, animated: true)
        }
        
        tableView.register(LeftTitleRightLabelTableViewCell.self, forCellReuseIdentifier: "middleCell")
        tableView.register(OneRightTwoLeftTableViewCell.self, forCellReuseIdentifier: "oneRightTwoLeftCell")
        tableView.register(NotesTableViewCell.self, forCellReuseIdentifier: "noteCell")
        tableView.register(CWFButtonTableViewCell.self, forCellReuseIdentifier: "buttonCell")


    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if userPermission == Permission.View {
            return 2
        }
        else{
            return 4
        }
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
            if userPermission == Permission.View {
                return 1
            }
            else {
                return 3
            }
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
                accessoryButton.setImage(UIImage.imageFromSystemBarButton(.action), for: .normal)
                accessoryButton.addTarget(self, action: #selector(memberPickerButtonPressed), for: .touchUpInside)
                cell?.accessoryView = accessoryButton
                
                cell?.titleLabel.text = NSLocalizedString("Proposed:", comment: "Proposed")
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                
                if let proposedId = callingToDisplay?.proposedIndId {
                    let proposedMember = appDelegate?.callingManager.getMemberWithId(memberId:proposedId)
                    
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
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
                    self.save()
                    //call to calling manager to release individual
                    callingMgr.releaseLCRCalling(callingToRelease: self.callingToDisplay!) { (success, error) in
                        let err = error?.localizedDescription ?? "nil"
                        print("Release result: \(success) - error: \(err)")
                        
                        
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
                self.save()

                callingMgr.deleteLCRCalling(callingToDelete: self.callingToDisplay!) { (success, error) in
                    let err = error?.localizedDescription ?? "nil"
                    print("Release result: \(success) - error: \(err)")
        
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
    
    
    //MARK: - Spinner
    func startSpinner() {
        let spinView = CWFSpinnerView(frame: CGRect.zero, title: NSLocalizedString("Updating", comment: "Updating") as NSString)
        
        self.view.addSubview(spinView)
        self.spinnerView = spinView
        
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==0)-[spinnerView]-(==0)-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: ["spinnerView": spinView])
        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[spinnerView]-|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: ["spinnerView": spinView])
        
        self.view.addConstraints(hConstraint)
        self.view.addConstraints(vConstraint)
    }
    
    func removeSpinner () {
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
