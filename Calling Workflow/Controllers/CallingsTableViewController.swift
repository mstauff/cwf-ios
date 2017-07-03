 //
//  CallingsTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/4/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class CallingsTableViewController: CWFBaseTableViewController, FilterTableViewControllerDelegate {
    
    var inProgressCallingsToDisplay : [Calling] = []
    
    var delegate : CallingsTableViewControllerDelegate? = nil
    
    var filterObject : FilterOptionsObject?
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
      
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44

        tableView.register(NameCallingProposedTableViewCell.self, forCellReuseIdentifier: "cell")
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.title = "In Progress"
        
        if delegate == nil {
            self.tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "filter"), style: .done, target: self, action: #selector(filterButtonPressed))
        }
        else {
            self.tabBarController?.navigationItem.rightBarButtonItem = nil
        }
        setupCallingsToDisplay()
        tableView.reloadData()
    }

    // MARK: - Setup
    
    func setupCallingsToDisplay() {
        if delegate == nil {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            if let unit = appDelegate?.callingManager.appDataOrg {
                inProgressCallingsToDisplay = unit.allInProcessCallings
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {

        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return inProgressCallingsToDisplay.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? NameCallingProposedTableViewCell
        
        let callingForRow = inProgressCallingsToDisplay[indexPath.row]
        
        cell?.nameLabel.text = callingForRow.position.name
       
        if callingForRow.existingIndId != nil {
            let currentyCalled = appDelegate?.callingManager.getMemberWithId(memberId: callingForRow.existingIndId!)
            cell?.currentCallingLabel.text = (currentyCalled?.name)! + " (\(callingForRow.existingMonthsInCalling) Months)"
        }
        else {
            cell?.currentCallingLabel.text = ""
        }
        
        if callingForRow.proposedStatus != CallingStatus.Unknown {
            cell?.callingInProcessLabel.text = callingForRow.proposedStatus.description
        }
        else {
            cell?.callingInProcessLabel.text = ""
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if delegate == nil {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            let nextVc = storyboard.instantiateViewController(withIdentifier: "CallingDetailsTableViewController") as? CallingDetailsTableViewController
            
            nextVc?.callingToDisplay = inProgressCallingsToDisplay[indexPath.row]
            
            navigationController?.pushViewController(nextVc!, animated: true)
        }
        else {
            self.delegate?.setReturnedCalling(calling: inProgressCallingsToDisplay[indexPath.row])
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func filterButtonPressed(sender : UIView) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let filterView = storyboard.instantiateViewController(withIdentifier: "FilterTableViewController") as? FilterTableViewController
        filterView?.addCallingStatusFilterCell()
        filterView?.addCallingOrgFilterCell()
        filterView?.delegate = self
        
        self.navigationController?.pushViewController(filterView!, animated: true)
    }
    
    //MARK: - FilterDelegate
    func setFilterOptions(memberFilterOptions: FilterOptionsObject) {
        filterObject = memberFilterOptions
        //filteredMembers = (filterObject?.filterMemberData(unfilteredArray: inProgressCallingsToDisplay))!
        tableView.reloadData()
    }

}
