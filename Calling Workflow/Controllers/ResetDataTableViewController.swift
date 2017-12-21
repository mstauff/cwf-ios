//
//  ResetDataTableViewController.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 12/13/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

struct ResetDataVCEnums {
    enum SectionTypes : Int {
        case Orgs
        case Actions
        
        static let allValues = [Orgs, Actions]
        
        static var count : Int {
            get {
                return allValues.count
            }
        }
    }
}

class ResetDataTableViewController: CWFBaseTableViewController, AlertBox, ProcessingSpinner {

    let orgCellId = "orgResetDataTableViewCell"
    let resetBtnCellId = "resetBtnTableViewCell"
    var callingMgr : CWFCallingManagerService? = nil
    var orgs : [Org] = []
    var selectedOrgIds : [Int64] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // get org names for each row
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            callingMgr = appDelegate.callingManager
            if let childOrgs = callingMgr?.appDataOrg?.children {
                orgs = childOrgs
            }
        }
        tableView.register(MultiSelectTableViewCell.self, forCellReuseIdentifier: orgCellId)
        tableView.register(CWFButtonTableViewCell.self, forCellReuseIdentifier: resetBtnCellId)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // 2 sections - the list of orgs, then the reset button
        return ResetDataVCEnums.SectionTypes.allValues.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numRows = 0
        switch section {
        case ResetDataVCEnums.SectionTypes.Orgs.rawValue:
            // first section has a row for each org
            numRows = orgs.count
        default:
            // last section has a single row for a button
            numRows = 1
        }
        return numRows
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case ResetDataVCEnums.SectionTypes.Orgs.rawValue:
            // org rows are a cell with the org name and a checkbox when selected
            let cell = tableView.dequeueReusableCell(withIdentifier: orgCellId, for: indexPath)
            if let orgName = orgs[safe: indexPath.row]?.orgName {
                cell.textLabel?.text = orgName
            }
            return cell
        default:
            // other section is just a single reset data button
            let cell = tableView.dequeueReusableCell(withIdentifier: resetBtnCellId, for: indexPath) as? CWFButtonTableViewCell
            cell?.buttonTitle = NSLocalizedString("Reset Data", comment: "Reset data in google drive")
            cell?.cellButton.addTarget(self, action: #selector(warnDataReset), for: .touchUpInside)
            return cell!
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == ResetDataVCEnums.SectionTypes.Orgs.rawValue {
            // by default the cell will stay highlighted gray - we want to dismiss that after the selection
            tableView.deselectRow(at: indexPath, animated: true)
            if let cell = tableView.cellForRow(at: indexPath) as? MultiSelectTableViewCell, let org = orgs[safe: indexPath.row] {
                // pass the event on to the cell so it can maintain its' own state (checked or not)
                cell.cellPressed()
                // In addition to the button state we need to capture which orgs have been selected
                if cell.isChecked {
                    selectedOrgIds.append( org.id )
                } else {
                    selectedOrgIds = selectedOrgIds.without(subtractedItems: [org.id])
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 0.1))
    }

    
    func performDataReset() {
        self.startStaticFrameProcessingSpinner()
        callingMgr?.resetAppData(forOrgIds: selectedOrgIds) { success, error in
            // todo - error handler
            DispatchQueue.main.async {
                // once the reset of google drive data has completed, dismiss the spinner and show an alert box
                self.removeProcessingSpinner()
                self.showAlert(title: NSLocalizedString("Complete", comment: "Complete"), message: "Data reset is complete", includeCancel: false, okCompletionHandler: nil)
            }
        }
    }
    

    // MARK: - Event Handlers
    
    // Final warning button
    func warnDataReset() {
        showAlert(title: "Warning", message: "This will delete all in process calling data for the selected organizations. It will not affect any data on lds.org. This action cannot be undone. Are you sure you want to proceed?", includeCancel: true) { _ in
            self.performDataReset()
        }
    }
    

    
}
