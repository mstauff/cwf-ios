//
//  DirectoryTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/4/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class DirectoryTableViewController: CWFBaseTableViewController, FilterTableViewControllerDelegate {

    var members : [Member]!

    var filteredMembers = [Member]()
    var filterViewOptions : FilterOptionsObject? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        
        members = []
        
        setupData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.title = "Directory"
        self.tabBarController?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "filter"), style: .done, target: self, action: #selector(filterButtonPressed))
        setupData()
        tableView.reloadData()
    }
  
    // MARK: - Setup
    func setupData() {        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            members = appDelegate.callingManager.memberList
        }
    }
  
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return members.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: NameCallingProposedTableViewCell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! NameCallingProposedTableViewCell
        let memberForCell = members[indexPath.row]
        
        cell.nameLabel.text = memberForCell.name
        
        if memberForCell.currentCallings.count > 0 {
            cell.currentCallingLabel.text = memberForCell.currentCallings[0].position.name
        }
        else {
            cell.currentCallingLabel.text = nil
        }
       
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        cell.callingInProcessLabel?.text = (appDelegate?.callingManager.getCallings(forMember: memberForCell).namesWithTime() ?? "") + (appDelegate?.callingManager.getPotentialCallings(forMember: memberForCell).namesWithStatus() ?? "")

        return cell
    }
    
    
    //MARK: - FilterViewDelegate
    
    func setFilterOptions(memberFilterOptions: FilterOptionsObject) {
        filterViewOptions = memberFilterOptions
        filteredMembers = (filterViewOptions?.filterMemberData(unfilteredArray: members))!
        tableView.reloadData()
    }

    func filterButtonPressed(sender : UIView) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let filterView = storyboard.instantiateViewController(withIdentifier: "FilterTableViewController") as? FilterTableViewController
        filterView?.addCallingsFilterCell()
        filterView?.addTimeInCallingFilterCell()
        filterView?.addAgeFilterCell()
        filterView?.addGenderFilterCell()
        filterView?.delegate = self
        
        self.navigationController?.pushViewController(filterView!, animated: true)
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    

}
