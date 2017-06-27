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
        
        tableView.register(DirectoryTableViewCell.self, forCellReuseIdentifier: "directioryCell")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
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
        let memberForCell = members[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "directioryCell", for: indexPath) as! DirectoryTableViewCell
        cell.nameLabel.text = memberForCell.name

        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if let callings = appDelegate?.callingManager.getCallings(forMember: memberForCell){
            cell.setupCallingLabels(callings:callings, member: memberForCell)
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let member = members[indexPath.row]
       
        displayContactInfoForMember(member:  member)
        
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
    
    //MARK: - Show Contact Info
    func displayContactInfoForMember(member: Member) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let memberDetailView = storyboard.instantiateViewController(withIdentifier: "MemberInfoView") as? MemberInfoView
        memberDetailView?.memberToView = member
        memberDetailView?.modalPresentationStyle = .overCurrentContext
        
        self.present(memberDetailView!, animated: true, completion: nil)
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
