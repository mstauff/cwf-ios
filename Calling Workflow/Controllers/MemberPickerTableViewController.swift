//
//  MemberPickerTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/3/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class MemberPickerTableViewController: UITableViewController {
    
    var delegate: MemberPickerDelegate?

    var members : [Member] = []

    var filteredMembers = [Member]()
    
    var searchController = UISearchController(searchResultsController: nil)
    
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.init(named: "filter"), style: .done, target: self, action: #selector(filterButtonPressed))

        tableView.register(TitleAdjustableSubtitleTableViewCell.self, forCellReuseIdentifier: "cell")
        
        setupSearchController()
        
        //todo - Remove this. it is only here to assign a calling to a member so we can test the view
        if (members.count > 4) {
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            members[1].currentCallings = (appDelegate?.callingManager.getCallingsForMember(member: members[1]))!
            members[3].currentCallings = (appDelegate?.callingManager.getCallingsForMember(member: members[3]))!


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
        tableView.tableHeaderView = searchController.searchBar
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredMembers.count
        }
        else {
            return members.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TitleAdjustableSubtitleTableViewCell.getHeightForCellForMember(member: members[indexPath.row])
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as? TitleAdjustableSubtitleTableViewCell
        
        var currentMember : Member
        
        if searchController.isActive && searchController.searchBar.text != "" {
            currentMember = filteredMembers[indexPath.row]
        }
        else {
            currentMember = members[indexPath.row]
        }
        
        cell?.infoButton.addTarget(self, action: #selector(showMemberDetails(_:)), for: .touchUpInside)
        cell?.infoButton.tag = indexPath.row

        cell?.setupCell(subtitleCount: currentMember.currentCallings.count)
        cell?.titleLabel.text = members[indexPath.row].name
        if currentMember.currentCallings.count > 0 {
            for i in 0...currentMember.currentCallings.count-1 {
                cell?.leftSubtitles[i].text = currentMember.currentCallings[i].position.name
                cell?.rightSubtitles[i].text = "\(currentMember.currentCallings[i].existingMonthsInCalling) Months"
            }
        }
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         memberSelected(selectedMember: members[indexPath.row])
    }
    
    // MARK: - Search Controller
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        filteredMembers = members.filter { member in
            return (member.name?.lowercased().contains(searchText.lowercased()))!
        }
        
        tableView.reloadData()
    }
    
    
    // MARK: - Button Method
    func memberSelected(selectedMember: Member?) {
        if selectedMember != nil {
            delegate?.setProspectiveMember(member: selectedMember!)
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
        filterView?.addOrgFilterCell(title: "Class", upperLevelNames: ["Relief Socity"], lowerLevelNames: ["Laurel", "Mia Maid", "Bee Hive"])
        
        self.navigationController?.pushViewController(filterView!, animated: true)
    }

    func showMemberDetails(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let memberDetailView = storyboard.instantiateViewController(withIdentifier: "MemberInfoView") as? MemberInfoView
        memberDetailView?.memberToView = members[sender.tag]
        memberDetailView?.modalPresentationStyle = .overCurrentContext

        self.present(memberDetailView!, animated: true, completion: nil)        
    }
}

extension MemberPickerTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}
