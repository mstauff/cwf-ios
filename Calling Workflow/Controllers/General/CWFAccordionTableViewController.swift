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
    case Calling
    case AddCalling
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
        
        self.navigationItem.title = rootOrg?.orgName
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Filter", style: .plain, target: self, action: #selector(filterButtonPressed))
       
        setupView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Setup
    func setupView() {
        if rootOrg != nil {
            if (rootOrg?.callings != nil && (rootOrg?.callings.count)! > 0) {
                let newDataItem = AccordionDataItem.init(dataItem: "Add Calling", dataItemType: .AddCalling, expanded: true)
                dataSource.append(newDataItem)
            }
            
            for calling in (rootOrg?.callings)!{
                let newCallingDataItem = AccordionDataItem.init(dataItem: calling, dataItemType: .Calling, expanded: false)
                dataSource.append(newCallingDataItem)
            }
            
            for org in (rootOrg?.children)! {
                let newDataItem = AccordionDataItem.init(dataItem: org, dataItemType: .Parent, expanded: false)
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
            let calling = (currentDataItem.dataItem as! Calling)
            
            cell?.title.text = calling.position.shortName
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
            if (calling.proposedIndId != nil) {
                if let proposedMember = appDelegate?.callingManager.getMemberWithId(memberId: calling.proposedIndId!) {
                    if let nameString = proposedMember.name {
                        cell?.rightItem.text = nameString
                    }
                }
            }
            else {
                cell?.rightItem.isHidden = true
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
                    cell?.newButton.isHidden = false
                    cell?.newButton.addTarget(self, action: #selector(addButtonPressed), for: .touchUpInside)
                    cell?.tag = indexPath.row
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
        if (indexPaths.count > 0) {
            for i in 0...indexPaths.count - 1 {
                let index = indexPaths[indexPaths.count-(i+1)]
                dataSource.remove(at: index.row)
            }
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
        for child in (rootOrg as! Org).children {
            let newDataItem = AccordionDataItem.init(dataItem: child, dataItemType: .Child, expanded: false)
            dataSource.insert(newDataItem, at: indexPath.row + i+1)
            indexPaths.append(IndexPath(row: indexPath.row + i+1, section: 0))
            i += 1
        }
        
        for calling in (rootOrg as! Org).callings {
            let newDataItem = AccordionDataItem.init(dataItem: calling, dataItemType: .Calling, expanded: false)
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
    
    func rootAddButtonPressed(sender: UIButton) {
        let storyBoard = UIStoryboard.init(name: "Main", bundle:nil)
        let nextVC = storyBoard.instantiateViewController(withIdentifier: "NewCallingTableViewController") as? NewCallingTableViewController
        nextVC?.parentOrg = self.rootOrg
        self.navigationController?.pushViewController(nextVC!, animated: true)
    }
    
    class func getCellHeight () -> CGFloat {
        return 50.0
    }
    
    // MARK: - Filter
    func filterButtonPressed() {
        print("showFilter")
    }

    // MARK: - Navigation

}
