//
//  MemberPickerTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/3/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class MemberPickerTableViewController: UITableViewController, FilterTableViewControllerDelegate, UISearchControllerDelegate {
    
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
        
        //Add the searchBar and the Delete current Person
        setupHeaderForTable()

        setupFilterOptions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.searchController.searchBar.resignFirstResponder()
        self.searchController.dismiss(animated: false, completion: nil)
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
        //Set the header for the table to a custom view
        tableView.tableHeaderView = headerForTable
        tableView.tableHeaderView?.translatesAutoresizingMaskIntoConstraints = false
        
        //Height for the header. Defaults to the height of a single item.
        var height : CGFloat = 44.0

        //check if we need to add the delete bar
        if let _ = currentlySelectedId {
            setupRemoveCurrentMemberView()
            //update height to accomidate search and delete
            height = 88.0
        }
        
        setupSearchController()

        //Add constraints to tableView to size header and update
        if let _ = tableView.tableHeaderView {
            let xConstraint = NSLayoutConstraint(item: tableView.tableHeaderView!, attribute: .leading, relatedBy: .equal, toItem: tableView, attribute: .leading, multiplier: 1, constant: 0)
            let yConstraint = NSLayoutConstraint(item: tableView.tableHeaderView!, attribute: .top, relatedBy: .equal, toItem: tableView, attribute: .top, multiplier: 1, constant: 0)
            let wConstraint = NSLayoutConstraint(item: tableView.tableHeaderView!, attribute: .width, relatedBy: .equal, toItem: tableView, attribute: .width, multiplier: 1, constant: 0)
            let hConstraint = NSLayoutConstraint(item: tableView.tableHeaderView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: height)
            
            tableView.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
            tableView.needsUpdateConstraints()
            tableView.layoutIfNeeded()
        }
    }
    
    func setupSearchController () {
        //set new view to contain searchbar
        let searchView = UIView()
        searchView.translatesAutoresizingMaskIntoConstraints = false
        
        //set the delegates, options, and responders for searchController
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        
        //add the searchBar to the container View
        searchView.addSubview(searchController.searchBar)

        //Add view to the headerView
        headerForTable.addSubview(searchView)
        
        //Add Constraints to layout searchBar in Header
        let xConstraint = NSLayoutConstraint(item: searchView, attribute: .left, relatedBy: .equal, toItem: headerForTable, attribute: .left, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: searchView, attribute: .bottom, relatedBy: .equal, toItem: headerForTable, attribute: .bottom, multiplier: 1, constant: 0)
        let wConstraint = NSLayoutConstraint(item: searchView, attribute: .width, relatedBy: .equal, toItem: headerForTable, attribute: .width, multiplier: 1, constant: 0)
        let hConstraint = NSLayoutConstraint(item: searchView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44)
        
        headerForTable.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
 
    }
    
    func setupRemoveCurrentMemberView () {
        //add container for the delete view
        let removeMemberView = UIView()
        removeMemberView.translatesAutoresizingMaskIntoConstraints = false

        //add button to view for delete
        let removeButton = UIButton(type: .system)
        removeButton.setImage(UIImage.init(named: "DeleteIcon") , for: .normal)
        removeButton.addTarget(self, action: #selector(removeButtonPressed), for: .touchUpInside)
        removeButton.translatesAutoresizingMaskIntoConstraints = false
        
        removeMemberView.addSubview(removeButton)
        
        let buttonXConstraint = NSLayoutConstraint(item: removeButton, attribute: .leading, relatedBy: .equal, toItem: removeMemberView, attribute: .leading, multiplier: 1, constant: 0)
        let buttonYConstraint = NSLayoutConstraint(item: removeButton, attribute: .top, relatedBy: .equal, toItem: removeMemberView, attribute: .top, multiplier: 1, constant: 0)
        let buttonHConstraint = NSLayoutConstraint(item: removeButton, attribute: .height, relatedBy: .equal, toItem: removeMemberView, attribute: .height, multiplier: 1, constant: 0)
        let buttonWConstraint = NSLayoutConstraint(item: removeButton, attribute: .width, relatedBy: .equal, toItem: removeButton, attribute: .height, multiplier: 1, constant: 0)
        
        removeMemberView.addConstraints([buttonXConstraint, buttonYConstraint, buttonHConstraint, buttonWConstraint])
        
        //add name label to the deleteView
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let selectedId = currentlySelectedId{
            if let currentlySelected = appDelegate.callingManager.getMemberWithId(memberId: selectedId) {
                nameLabel.text = currentlySelected.name
            }
        }
        
        removeMemberView.addSubview(nameLabel)
        
        let nameXConstraint = NSLayoutConstraint(item: nameLabel, attribute: .leading, relatedBy: .equal, toItem: removeButton, attribute: .trailing, multiplier: 1, constant: 0)
        let nameYConstraint = NSLayoutConstraint(item: nameLabel, attribute: .top, relatedBy: .equal, toItem: removeMemberView, attribute: .top, multiplier: 1, constant: 0)
        let nameHConstraint = NSLayoutConstraint(item: nameLabel, attribute: .bottom, relatedBy: .equal, toItem: removeMemberView, attribute: .bottom, multiplier: 1, constant: 0)
        let nameWConstraint = NSLayoutConstraint(item: nameLabel, attribute: .right, relatedBy: .equal, toItem: removeMemberView, attribute: .right, multiplier: 1, constant: -15)
        
        removeMemberView.addConstraints([nameXConstraint, nameYConstraint, nameHConstraint, nameWConstraint])
        
        
        headerForTable.addSubview(removeMemberView)
        
        let xConstraint = NSLayoutConstraint(item: removeMemberView, attribute: .leading, relatedBy: .equal, toItem: headerForTable, attribute: .leading, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: removeMemberView, attribute: .top, relatedBy: .equal, toItem: headerForTable, attribute: .top, multiplier: 1, constant: 0)
        let wConstraint = NSLayoutConstraint(item: removeMemberView, attribute: .trailing, relatedBy: .equal, toItem: headerForTable, attribute: .trailing, multiplier: 1, constant: 0)
        let hConstraint = NSLayoutConstraint(item: removeMemberView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44)
        
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
        let baseCurrentString = (currentMember.callings.namesWithTime())
        let baseProposedString = (currentMember.proposedCallings.namesWithStatus())
        let callingText : NSMutableAttributedString = NSMutableAttributedString(string: "")
        
        callingText.append(NSAttributedString(string: baseCurrentString))
        if (callingText != NSAttributedString(string:"") && baseProposedString != "") {
            callingText.append(NSAttributedString(string: ", "))
        }
        callingText.append(NSAttributedString(string: baseProposedString))
        
        let greenRange = NSRange.init(location: callingText.length - baseProposedString.count, length: baseProposedString.count)
        callingText.addAttribute(NSForegroundColorAttributeName, value: UIColor.CWFGreenTextColor, range: greenRange)

        cell?.subtitle.attributedText = callingText

        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        memberSelected(selectedMember: filteredMembers[indexPath.row])
    }
    
    // MARK: - Search Controller
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        //filter if there is text
        if searchText != "" {
            filteredMembers = filteredMembers.filter { member in
                return (member.member.name?.lowercased().contains(searchText.lowercased()))!
            }
        }
        //reset to filtered list if no text
        else {
            setupFilterOptions()
        }
        tableView.reloadData()
    }
    
    // MARK: - Button Method
    func memberSelected(selectedMember: MemberCallings?) {
        self.searchController.isActive = false
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
        if let filterOptions = self.filterViewOptions {
            filterView?.filterObject = filterOptions
        }
        
        self.navigationController?.pushViewController(filterView!, animated: true)
    }

    func showMemberDetails(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let memberDetailView = storyboard.instantiateViewController(withIdentifier: "MemberInfoView") as? MemberInfoView
        memberDetailView?.memberToView = self.filteredMembers[sender.tag]
        memberDetailView?.modalPresentationStyle = .overCurrentContext

        self.present(memberDetailView!, animated: true, completion: nil)        
    }
    
    //MARK: - FilterViewDelegate
    
    func setFilterOptions(memberFilterOptions: FilterOptions) {
        self.filteredMembers = memberFilterOptions.filterMemberData(unfilteredArray: members)
        self.filterViewOptions = memberFilterOptions
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
