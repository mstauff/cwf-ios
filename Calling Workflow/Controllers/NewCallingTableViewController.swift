 //
//  NewCallingTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/9/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class NewCallingTableViewController: UITableViewController, MemberPickerDelegate, StatusPickerDelegate, CallingPickerTableViewControllerDelegate, UITextViewDelegate {
    
    var parentOrg : Org?
    
    var newCalling : Calling?
    
    var delegate : CallingsTableViewControllerDelegate?
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    var debouncedNotesChange : Debouncer? = nil
    let textViewDebounceTime = 0.8

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = parentOrg?.orgName//NSLocalizedString("Add New Calling", comment: "Add New Calling")
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.plain, target: self, action: #selector(saveNewCalling))
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        
        tableView.register(SingleFieldTableViewCell.self, forCellReuseIdentifier: "SingleFieldTableViewCell")
        tableView.register(NotesTableViewCell.self, forCellReuseIdentifier: "NoteTableViewCell")
        let positionMetadata = PositionMetadata()
        let newPostiton = Position(positionTypeId: 0, name: nil, hidden: false, multiplesAllowed: true, displayOrder: nil, metadata: positionMetadata)
        
        var newStatusArray = CallingStatus.userValues
        if let excludeStatuses = appDelegate?.callingManager.statusToExcludeForUnit {
            newStatusArray = CallingStatus.userValues.filter() { !excludeStatuses.contains(item: $0) }
        }
        
        // Set newCalling. If there is only one potential calling use that as the new calling
        if var newPositions = parentOrg?.potentialNewPositions {
            var tmpNewPositions : [Position] = []
            for position in newPositions {
                if position.metadata.positionTypeId == -1 {
                    let positionMD = appDelegate?.callingManager.positionMetadataMap[position.positionTypeId] ?? PositionMetadata()
                    var tmpPosition = position
                    tmpPosition.metadata = positionMD
                    tmpNewPositions.append(tmpPosition)
                }
                else {
                    tmpNewPositions.append(position)
                }
            }
            
            newPositions = tmpNewPositions
            
            switch newPositions.count {
            //if only one calling
            case 1:
//                let positionMD = appDelegate?.callingManager.positionMetadataMap[newPositions[0].positionTypeId]
//                let tmpPosition = 
                newCalling = Calling(id: nil, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: nil, status: newStatusArray.first, position: newPositions[0], notes: nil, parentOrg: parentOrg, cwfOnly: true)
            default:
                newCalling = Calling(id: nil, cwfId: nil, existingIndId: nil, existingStatus: nil, activeDate: nil, proposedIndId: nil, status: newStatusArray.first, position: newPostiton, notes: nil, parentOrg: parentOrg, cwfOnly: true)
            }
        }
        
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
                    
                    //add in the filter options
                    if let position = newCalling?.position, let metaData = appDelegate?.callingManager.positionMetadataMap[position.positionTypeId] {
                        let requirements = metaData.requirements
                        let filterOptions = requirements != nil ? FilterOptions( fromPositionRequirements: requirements! ) : FilterOptions()
                        nextVC?.filterViewOptions = filterOptions
                    }
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
                cell?.noteTextView.text = newCalling?.notes
            }
            cell?.noteTextView.delegate = self
            debouncedNotesChange = Debouncer(delay: textViewDebounceTime) { [weak self] in
                self?.updateNotes( cell?.noteTextView )
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
            //TODO add check that calling is set
            if (newCalling?.position.positionTypeId != 0) {
                navigationItem.rightBarButtonItem?.isEnabled = true
            }
            
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
       
        if var tmpCalling = self.newCalling  {
            if tmpCalling.position.metadata.positionTypeId == -1 {
                // if the metadata is not present we need to get it from the appDelegate
                var updatedPosition = tmpCalling.position
                updatedPosition.metadata = appDelegate?.callingManager.positionMetadataMap[tmpCalling.position.positionTypeId] ?? PositionMetadata()
                tmpCalling = Calling( tmpCalling, position: updatedPosition )
            }
            // we only need the name for reporting in cases where the update fails. Default to generic "that calling" if we can't get a name
            let callingName = tmpCalling.position.name ?? "that calling"
            appDelegate?.callingManager.addCalling(calling: tmpCalling)  {success, error in
                // if there was an error then we need to inform the user
                if error != nil || !success {
                    let updateErrorAlert = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: NSLocalizedString("Unable to add \(callingName). Please try again later.", comment: "Error saving changes"), preferredStyle: .alert)
                    let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.cancel, handler: nil)
                    
                    //Add the buttons to the alert and display to the user.
                    updateErrorAlert.addAction(okAction)
                    
                    showAlertFromBackground(alert: updateErrorAlert, completion: nil)
                    
                    // we have previously updated the calling VC with the change so it can be updated in the UI while the async update is happening. In this case, now that the update has failed we need to remove it
                    self.delegate?.setDeletedCalling(calling: tmpCalling)
                }
            }
            
            self.delegate?.setNewCalling(calling: tmpCalling)
            
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - CallingsTableViewControllerDelegate
    
    func setReturnedPostiton(position: Position) {
        newCalling = Calling(id: newCalling?.id, cwfId: newCalling?.cwfId, existingIndId: newCalling?.existingIndId, existingStatus: newCalling?.existingStatus, activeDate: newCalling?.activeDate, proposedIndId: newCalling?.proposedIndId, status: newCalling?.proposedStatus, position: position, notes: newCalling?.notes, parentOrg: newCalling?.parentOrg, cwfOnly: true)
        if (newCalling?.proposedIndId != nil) {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        tableView.reloadData()
    }
    
    //MARK: - UI Text View Delegate
    func textViewDidChange(_ textView: UITextView) {
        debouncedNotesChange?.call()
    }
    
    func updateNotes(_ textView : UITextView?) {
        if let validTextView = textView {
            self.newCalling?.notes = validTextView.text
        }
    }

}
