//
//  MemberPickerTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/3/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class MemberPickerTableViewController: UITableViewController, FilterTableViewControllerDelegate {
    
    var delegate: MemberPickerDelegate?

    var members : [MemberCallings] = []
    
    var searchController = UISearchController(searchResultsController: nil)

    var filteredMembers = [MemberCallings]()
    var filterViewOptions : FilterOptionsObject? = nil
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "filter"), style: .done, target: self, action: #selector(filterButtonPressed))

        tableView.register(TitleAdjustableSubtitleTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        setupSearchController()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Setup
    
    func setupSearchController () {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (searchController.isActive && searchController.searchBar.text != "") || filterViewOptions != nil {
            return filteredMembers.count
        }
        else {
            return members.count
        }
    }
    
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        if searchController.isActive && searchController.searchBar.text != "" || filterViewOptions != nil{
//            return TitleAdjustableSubtitleTableViewCell.getHeightForCellForMember(member: filteredMembers[indexPath.row])
//        }
//        else {
//            return TitleAdjustableSubtitleTableViewCell.getHeightForCellForMember(member: members[indexPath.row])
//        }
//    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? TitleAdjustableSubtitleTableViewCell
        
        var currentMember : MemberCallings
        
        if searchController.isActive && searchController.searchBar.text != "" || filterViewOptions != nil {
            currentMember = filteredMembers[indexPath.row]
        }
        else {
            currentMember = members[indexPath.row]
        }
        
        cell?.infoButton.addTarget(self, action: #selector(showMemberDetails(_:)), for: .touchUpInside)
        cell?.infoButton.tag = indexPath.row

        cell?.titleLabel.text = currentMember.member.name
        
        cell?.subtitle.text = (currentMember.callings.namesWithTime() ) + (currentMember.proposedCallings.namesWithStatus() )

        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchController.isActive && searchController.searchBar.text != "" || filterViewOptions != nil {
            memberSelected(selectedMember: members[indexPath.row])
        }
        else {
             memberSelected(selectedMember: members[indexPath.row])
        }
    }
    
    // MARK: - Search Controller
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredMembers = members.filter { member in
            return (member.member.name?.lowercased().contains(searchText.lowercased()))!
        }
        
        tableView.reloadData()
    }
    
    
    // MARK: - Button Method
    func memberSelected(selectedMember: MemberCallings?) {
        if selectedMember != nil {
            delegate?.setProspectiveMember(member: selectedMember!.member)
        }
        self.navigationController?.popViewController(animated: true)
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

    func showMemberDetails(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let memberDetailView = storyboard.instantiateViewController(withIdentifier: "MemberInfoView") as? MemberInfoView
        memberDetailView?.memberToView = members[sender.tag]
        memberDetailView?.modalPresentationStyle = .overCurrentContext

        self.present(memberDetailView!, animated: true, completion: nil)        
    }
    
    //MARK: - FilterViewDelegate
    
    func setFilterOptions(memberFilterOptions: FilterOptionsObject) {
        filterViewOptions = memberFilterOptions
        filteredMembers = (filterViewOptions?.filterMemberData(unfilteredArray: members))!
        tableView.reloadData()
    }
}

//MARK: - MemberPickerExtension
extension MemberPickerTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
