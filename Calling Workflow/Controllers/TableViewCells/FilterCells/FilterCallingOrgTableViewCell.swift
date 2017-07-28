//
//  FilterCallingOrgTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 6/22/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterCallingOrgTableViewCell: FilterBaseTableViewCell {

    let cellTitle : UILabel = UILabel()
    var orgButtonArray : [OrgFilterButton] = []
    var unitLevelOrgs : [Org] = []
    
    init(style: UITableViewCellStyle, reuseIdentifier: String?, unitLevelOrgs : [Org]) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.unitLevelOrgs = unitLevelOrgs
        setupCellTitle()
        setupOrgButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    func setupCellTitle() {
        cellTitle.translatesAutoresizingMaskIntoConstraints = false
        cellTitle.numberOfLines = 0
        cellTitle.text = NSLocalizedString("Organization", comment: "Organization")
        cellTitle.textColor = UIColor.CWFGreyTextColor
        
        self.addSubview(cellTitle)
        
        let xConstraint = NSLayoutConstraint(item: cellTitle, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 15)
        let yConstraint = NSLayoutConstraint(item: cellTitle, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 5)
        let wConstraint = NSLayoutConstraint(item: cellTitle, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -15)
        let hConstraint = NSLayoutConstraint(item: cellTitle, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30)
        
        self.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
    }
    
    func setupOrgButtons(){
        
        var buttonPosition = 0
        var lastElement : OrgFilterButton? = nil
        var isFirst = true

            for buttonOrg in unitLevelOrgs {
                let currentButton = OrgFilterButton()
                currentButton.setTitle(buttonOrg.orgName, for: .normal)
                currentButton.addTarget(self, action: #selector(buttonSelected(sender:)), for: .touchUpInside)
                currentButton.titleLabel?.adjustsFontSizeToFitWidth = true
                // store the  ID's from the org and all the children to add to the button so we can know when a single org (i.e. Primary) is selected we can correctly show any callings in all sub orgs of the org
                currentButton.allOrgIds = buttonOrg.allOrgIds
                
                orgButtonArray.append(currentButton)
                self.addSubview(currentButton)
                
                switch buttonPosition {
                case 0:
                    let xConstriant = NSLayoutConstraint(item: currentButton, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 15)
                    let hConstraint = NSLayoutConstraint(item: currentButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 25)
                    
                    if isFirst {
                        let yConstraint = NSLayoutConstraint(item: currentButton, attribute: .top, relatedBy: .equal, toItem: cellTitle, attribute: .bottom, multiplier: 1, constant: 2)
                        self.addConstraints([xConstriant,yConstraint, hConstraint])
                        isFirst = false
                        
                    }
                    else {
                        let yConstraint = NSLayoutConstraint(item: currentButton, attribute: .top, relatedBy: .equal, toItem: lastElement, attribute: .bottom, multiplier: 1, constant: 2)
                        let wConstraint = NSLayoutConstraint(item: currentButton, attribute: .width, relatedBy: .equal, toItem: lastElement, attribute: .width, multiplier: 1, constant: 0)
                        self.addConstraints([xConstriant, yConstraint, wConstraint, hConstraint])
                    }
                    
                case 1:
                    let xConstraint = NSLayoutConstraint(item: currentButton, attribute: .leading, relatedBy: .equal, toItem: lastElement, attribute: .trailing, multiplier: 1, constant: 5)
                    let yConstraint = NSLayoutConstraint(item: currentButton, attribute: .top, relatedBy: .equal, toItem: lastElement, attribute: .top, multiplier: 1, constant: 0)
                    let wConstraint = NSLayoutConstraint(item: currentButton, attribute: .width, relatedBy: .equal, toItem: lastElement, attribute: .width, multiplier: 1, constant: 0)
                    let hConstraint = NSLayoutConstraint(item: currentButton, attribute: .height, relatedBy: .equal, toItem: lastElement, attribute: .height, multiplier: 1, constant: 0)
                    self.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
                    
                case 2:
                    let xConstraint = NSLayoutConstraint(item: currentButton, attribute: .leading, relatedBy: .equal, toItem: lastElement, attribute: .trailing, multiplier: 1, constant: 5)
                    let yConstraint = NSLayoutConstraint(item: currentButton, attribute: .top, relatedBy: .equal, toItem: lastElement, attribute: .top, multiplier: 1, constant: 0)
                    let wConstraint = NSLayoutConstraint(item: currentButton, attribute: .width, relatedBy: .equal, toItem: lastElement, attribute: .width, multiplier: 1, constant: 0)
                    let hConstraint = NSLayoutConstraint(item: currentButton, attribute: .height, relatedBy: .equal, toItem: lastElement, attribute: .height, multiplier: 1, constant: 0)
                    let rConstraint = NSLayoutConstraint(item: currentButton, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -15)
                    self.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint, rConstraint])
                    
                    
                default:
                    print("unknown state")
                }
                
                lastElement = currentButton
                
                buttonPosition += 1
                
                if buttonPosition >= 3 {
                    buttonPosition = 0
                }
            }
    }
   
    func buttonSelected (sender: FilterButton) {
        if sender.isSelected {
            sender.setupForUnselected()
        }
        else {
            sender.setupForSelected()
        }
    }
    
    override func getCellHeight() -> CGFloat {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        if let orgArray : [Org] = appDelegate?.callingManager.appDataOrg?.children {

            let remainder : Double = Double(orgArray.count)/3.0 - Double(orgArray.count/3)
            if remainder != 0 {
                return CGFloat(30 + 29*((orgArray.count/3)+1))
            }
            else {
                return CGFloat(30 + 29*(orgArray.count/3))
            }
        }
        else {
            return 30
        }
        
    }

}

extension FilterCallingOrgTableViewCell : UIFilterElement {
    /** Set the filter options based on what elements are selected in the UI */
    func getSelectedOptions(filterOptions: FilterOptions) -> FilterOptions {
        var filterOptions = filterOptions
        filterOptions.callingOrgs = orgButtonArray.filter( { $0.isSelected && $0.allOrgIds.isNotEmpty } ).reduce([], { $0 + $1.allOrgIds } )
        return filterOptions
    }
    
    /** Set the state of UI elements based on anything that's currently being applied in the filter */
    func setSelectedOptions(filterOptions: FilterOptions) {
        guard filterOptions.callingOrgs.isNotEmpty else {
            return
        }
        
        for button in orgButtonArray {
            // for all the buttons look and see if the list of ids for the button is in the list of ids in the filterOptions
            if button.allOrgIds.contains(where: {filterOptions.callingOrgs.contains($0)}) {
                button.setupForSelected()
            }
        }
        
    }
}
