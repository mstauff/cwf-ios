//
//  FilterOrgTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/16/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

/**
 Class for handling both Priesthood or MemberClass elements
 */
class FilterOrgTableViewCell: FilterBaseTableViewCell {

    let titleLabel : UILabel = UILabel()
    // for both priesthood or sisters we have two rows of filter options, the top row is the adult options (HP, Elder or RS), the lower row are the younger options (Priest, Deacon, Beehive, etc.)
    var upperClassButtons : [FilterButton] = []
    var lowerClassButtons : [FilterButton] = []
    // which type of filter (priesthood or member class)
    let filterOrgType : FilterOrgType?
    
    //MARK: - init
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        filterOrgType = nil
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTitle(titleString: "")
    }
    
    init(style: UITableViewCellStyle, reuseIdentifier: String?, title: String, orgType: FilterOrgType, upperClasses: [FilterButtonEnum], lowerClasses: [FilterButtonEnum] ) {
        filterOrgType = orgType
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupTitle(titleString: title)
        
        if upperClasses.isNotEmpty {
            addClasses(enumValues: upperClasses, belowView: titleLabel, isUpper: true)
            if lowerClasses.isNotEmpty {
                addClasses(enumValues: lowerClasses, belowView: upperClassButtons[0], isUpper: false)
            }
        }
        else {
            addClasses(enumValues: lowerClasses, belowView: titleLabel, isUpper: false)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Setup
    
    func setupTitle(titleString: String) {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = titleString
        titleLabel.textColor = UIColor.CWFGreyTextColor
        
        self.addSubview(titleLabel)
        
        let lConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
        let yConstraint = NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 5)
        
        self.addConstraints([lConstraint, yConstraint])
    }
    
    func addClasses(enumValues: [FilterButtonEnum], belowView: UIView, isUpper: Bool) {
        var previousView: UIView? = nil
        
        for currentEnum in enumValues {
            let currentButton = FilterButton()
            currentButton.setTitle(currentEnum.description, for: .normal)
            currentButton.addTarget(self, action: #selector(buttonSelected(sender:)), for: .touchUpInside)
            currentButton.filterButtonEnum = currentEnum
            
            
            self.addSubview(currentButton)

            if isUpper {
                upperClassButtons.append(currentButton)
            }
            else {
                lowerClassButtons.append(currentButton)
            }
            
            let yConstraint = NSLayoutConstraint(item: currentButton, attribute: .top, relatedBy: .equal, toItem: belowView, attribute: .bottom, multiplier: 1, constant: 5)
            var xConstraint = NSLayoutConstraint()
            
            // this is just for positioning. The first item is positioned specifically, then the rest are just relative to the previous item
            if previousView == nil {
                xConstraint = NSLayoutConstraint(item: currentButton, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
            } else {
                xConstraint = NSLayoutConstraint(item: currentButton, attribute: .left, relatedBy: .equal, toItem: previousView!, attribute: .right, multiplier: 1, constant: 15)
            }
            
            self.addConstraints([xConstraint, yConstraint])
            
            previousView = currentButton
        }
    }
    
    func buttonSelected (sender: FilterButton) {
        // right now each button is just an independent toggle, so enabling one shouldn't affect anything else
        if (sender.isSelected){
            sender.setupForUnselected()
        } else {
            sender.setupForSelected()
        }
    }

    
    override func getCellHeight() -> CGFloat {
        return 100
    }
}

extension FilterOrgTableViewCell : UIFilterElement {
    func getSelectedOptions(filterOptions: FilterOptions) -> FilterOptions {
        var filterOptions = filterOptions
        // need to find what buttons were selected. Combine them into an array, then pull out the ones that are selected
        let selectedOptions = (upperClassButtons + lowerClassButtons).filter({$0.isSelected})
        if selectedOptions.isNotEmpty {
            // if anything was selected, see which type of org we're dealing with, then set either the priesthood or member class option
            if let orgType = self.filterOrgType, orgType == .MemberClass {
                filterOptions.memberClass = selectedOptions.flatMap({$0.filterButtonEnum as? MemberClass})
            } else if let orgType = self.filterOrgType, orgType == .Priesthood {
                filterOptions.priesthood = selectedOptions.flatMap({$0.filterButtonEnum as? Priesthood})
            }
        }
        return filterOptions
    }
    
    func setSelectedOptions(filterOptions: FilterOptions) {
        guard let orgType = self.filterOrgType else {
            return
        }
        var buttonSelections : [FilterButtonEnum] = []
        // based on the orgType of the filter then read either the priesthood or member class, filter for any true items (as of 7/17 this is unnecessary since we only put something in the list if it should be filtered, but left the filter in for good measure)
        switch orgType {
        case .Priesthood:
                buttonSelections = filterOptions.priesthood
        case .MemberClass:
                buttonSelections = filterOptions.memberClass
        }
        
        if buttonSelections.isNotEmpty {
            for button in (upperClassButtons + lowerClassButtons) {
                // loop through all the buttons in the UI and see if there is a matching enum in the array of values that are being filtered on, set the button to selected if so
                if buttonSelections.contains(where: {$0.rawValue == button.filterButtonEnum?.rawValue}) {
                    button.setupForSelected()
                }
            }
        }

    }
    
}

enum FilterOrgType {
    case Priesthood
    case MemberClass
}
