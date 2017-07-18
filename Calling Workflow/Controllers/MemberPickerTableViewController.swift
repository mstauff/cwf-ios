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
    var filterViewOptions : FilterOptions? = nil
    
    var tableHeaderView : UIView = UIView()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "filter"), style: .done, target: self, action: #selector(filterButtonPressed))

        tableView.register(TitleAdjustableSubtitleTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        setupSearchController()
        
        // if there's any filter options then apply the filter
        if let filter = self.filterViewOptions {
            self.filteredMembers = filter.filterMemberData(unfilteredArray: members)            
        } else {
            // otherwise just set the filteredMembers to the members, we always read/display from filteredMembers
            self.filteredMembers = members
        }
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
        tableHeaderView.addSubview(searchController.searchBar)
        tableView.tableHeaderView = tableHeaderView
//        tableView.tableHeaderView = searchController.searchBar
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredMembers.count
    }
    


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? TitleAdjustableSubtitleTableViewCell
        
        let currentMember = filteredMembers[indexPath.row]
        
        cell?.infoButton.addTarget(self, action: #selector(showMemberDetails(_:)), for: .touchUpInside)
        cell?.infoButton.tag = indexPath.row

        cell?.titleLabel.text = currentMember.member.name
        
        cell?.subtitle.text = (currentMember.callings.namesWithTime() ) + (currentMember.proposedCallings.namesWithStatus() )

        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        memberSelected(selectedMember: filteredMembers[indexPath.row])
    }
    
    // MARK: - Search Controller
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredMembers = filteredMembers.filter { member in
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
        // we want all the filter options to be included so just use the convenience method to add them all
        filterView?.addAllFilters()
        filterView?.delegate = self
        // if there are any preset filter options (based on position requirements) then set those on the filter screen before we transition
        if filterViewOptions != nil {
            filterView?.filterObject = filterViewOptions!
        }
        
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
    
    func setFilterOptions(memberFilterOptions: FilterOptions) {
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
