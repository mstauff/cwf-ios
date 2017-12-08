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
                self.rootOrg = self.rootOrg?.updatedWith(changedCalling: validCalling)
            }
        }
    }
    
    // this is the selected calling that the user tapped that will be passed to calling details.
    var callingToDisplay : Calling?
    
    func setReturnedCalling(calling: Calling) {
        self.updatedCalling = calling
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
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
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
                if self.expandedParents.contains(where: {org == $0.dataItem as? Org}) {
                    cell?.newButton.isHidden = false
                }
                else {
                    cell?.newButton.isHidden = true
                }
            }
            return cell!
            
        case .AddCalling:
            let cell = tableView.dequeueReusableCell(withIdentifier: "rootCell", for: indexPath) as? CWFAccordionRootTableViewCell
            cell?.titleLabel.text = currentDataItem.dataItem as? String
            cell?.newButton.isHidden = false
            cell?.newButton.addTarget(self, action: #selector(rootAddButtonPressed(sender:)), for: .touchUpInside)
            return cell!
        
        case .Child:
            let cell = tableView.dequeueReusableCell(withIdentifier: "childCell", for: indexPath) as? CWFAccordionChildTableViewCell
            let child = (currentDataItem.dataItem as! Org)
            
            cell?.title.text = child.orgName
            
            return cell!
            
        case .Calling:
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
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "childCell", for: indexPath) as? CWFAccordionChildTableViewCell
            
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
                    cell?.newButton.isHidden = true
                    collapseCell(indexPath: indexPath)
                }
                else {
                    let cell = tableView.cellForRow(at: indexPath) as? CWFAccordionRootTableViewCell
                    if (hasPermissionToEdit()) {
                        cell?.newButton.isHidden = false
                    }
                    cell?.newButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
                    if let org = dataItem.dataItem as? Org {
                        cell?.newButton.buttonOrg = org
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

    func addButtonPressed(sender: AccordionUIButton) {
        
        let storyBoard = UIStoryboard.init(name: "Main", bundle:nil)
        let nextVC = storyBoard.instantiateViewController(withIdentifier: "NewCallingTableViewController") as? NewCallingTableViewController
        if let org = sender.buttonOrg {
            nextVC?.parentOrg = org
        }
        self.navigationController?.pushViewController(nextVC!, animated: true)
    }
    
    func rootAddButtonPressed(sender: UIButton) {
        let storyBoard = UIStoryboard.init(name: "Main", bundle:nil)
        let nextVC = storyBoard.instantiateViewController(withIdentifier: "NewCallingTableViewController") as? NewCallingTableViewController
        nextVC?.parentOrg = self.rootOrg
        self.navigationController?.pushViewController(nextVC!, animated: true)
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
}
