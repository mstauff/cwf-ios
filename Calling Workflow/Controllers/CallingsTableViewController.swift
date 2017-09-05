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
    var allInProgressCallings : [Calling] = []
    var unitLevelOrgs : [Org] = []
    
    var filterObject : FilterOptions?
    
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
        tabBarController?.title = NSLocalizedString("In Progress", comment: "callings in progress")
        
        self.tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "filter"), style: .done, target: self, action: #selector(filterButtonPressed))

        loadCallingData()
        tableView.reloadData()
    }

    // MARK: - Setup
    
    func loadCallingData() {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if let unit = appDelegate?.callingManager.appDataOrg {
            allInProgressCallings = unit.allInProcessCallings
            // we always display inProgressCallingsToDisplay, so look for any existing filter and if there isn't one then just use allInProgressCallings. If there is a filter then the list has already been filtered by the delegate handling method so just use it as is
            inProgressCallingsToDisplay = filterObject == nil ? allInProgressCallings : inProgressCallingsToDisplay
            unitLevelOrgs = unit.children
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return inProgressCallingsToDisplay.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? NameCallingProposedTableViewCell
        
        let callingForRow = inProgressCallingsToDisplay[indexPath.row]
        
        cell?.nameLabel.text = callingForRow.position.name
       
        if let currentlyCalledId = callingForRow.existingIndId {
            if let currentyCalled = appDelegate?.callingManager.getMemberWithId(memberId: currentlyCalledId), let name = currentyCalled.name {
                cell?.currentCallingLabel.text = name + NSLocalizedString(" (\(callingForRow.existingMonthsInCalling) Months)", comment: "months in calling")
            }
        }
        else {
            cell?.currentCallingLabel.text = nil
        }
        
        if let proposedId = callingForRow.proposedIndId {
            if let proposedCalled = appDelegate?.callingManager.getMemberWithId(memberId: proposedId) {
                if let name = proposedCalled.name {
                    cell?.callingInProcessLabel.textColor = UIColor.CWFGreenTextColor
                    cell?.callingInProcessLabel.text = "\(name)"
                    
                    if callingForRow.proposedStatus != .Unknown {
                        cell?.callingInProcessLabel.text?.append(" (\(callingForRow.proposedStatus.description))")
                    }
                }
            }
        }
        else {
            cell?.callingInProcessLabel.text = nil
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let nextVc = storyboard.instantiateViewController(withIdentifier: "CallingDetailsTableViewController") as? CallingDetailsTableViewController
            
        nextVc?.callingToDisplay = inProgressCallingsToDisplay[indexPath.row]
            
        navigationController?.pushViewController(nextVc!, animated: true)
    }
    
    //MARK: - FilterButton
    func filterButtonPressed(sender : UIView) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let filterView = storyboard.instantiateViewController(withIdentifier: "FilterTableViewController") as? FilterTableViewController {
            // need to add the orgs before we add the filter cells so when the view gets init'ed the orgs are available to create the buttons
            filterView.unitLevelOrgs = self.unitLevelOrgs
            filterView.addCallingStatusFilterCell()
            filterView.addCallingOrgFilterCell()
            filterView.delegate = self
            if let currentFilters = self.filterObject {
                filterView.filterObject = currentFilters
            }
        
            self.navigationController?.pushViewController(filterView, animated: true)
        }
    }
    
    //MARK: - FilterDelegate
    func setFilterOptions(memberFilterOptions: FilterOptions) {
        self.filterObject = memberFilterOptions
        // we don't need the member object for any of these filters, we just need a MemberCalling object and rather than make Member, Member? we convert all the callings to MemberCalling. We don't actually use the Member object for anything so rather than look up the appropriate member based on the calling proposedIndId and set it just to throw it away, we just create a dummy member object for all of them. If we ever add different filters (like number or length in the calling) then we will need to change this to be the actual member
        let dummyMember = Member(indId: -1, name: nil, indPhone: nil, housePhone: nil, indEmail: nil, householdEmail: nil, streetAddress: [], birthdate: nil, gender: nil, priesthood: nil)
        // map the callings to a MemberCalling objects and run them through the filters, then convert them back to callings.
        let filteredMembers = memberFilterOptions.filterMemberData(unfilteredArray: allInProgressCallings.map() {
            MemberCallings(member: dummyMember, callings: [], proposedCallings: [$0])
        })
        // we added each individual calling to $proposedCallings[0], so safe to pull it out of there
        inProgressCallingsToDisplay = filteredMembers.map() { $0.proposedCallings[0] }
        tableView.reloadData()
    }
}
