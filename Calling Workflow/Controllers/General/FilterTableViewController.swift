//
//  FilterTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/9/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterTableViewController: UITableViewController, FilterTableViewCellDelegate {

    var filterContentArray : [FilterBaseTableViewCell] = []
    var titleString : String?
    var filterObject : FilterOptions = FilterOptions(){
        didSet {
            if let gender = filterObject.gender {
                
                filterContentArray = filterContentArray.filter() {
                    if $0 is FilterOrgTableViewCell {
                        return false
                    }
                    return true
                }
                
                if gender == Gender.Female {
                    addOrgFilterCell(title: "Class", orgType: .MemberClass, upperLevelEnums: [MemberClass.ReliefSociety], lowerLevelEnums: [MemberClass.Laurel, MemberClass.MiaMaid, MemberClass.Beehive])
                } else {
                    addOrgFilterCell(title: "Priesthood", orgType: .Priesthood, upperLevelEnums: [Priesthood.HighPriest, Priesthood.Elder], lowerLevelEnums: [Priesthood.Priest, Priesthood.Teacher, Priesthood.Deacon])
                }
                
                tableView.reloadData()
            }
        }
    }

    
    var delegate : FilterTableViewControllerDelegate?
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        titleString = "Search Filter"
        self.tableView.alwaysBounceVertical = false
        self.tableView.separatorStyle = .none
        self.clearsSelectionOnViewWillAppear = false
        
        regesterTableViewCells()
        addTitleCell()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI(fromFilterOptions: filterObject)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - SETUP
    
    func regesterTableViewCells() {
        tableView.register(FilterTitleTableViewCell.self, forCellReuseIdentifier: "filterTitleCell")
        tableView.register(FilterCallingNumberTableViewCell.self, forCellReuseIdentifier: "FilterCallingNumberCell")
        tableView.register(FilterTimeTableViewCell.self, forCellReuseIdentifier: "FilterTimeCell")
        tableView.register(FilterAgeTableViewCell.self, forCellReuseIdentifier: "FilterAgeCell")
        tableView.register(FilterGenderTableViewCell.self, forCellReuseIdentifier: "FilterGenderCell")
        tableView.register(FilterApplyButtonTableViewCell.self, forCellReuseIdentifier: "FilterApplyCell")
        tableView.register(FilterCallingStatusTableViewCell.self, forCellReuseIdentifier: "FilterCallingStatusCell")
        tableView.register(FilterCallingOrgTableViewCell.self, forCellReuseIdentifier: "FilterCallingOrgCell")
    }
    
    /** 
     Convenience method for adding all possible filter options to the view. Alternatively calling classes can call the individual methods if they only want a limited set of filter options. 
     */
    func addAllFilters() {
        self.addCallingsFilterCell()
        self.addTimeInCallingFilterCell()
        self.addAgeFilterCell()
        self.addGenderFilterCell()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterContentArray.count + 1
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < filterContentArray.count {
            return filterContentArray[indexPath.row].getCellHeight()
        }
        else {
            return FilterApplyButtonTableViewCell.getClassCellHeight()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < filterContentArray.count {
            return filterContentArray[indexPath.row]
        }
        else {
            return addApplyFilterCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    
    // MARK: - Cell Add Methods
    
    private func addTitleCell() {
        let cell = FilterTitleTableViewCell(style: .default, reuseIdentifier: "filterTitleCell", title: titleString)
        
        filterContentArray.insert(cell, at: 0)
    }
 
    private func addApplyFilterCell () -> UITableViewCell {
        let cell = FilterApplyButtonTableViewCell(style: .default, reuseIdentifier: "FilterApplyCell")
        cell.cancelButton.addTarget(self, action: #selector(cancelPressed), for: .touchUpInside)
        cell.applyButton.addTarget(self, action: #selector(applyPressed), for: .touchUpInside)
        return cell
    }

    func addCallingsFilterCell() {
        let cell = FilterCallingNumberTableViewCell(style: .default, reuseIdentifier: "FilterCallingNumberCell", numbers: [0, 1, 2, 3])
        cell.filterDelegate = self
        filterContentArray.append(cell)
    }
    
    func addTimeInCallingFilterCell () {
        let cell = FilterTimeTableViewCell(style: .default, reuseIdentifier: "FilterTimeCell")
        cell.filterDelegate = self
        filterContentArray.append(cell)
    }
    
    func addAgeFilterCell() {
        let cell = FilterAgeTableViewCell(style: .default, reuseIdentifier: "FilterAgeCell")
        cell.filterDelegate = self
        filterContentArray.append(cell)
    }
    
    func addGenderFilterCell() {
        let cell = FilterGenderTableViewCell(style: .default, reuseIdentifier: "FilterGenderCell")
        cell.filterDelegate = self
        filterContentArray.append(cell)
    }
    
    func addCallingStatusFilterCell() {
        let cell = FilterCallingStatusTableViewCell(style: .default, reuseIdentifier: "FilterCallingStatusCell")
        cell.filterDelegate = self
        filterContentArray.append(cell)
    }
    
    func addCallingOrgFilterCell() {
        let cell = FilterCallingOrgTableViewCell(style: .default, reuseIdentifier: "FilterCallingOrgCell")
        cell.filterDelegate = self
        filterContentArray.append(cell)
    }
    private func addOrgFilterCell(title: String, orgType: FilterOrgType, upperLevelEnums: [FilterButtonEnum], lowerLevelEnums: [FilterButtonEnum]) {
        let cell = FilterOrgTableViewCell(style: .default, reuseIdentifier: "FilterOrgCell", title: "Class", orgType: orgType, upperClasses: upperLevelEnums, lowerClasses: lowerLevelEnums)
            filterContentArray.append(cell)
    }
    
    func cancelPressed () {
        self.navigationController?.popViewController(animated: true)
    }
    
    func applyPressed () {
        print("Apply pressed")
        self.delegate?.setFilterOptions(memberFilterOptions: self.getUpdatedFilterObject())
        self.navigationController?.popViewController(animated: true)
    }
    
    func getUpdatedFilterObject() -> FilterOptions {
        var filterOptions : FilterOptions = FilterOptions()
        // combines the elements of all the UI elements into a single filter options object
        filterOptions = filterContentArray.reduce( filterOptions ) {
            let filterCell = $1 as? UIFilterElement
            // we pass in the current filterOptions and return one with any updates from the current UIFilterElement
            return filterCell?.getSelectedOptions(filterOptions: $0) ?? $0
        }
        return filterOptions
    }
    
    func updateUI(fromFilterOptions filterOptions:FilterOptions) {
        // set the state of all the child UI elements based on any filters options that should be applied
        for cell in filterContentArray {
            let filterCell = cell as? UIFilterElement
            filterCell?.setSelectedOptions(filterOptions: filterOptions)
        }
        tableView.reloadData()
    }
    
    
    func updateFilterOptionsForFilterView() {
        self.filterObject = getUpdatedFilterObject()
    }
}
