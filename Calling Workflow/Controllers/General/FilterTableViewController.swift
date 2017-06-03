//
//  FilterTableViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/9/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterTableViewController: UITableViewController {

    var filterContentArray : [FilterBaseTableViewCell] = []
    
    var filterObject : FilterOptionsObject = FilterOptionsObject()
    
    var delegate : FilterTableViewControllerDelegate?
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.alwaysBounceVertical = false
        self.tableView.separatorStyle = .none
        self.clearsSelectionOnViewWillAppear = false
        regesterTableViewCells()
        addTitleCell()
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
        let cell = FilterTitleTableViewCell(style: .default, reuseIdentifier: "filterTitleCell", title: "Search Filter")
        
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
        
        filterContentArray.append(cell)
    }
    
    func addTimeInCallingFilterCell () {
        let cell = FilterTimeTableViewCell(style: .default, reuseIdentifier: "FilterTimeCell")
        
        filterContentArray.append(cell)
    }
    
    func addAgeFilterCell() {
        let cell = FilterAgeTableViewCell(style: .default, reuseIdentifier: "FilterAgeCell")
        
        filterContentArray.append(cell)
    }
    
    func addGenderFilterCell() {
        let cell = FilterGenderTableViewCell(style: .default, reuseIdentifier: "FilterGenderCell")
        
        filterContentArray.append(cell)
    }
    
    func addOrgFilterCell(title: String, upperLevelNames: [String]?, lowerLevelNames: [String]?) {
        let cell = FilterOrgTableViewCell(style: .default, reuseIdentifier: "FilterOrgCell", title: "Class", upperClasses: upperLevelNames, lowerClasses: lowerLevelNames)
        
        filterContentArray.append(cell)
    }
    
    func cancelPressed () {
        self.navigationController?.popViewController(animated: true)
    }
    
    func applyPressed () {
        print("Apply pressed")
        var filterOptions : FilterOptionsObject = FilterOptionsObject()
        for cell in tableView.visibleCells {
            let filterCell = cell as? FilterBaseTableViewCell
            filterOptions = (filterCell?.getSelectedOptions(filterOptions: filterOptions))!
        }
        self.delegate?.setFilterOptions(memberFilterOptions: filterOptions)
        self.navigationController?.popViewController(animated: true)
    }
    
}
