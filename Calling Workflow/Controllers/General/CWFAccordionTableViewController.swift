//
//  CWFAccordionTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 3/8/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

struct CWFAccordionVCElements {
    enum DataItemType {
        case Parent
        case Child
        case Calling
        case AddCalling
    }
    
    struct AccordionDataItem {
        var dataItem : Any
        var dataItemType : DataItemType
        var expanded : Bool
    }
}

class CWFAccordionTableViewController: CWFBaseTableViewController, CallingsTableViewControllerDelegate {
    
    // this is the calling with any changes that came back from the calling details controller
    var updatedCalling : Calling? {
        didSet {
            if let validCalling = updatedCalling {
                    if let prevVal = callingToDisplay, validCalling.position.multiplesAllowed, prevVal.id != validCalling.id {
                        // in the cases where we've done an update to LCR when multiples are allowed the calling ID may have changed so we need to remove the old one (by it's cwfID) before updating with the new one. If we simply update the new value with the ID it is not matched with the old calling without an ID, so it gets added as new rather than replacing
                        self.rootOrg = self.rootOrg?.updatedWith(callingToDelete: prevVal)
                    }
                //Updates the ui only. No updates to Drive or LCR
                self.rootOrg = self.rootOrg?.updatedWith(changedCalling: validCalling)
            }
            else {
                self.resetRootOrg()
            }
            self.tableView.reloadData()
        }
    }
    
    // this is the selected calling that the user tapped that will be passed to calling details.
    var callingToDisplay : Calling?
    
    func setReturnedCalling(calling: Calling) {
        self.updatedCalling = calling
    }
    
    // called by New Calling View Controller to update the ui only
    func setNewCalling(calling: Calling) {
        self.rootOrg = self.rootOrg?.updatedWith(newCalling: calling)
        self.tableView.reloadData()
    }
    
    //called by the Calling Details View Controller to update the ui only
    func setDeletedCalling(calling: Calling) {
        self.rootOrg = self.rootOrg?.updatedWith(callingToDelete: calling)
        tableView.reloadData()
    }
    
    private var dataSource : [CWFAccordionVCElements.AccordionDataItem] = []
    
    // the root org gets updated after the view is loaded (because we read it asynchronously - fresh from google drive) so after it gets updated we need to redraw 
    var rootOrg : Org? {
        didSet {
            setupView()
            tableView.reloadData()
        }
    }
    
    private var expandedParents : [CWFAccordionVCElements.AccordionDataItem] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false

        tableView.register(CWFAccordionRootTableViewCell.self, forCellReuseIdentifier: "rootCell")
        tableView.register(CWFAccordionChildTableViewCell.self, forCellReuseIdentifier: "childCell")
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filterButtonPressed))
       
        setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
     }

    // MARK: - Setup
    func setupView() {
        if rootOrg != nil {
            self.navigationItem.title = rootOrg?.orgName
            callingToDisplay = nil

            dataSource.removeAll( keepingCapacity: true )
            if (rootOrg?.callings != nil && (rootOrg?.callings.count)! > 0 && hasPermissionToEdit()) {
                let newDataItem = CWFAccordionVCElements.AccordionDataItem.init(dataItem: NSLocalizedString("Add Calling", comment: "select to add calling"), dataItemType: .AddCalling, expanded: true)
                dataSource.append(newDataItem)
            }
            
            for calling in (rootOrg?.callings)!{
                let newCallingDataItem = CWFAccordionVCElements.AccordionDataItem.init(dataItem: calling, dataItemType: .Calling, expanded: false)
                dataSource.append(newCallingDataItem)
            }
            
            for org in (rootOrg?.children)! {
                var newDataItem = CWFAccordionVCElements.AccordionDataItem.init(dataItem: org, dataItemType: .Parent, expanded: false)
                //check if it should be expanded
                let filteredArray = expandedParents.filter() {
                    let filterOrg = $0.dataItem as! Org
                    if filterOrg == org {
                        return true
                    } else {
                        return false
                    }
                }
                if filteredArray.count > 0 {
                    newDataItem.expanded = true
                    dataSource.append(newDataItem)
                    self.setupChildren(org: org)
                }
                else {
                    dataSource.append(newDataItem)
                }
            }
        }
    }
    
    func setupChildren(org: Org) {
        for child in org.children {
            let childDataItem = CWFAccordionVCElements.AccordionDataItem.init(dataItem: child, dataItemType: .Child, expanded: false)
            dataSource.append(childDataItem)
        }
        
        for calling in org.callings {
            let callingDataItem = CWFAccordionVCElements.AccordionDataItem.init(dataItem: calling, dataItemType: .Calling, expanded: false)
            dataSource.append(callingDataItem)
        }
    }
    
    func setupNewButton (button : UIButtonWithOrg?) {
        button?.removeTarget(nil, action: nil, for: .allEvents)
        if self.expandedParents.contains(where: {button?.buttonOrg == $0.dataItem as? Org}) {
            button?.isHidden = false
            button?.setBackgroundImage(UIImage.init(named: "add"), for: .normal)
            button?.setTitle(nil, for: .normal)
            button?.addTarget(self, action: #selector(addButtonPressed(sender:)), for: .touchUpInside)
        }
        else {
            button?.isHidden = true
        }
    }
    
    func setupWarningButton (button : UIButtonWithOrg?) {
        button?.removeTarget(self, action: #selector(addButtonPressed(sender:)), for: .touchUpInside)
        button?.isHidden = false
        button?.setBackgroundImage(nil, for: .normal)
        button?.setTitle("⚠️", for: .normal)
        button?.addTarget(self, action: #selector(orgDeletedWarningPressed(sender:)), for: .touchUpInside)
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let currentDataItem = self.dataSource[indexPath.row]
        switch currentDataItem.dataItemType {
        case CWFAccordionVCElements.DataItemType.Parent:
            let cell = tableView.dequeueReusableCell(withIdentifier: "rootCell", for: indexPath) as? CWFAccordionRootTableViewCell
            if let org = currentDataItem.dataItem as? Org {
                cell?.titleLabel.text = org.orgName
                cell?.newButton.buttonOrg = org
                if org.conflict == nil {
                    setupNewButton(button: cell?.newButton)
                }
                else {
                    setupWarningButton(button: cell?.newButton)
//                    cell?.newButton.isHidden = false
//                    cell?.newButton.setBackgroundImage(nil, for: .normal)
//                    cell?.newButton.setTitle("⚠️", for: .normal)
//                    cell?.newButton.addTarget(self, action: #selector(orgDeletedWarningPressed), for: .touchUpInside)
                }
            }
            return cell!
            
        case .AddCalling:
            let cell = tableView.dequeueReusableCell(withIdentifier: "rootCell", for: indexPath) as? CWFAccordionRootTableViewCell
            cell?.titleLabel.text = currentDataItem.dataItem as? String
            if rootOrg?.conflict == nil {
                cell?.newButton.isHidden = false
                cell?.newButton.addTarget(self, action: #selector(rootAddButtonPressed(sender:)), for: .touchUpInside)
            }
            return cell!
        
        case .Child:
            let cell = tableView.dequeueReusableCell(withIdentifier: "childCell", for: indexPath) as? CWFAccordionChildTableViewCell
            let child = (currentDataItem.dataItem as! Org)
            
            cell?.title.text = child.orgName
            
            return cell!
            
        default: //Calling
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "childCell", for: indexPath) as? CWFAccordionChildTableViewCell
            cell?.callingForCell = (currentDataItem.dataItem as! Calling)
                        
            cell?.title.text = cell?.callingForCell?.position.shortName
            if let existingId = cell?.callingForCell?.existingIndId {
                if let existingMember = appDelegate?.callingManager.getMemberWithId(memberId: existingId) {
                    if let nameString = existingMember.name {
                        cell?.second_subtitle.text = "\(nameString) (\(cell?.callingForCell?.existingMonthsInCalling ?? 0) months)"
                    }
                }
            }
            else {
                cell?.second_subtitle.text = "--"
                //cell?.second_subtitle.isHidden = true
            }
            
            if let proposedId = cell?.callingForCell?.proposedIndId {
                if let proposedMember = appDelegate?.callingManager.getMemberWithId(memberId: proposedId) {
                    if let nameString = proposedMember.name {
                        var displayText : String = nameString
                        if let proposedStatusDescription = cell?.callingForCell?.proposedStatus.description {
                            displayText = displayText.appending(" - \(proposedStatusDescription)")
                        }
                        cell?.first_subtitle.text = displayText
                    }
                }
            }
            else {
                cell?.first_subtitle.text = nil
            }
            
            if cell?.callingForCell?.conflict != nil {
                cell?.warningButton.isHidden = false
                cell?.warningButton.addTarget(self, action: #selector(warningButtonPressed), for: .touchUpInside)
            }
            else {
                cell?.warningButton.isHidden = true
            }
            
            return cell!
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataItem = dataSource[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        switch dataItem.dataItemType {
        case .Parent:
            if (dataItem.dataItem as! Org).children.count > 0 {
                let storyBorad = UIStoryboard.init(name: "Main", bundle: nil)
                let nextVC = storyBorad.instantiateViewController(withIdentifier: "OrgDetailTableViewController") as? OrgDetailTableViewController
                nextVC?.rootOrg = dataItem.dataItem as? Org
                self.navigationController?.pushViewController(nextVC!, animated: true)

            }
            else {
                if (dataItem.expanded) {
                    let cell = tableView.cellForRow(at: indexPath) as? CWFAccordionRootTableViewCell
                    if cell?.newButton.buttonOrg?.conflict == nil {
                        cell?.newButton.isHidden = true
                    }
                    collapseCell(indexPath: indexPath)
                }
                else {
                    let cell = tableView.cellForRow(at: indexPath) as? CWFAccordionRootTableViewCell
                    if let org = dataItem.dataItem as? Org {
                        if org.conflict == nil {
                            if (hasPermissionToEdit() && org.potentialNewPositions.count > 0) {
                                cell?.newButton.isHidden = false
                                cell?.newButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
                            }
                            cell?.newButton.buttonOrg = org
                        }
                        else {
                            cell?.newButton.isHidden = false
                            cell?.newButton.setBackgroundImage(nil, for: .normal)
                            cell?.newButton.setTitle("⚠️", for: .normal)
                            cell?.newButton.addTarget(self, action: #selector(orgDeletedWarningPressed), for: .touchUpInside)
                        }
                    }
                    expandCell(indexPath: indexPath)
                }
            }
        case .AddCalling:
            print("add calling tapped")
            
        case .Child:
            let storyBorad = UIStoryboard.init(name: "Main", bundle: nil)
            let nextVC = storyBorad.instantiateViewController(withIdentifier: "OrgDetailTableViewController") as? OrgDetailTableViewController
            nextVC?.rootOrg = dataItem.dataItem as? Org
            self.navigationController?.pushViewController(nextVC!, animated: true)
            

        default:
            let calling = dataItem.dataItem as? Calling
            let storyBoard = UIStoryboard.init(name: "Main", bundle:nil)
            let nextVC = storyBoard.instantiateViewController(withIdentifier: "CallingDetailsTableViewController") as? CallingDetailsTableViewController
            self.callingToDisplay = calling
            nextVC?.callingToDisplay = calling
            nextVC?.delegate = self
            nextVC?.titleBarString = rootOrg?.orgName
            self.navigationController?.pushViewController(nextVC!, animated: true)

        }
    }
    
    func isRootCell(indexPath: IndexPath) -> Bool {
        return true
    }

    class func getCellHeight () -> CGFloat {
        return 50.0
    }
    

    // MARK: - Event Handlers
    func collapseCell(indexPath: IndexPath) {
        var indexPaths : [IndexPath] = []
        var foundParent = false
        var currentIndex = indexPath.row + 1
        
        while !foundParent && currentIndex < dataSource.count {
            if dataSource[currentIndex].dataItemType == CWFAccordionVCElements.DataItemType.Parent {
                foundParent = true
            }
            else {
                indexPaths.append(IndexPath(row: currentIndex, section: 0))
                currentIndex = currentIndex + 1
            }
        }
        if (indexPaths.count > 0) {
            for i in 0...indexPaths.count - 1 {
                let index = indexPaths[indexPaths.count-(i+1)]
                dataSource.remove(at: index.row)
            }
        }
        dataSource[indexPath.row].expanded = false
        expandedParents = expandedParents.filter() {
            $0.dataItem as! Org != dataSource[indexPath.row].dataItem as! Org
        }
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: indexPaths, with: .fade)
        self.tableView.endUpdates()
    }
    
    func expandCell(indexPath: IndexPath) {
        
        let rootOrg = dataSource[indexPath.row].dataItem
        var i = 0
        var indexPaths : [IndexPath] = []
        for child in (rootOrg as! Org).children {
            let newDataItem = CWFAccordionVCElements.AccordionDataItem.init(dataItem: child, dataItemType: .Child, expanded: false)
            dataSource.insert(newDataItem, at: indexPath.row + i+1)
            indexPaths.append(IndexPath(row: indexPath.row + i+1, section: 0))
            i += 1
        }
        
        for calling in (rootOrg as! Org).callings {
            let newDataItem = CWFAccordionVCElements.AccordionDataItem.init(dataItem: calling, dataItemType: .Calling, expanded: false)
            dataSource.insert(newDataItem, at: indexPath.row + i+1)
            indexPaths.append(IndexPath(row: indexPath.row + i+1, section: 0))
            i += 1
        }
        
        dataSource[indexPath.row].expanded = true
        
        self.expandedParents.append(dataSource[indexPath.row])
        
        self.tableView.beginUpdates()
        
        tableView.insertRows(at: indexPaths, with: .fade)
        
        self.tableView.endUpdates()
    }

    func addButtonPressed(sender: UIButtonWithOrg) {
        
        let storyBoard = UIStoryboard.init(name: "Main", bundle:nil)
        let nextVC = storyBoard.instantiateViewController(withIdentifier: "NewCallingTableViewController") as? NewCallingTableViewController
        if let org = sender.buttonOrg {
            nextVC?.parentOrg = org
        }
        nextVC?.delegate = self
        self.navigationController?.pushViewController(nextVC!, animated: true)
    }
    
    func rootAddButtonPressed(sender: UIButton) {
        let storyBoard = UIStoryboard.init(name: "Main", bundle:nil)
        let nextVC = storyBoard.instantiateViewController(withIdentifier: "NewCallingTableViewController") as? NewCallingTableViewController
        nextVC?.parentOrg = self.rootOrg
        self.navigationController?.pushViewController(nextVC!, animated: true)
    }
    
    func resetRootOrg () {
        // grab the org out of memory without any potential changes
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let org = self.rootOrg, let unitOrg = appDelegate.callingManager.appDataOrg {
            self.rootOrg = unitOrg.getChildOrg(id: org.id )
        }
    }
    
    // MARK: - Filter
    func filterButtonPressed() {
        print("showFilter")
    }

    // MARK: - Permissions
    func hasPermissionToEdit() -> Bool {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let root = rootOrg, let rootId = rootOrg?.id, let unitLevelOrg = appDelegate.callingManager.unitLevelOrg(forSubOrg: rootId) {
            let authOrg = AuthorizableOrg(fromSubOrg: root, inUnitLevelOrg: unitLevelOrg)
            return appDelegate.callingManager.permissionMgr.isAuthorized(unitRoles: appDelegate.callingManager.userRoles, domain: .PotentialCalling, permission: .Update, targetData: authOrg)
        }
        else {
            return false
        }
    }
    
    //MARK: - Warning
    func warningButtonPressed() {
        print("warning pressed")
        let alert = UIAlertController(title: NSLocalizedString("Error", comment: ""), message: NSLocalizedString("There was an error uploading changes", comment: "error uploading message"), preferredStyle: .alert)
        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func orgDeletedWarningPressed(sender: UIButtonWithOrg) {
        var orgName : String = "Organization"
        //Get the name for the org with the conflict
        if let name = sender.buttonOrg?.orgName {
            orgName = name
        }
        var messageText = NSLocalizedString("\(orgName) no longer exists on lds.org and should be removed, but there are outstanding changes in some callings. If these proposed changes are no longer needed you can remove the organization with the 'Remove' button. If you want to review the callings with outstanding changes you can choose 'keep for now'\n", comment: "Deleted org error message")
        
        if let callingsWithChanges = sender.buttonOrg?.allInProcessCallings{
            var callingsString = ""
            if callingsWithChanges.count > 0 {
                callingsString += NSLocalizedString("\n Callings With Changes:\n", comment: "callings with changes")
            }
            var names : [String] = []
            for calling in callingsWithChanges {
                if let callingName = calling.position.mediumName {
                    names.append(callingName)
                }
            }
            for name in names {
                callingsString += "\n•  \(name)"
            }
            messageText += callingsString
        }
      
        //setup the attributed message so we can format the string left aligned
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        //set the message and its attributes
        let messageTextAttributed = NSMutableAttributedString(
            string: messageText,
            attributes: [
                NSParagraphStyleAttributeName: paragraphStyle,
                NSForegroundColorAttributeName: UIColor.black,
                NSFontAttributeName: UIFont.init(name: "Arial", size: 14)
            ])
        
        //Create the alert and add the message
        let alert = UIAlertController(title: NSLocalizedString("Missing Organization", comment: ""), message: "", preferredStyle: .alert)
        alert.setValue(messageTextAttributed, forKey: "attributedMessage")
        
        //add the actions to the alert
        let removeAction = UIAlertAction(title: NSLocalizedString("Remove", comment: "Remove"), style: UIAlertActionStyle.destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            if let org = sender.buttonOrg {
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                appDelegate?.callingManager.removeOrg(org: org) { success, error in
                    // if there was an error then we need to inform the user
                    if error != nil || !success {
                        let updateErrorAlert = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: NSLocalizedString("Unable to remove \(org.orgName). Please try again later.", comment: "Error removing org"), preferredStyle: .alert)
                        let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.cancel, handler: nil)
                        
                        //Add the buttons to the alert and display to the user.
                        updateErrorAlert.addAction(okAction)
                        
                        showAlertFromBackground(alert: updateErrorAlert, completion: nil)
                    }
                    self.tableView.reloadData()
                }
            }
        })
        let keepAction = UIAlertAction(title: NSLocalizedString("Keep For Now", comment: "Keep For Now"), style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(removeAction)
        alert.addAction(keepAction)
        self.present(alert, animated: true, completion: nil)
    }
}
