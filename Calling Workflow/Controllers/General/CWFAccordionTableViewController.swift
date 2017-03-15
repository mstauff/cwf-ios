//
//  CWFAccordionTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 3/8/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

enum DataItemType {
    case Parent
    case Child
}

struct AccordionDataItem {
    var dataItem : Any
    var dataItemType : DataItemType
    var expanded : Bool
    
}

class CWFAccordionTableViewController: CWFBaseTableViewController {
    
    var dataSource : [AccordionDataItem] = []
    var rootOrg : Org?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false

        tableView.register(CWFAccordionRootTableViewCell.self, forCellReuseIdentifier: "rootCell")
        tableView.register(CWFAccordionChildTableViewCell.self, forCellReuseIdentifier: "childCell")
        
        setupView()
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Setup
    func setupView() {
        if rootOrg != nil {
            for org in (rootOrg?.children)! {
                let newDataItem = AccordionDataItem.init(dataItem: org, dataItemType: DataItemType.Parent, expanded: false)
                dataSource.append(newDataItem)
            }
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

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let currentDataItem = dataSource[indexPath.row]
        if currentDataItem.dataItemType == .Parent{
            return CWFAccordionRootTableViewCell.getCellHeight()
        }
        else {
            return CWFAccordionChildTableViewCell.getCellHeight()  
        }
        
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let currentDataItem = self.dataSource[indexPath.row]
        switch currentDataItem.dataItemType {
        case DataItemType.Parent:
            let cell = tableView.dequeueReusableCell(withIdentifier: "rootCell", for: indexPath) as? CWFAccordionRootTableViewCell
            cell?.titleLabel.text = (currentDataItem.dataItem as! Org).orgName
            return cell!

        default:
            let appDelegate = UIApplication.shared.delegate as? AppDelegate

            let cell = tableView.dequeueReusableCell(withIdentifier: "childCell", for: indexPath) as? CWFAccordionChildTableViewCell
            let calling = (currentDataItem.dataItem as! Calling)
            
            cell?.title.text = calling.position.name
            if (calling.existingIndId != nil) {
                if let existingMember = appDelegate?.callingManager.getMemberWithId(memberId: calling.existingIndId!) {
                    if let nameString = existingMember.name {
                        cell?.subtitle.text = "(\(nameString))"
                    }
                }
            }
            else {
                cell?.subtitle.isHidden = true
            }
            if (true) { //(calling.proposedIndId != nil) { // todo - remove the true
                if let proposedMember = appDelegate?.callingManager.getMemberWithId(memberId: 8999999998963918) { // todo - Remove the hard coded value
                    if let nameString = proposedMember.name {
                        cell?.rightItem.text = nameString
                    }
                }
            }
            else {
                cell?.rightItem.isHidden = true
            }
            
            return cell!
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dataItem = dataSource[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        
        if dataItem.dataItemType == DataItemType.Parent {
            if (dataItem.expanded) {
                let cell = tableView.cellForRow(at: indexPath) as? CWFAccordionRootTableViewCell
                cell?.newButton.isHidden = true
                collapseCell(indexPath: indexPath)
            }
            else {
                let cell = tableView.cellForRow(at: indexPath) as? CWFAccordionRootTableViewCell
                cell?.newButton.isHidden = false
                cell?.newButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
                cell?.tag = indexPath.row
                expandCell(indexPath: indexPath)
            }
        }
        else {
            let calling = dataItem.dataItem as? Calling
            let storyBoard = UIStoryboard.init(name: "Main", bundle:nil)
            let nextVC = storyBoard.instantiateViewController(withIdentifier: "CallingDetailsTableViewController") as? CallingDetailsTableViewController
            nextVC?.callingToDisplay = calling
            self.navigationController?.pushViewController(nextVC!, animated: true)
        }
    }
    
    func collapseCell(indexPath: IndexPath) {
        var indexPaths : [IndexPath] = []
        var foundParent = false
        var currentIndex = indexPath.row + 1
        
        while !foundParent && currentIndex < dataSource.count {
            if dataSource[currentIndex].dataItemType == DataItemType.Parent {
                foundParent = true
            }
            else {
                indexPaths.append(IndexPath(row: currentIndex, section: 0))
                currentIndex = currentIndex + 1
            }
        }
        
        for i in 0...indexPaths.count - 1 {
            let index = indexPaths[indexPaths.count-(i+1)]
            dataSource.remove(at: index.row)
        }
        dataSource[indexPath.row].expanded = false
        self.tableView.beginUpdates()
        self.tableView.deleteRows(at: indexPaths, with: .fade)
        self.tableView.endUpdates()
    }
    func expandCell(indexPath: IndexPath) {
        
        let rootOrg = dataSource[indexPath.row].dataItem
        var i = 0
        var indexPaths : [IndexPath] = []
        for child in (rootOrg as! Org).callings {
            let newDataItem = AccordionDataItem.init(dataItem: child, dataItemType: .Child, expanded: false)
            dataSource.insert(newDataItem, at: indexPath.row + i+1)
            indexPaths.append(IndexPath(row: indexPath.row + i+1, section: 0))
            i += 1
        }
        
        dataSource[indexPath.row].expanded = true
        
        self.tableView.beginUpdates()

        tableView.insertRows(at: indexPaths, with: .fade)

        self.tableView.endUpdates()
    }
    
    func isRootCell(indexPath: IndexPath) -> Bool {
        return true
    }
    
    func addButtonPressed(sender: UIButton) {
        
        let storyBoard = UIStoryboard.init(name: "Main", bundle:nil)
        let nextVC = storyBoard.instantiateViewController(withIdentifier: "NewCallingTableViewController") as? NewCallingTableViewController
        nextVC?.parentOrg = dataSource[sender.tag].dataItem as? Org
        self.navigationController?.pushViewController(nextVC!, animated: true)
    }
    
    class func getCellHeight () -> CGFloat {
        return 50.0
    }
    // MARK: - Navigation

}
