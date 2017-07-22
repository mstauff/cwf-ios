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
    var currentlySelectedId : Int64? = nil
    var searchController = UISearchController(searchResultsController: nil)

    var filteredMembers = [MemberCallings]()
    var filterViewOptions : FilterOptions? = nil
    
    var headerForTable : UIView = UIView()
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "filter"), style: .done, target: self, action: #selector(filterButtonPressed))

        tableView.register(TitleAdjustableSubtitleTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 44
        
        setupHeaderForTable()
        
        setupFilterOptions()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Setup
    func setupFilterOptions() {
        // if there's any filter options then apply the filter
        if let filter = self.filterViewOptions {
            self.filteredMembers = filter.filterMemberData(unfilteredArray: members)
        } else {
            // otherwise just set the filteredMembers to the members, we always read/display from filteredMembers
            self.filteredMembers = members
        }

    }
    
    func setupHeaderForTable () {
        
        headerForTable.translatesAutoresizingMaskIntoConstraints = false
        
        if let _ = currentlySelectedId {
            setupRemoveCurrentMemberView()
        }
        
        setupSearchController()

        
        tableView.tableHeaderView = headerForTable
        
        /*        let views : [String : UIView] = ["tableViewHeader" : tableHeaderView]
         let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[tableViewHeader]-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: views)
         let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[tableViewHeader(==20)]-|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: views)
         tableView.addConstraints(hConstraint)
         tableView.addConstraints(vConstraint)
         */
        if let headerView = tableView.tableHeaderView {
            let xConstraint = NSLayoutConstraint(item: headerView, attribute: .leading, relatedBy: .equal, toItem: tableView, attribute: .leading, multiplier: 1, constant: 0)
            let yConstraint = NSLayoutConstraint(item: headerView, attribute: .top, relatedBy: .equal, toItem: tableView, attribute: .top, multiplier: 1, constant: 0)
            let wConstraint = NSLayoutConstraint(item: headerView, attribute: .width, relatedBy: .equal, toItem: tableView, attribute: .width, multiplier: 1, constant: 0)
            let hConstraint = NSLayoutConstraint(item: headerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: CGFloat(44*headerView.subviews.count))
            
            tableView.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
            tableView.needsUpdateConstraints()
            tableView.layoutIfNeeded()
        }
    }
    
    func setupSearchController () {
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        definesPresentationContext = true
        
        headerForTable.addSubview(searchController.searchBar)
        
        let xConstraint = NSLayoutConstraint(item: searchController.searchBar, attribute: .leading, relatedBy: .equal, toItem: headerForTable, attribute: .leading, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: searchController.searchBar, attribute: .bottom, relatedBy: .equal, toItem: headerForTable, attribute: .bottom, multiplier: 1, constant: 0)
        let wConstraint = NSLayoutConstraint(item: searchController.searchBar, attribute: .trailing, relatedBy: .equal, toItem: headerForTable, attribute: .trailing, multiplier: 1, constant: 0)
        let hConstraint = NSLayoutConstraint(item: searchController.searchBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44)
        
        headerForTable.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
    }
    
    func setupRemoveCurrentMemberView () {
        let memberView = UIView()
        memberView.translatesAutoresizingMaskIntoConstraints = false

        let removeButton = UIButton(type: .system)
        removeButton.setImage(UIImage.imageFromSystemBarButton(.trash), for: .normal)
        removeButton.addTarget(self, action: #selector(removeButtonPressed), for: .touchUpInside)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        
        memberView.addSubview(removeButton)
        
        let buttonXConstraint = NSLayoutConstraint(item: removeButton, attribute: .leading, relatedBy: .equal, toItem: memberView, attribute: .leading, multiplier: 1, constant: 0)
        let buttonYConstraint = NSLayoutConstraint(item: removeButton, attribute: .top, relatedBy: .equal, toItem: memberView, attribute: .top, multiplier: 1, constant: 0)
        let buttonHConstraint = NSLayoutConstraint(item: removeButton, attribute: .height, relatedBy: .equal, toItem: memberView, attribute: .height, multiplier: 1, constant: 0)
        let buttonWConstraint = NSLayoutConstraint(item: removeButton, attribute: .width, relatedBy: .equal, toItem: removeButton, attribute: .height, multiplier: 1, constant: 0)
        
        memberView.addConstraints([buttonXConstraint, buttonYConstraint, buttonHConstraint, buttonWConstraint])
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let selectedId = currentlySelectedId{
            if let currentlySelected = appDelegate.callingManager.getMemberWithId(memberId: selectedId) {
                nameLabel.text = currentlySelected.name
            }
        }
        
        memberView.addSubview(nameLabel)
        
        let nameXConstraint = NSLayoutConstraint(item: nameLabel, attribute: .leading, relatedBy: .equal, toItem: removeButton, attribute: .trailing, multiplier: 1, constant: 0)
        let nameYConstraint = NSLayoutConstraint(item: nameLabel, attribute: .top, relatedBy: .equal, toItem: memberView, attribute: .top, multiplier: 1, constant: 0)
        let nameHConstraint = NSLayoutConstraint(item: nameLabel, attribute: .bottom, relatedBy: .equal, toItem: memberView, attribute: .bottom, multiplier: 1, constant: 0)
        let nameWConstraint = NSLayoutConstraint(item: nameLabel, attribute: .right, relatedBy: .equal, toItem: memberView, attribute: .right, multiplier: 1, constant: -15)
        
        memberView.addConstraints([nameXConstraint, nameYConstraint, nameHConstraint, nameWConstraint])
        
        
        headerForTable.addSubview(memberView)
        
        let xConstraint = NSLayoutConstraint(item: memberView, attribute: .leading, relatedBy: .equal, toItem: headerForTable, attribute: .leading, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: memberView, attribute: .top, relatedBy: .equal, toItem: headerForTable, attribute: .top, multiplier: 1, constant: 0)
        let wConstraint = NSLayoutConstraint(item: memberView, attribute: .trailing, relatedBy: .equal, toItem: headerForTable, attribute: .trailing, multiplier: 1, constant: 0)
        let hConstraint = NSLayoutConstraint(item: memberView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44)
        
        headerForTable.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
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
        if let member = selectedMember {
            delegate?.setProspectiveMember(member: member.member)
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
    
    //MARK: - RemoveButton
    func removeButtonPressed() {
        delegate?.setProspectiveMember(member: nil)
        self.navigationController?.popViewController(animated: true)
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
