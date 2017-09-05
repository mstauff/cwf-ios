//
//  FilterGenderTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/16/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterGenderTableViewCell: FilterBaseTableViewCell {
    let titleLabel : UILabel = UILabel()
    var maleButton = FilterButton()
    var femaleButton = FilterButton()
        
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTitle()
        setupButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
    //MARK: - Setup
    
    func setupTitle() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = NSLocalizedString("Gender", comment: "")
        titleLabel.textColor = UIColor.CWFGreyTextColor
        
        self.addSubview(titleLabel)
        
        let hConstraint = NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        let lConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
        let xConstraint = NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([hConstraint, lConstraint, xConstraint])
    }
    
    func setupButtons() {
        
        maleButton.setTitle(NSLocalizedString("Male", comment: ""), for: UIControlState.normal)
        maleButton.addTarget(self, action: #selector(buttonSelected), for: .touchUpInside)
        maleButton.tag = 1
        
        self.addSubview(maleButton)
        
        let xConstraint = NSLayoutConstraint(item: maleButton, attribute: .left, relatedBy: .equal, toItem: titleLabel, attribute: .right, multiplier: 1, constant: 10)
        let yConstraint = NSLayoutConstraint(item: maleButton, attribute: .centerY, relatedBy: .equal, toItem: titleLabel, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([xConstraint, yConstraint])
        
        femaleButton.setTitle(NSLocalizedString("Female", comment: ""), for: UIControlState.normal)
        femaleButton.layoutMargins = .init(top: 5, left: 5, bottom: 5, right: 5)
        femaleButton.tag = 2
        
        femaleButton.addTarget(self, action: #selector(buttonSelected), for: .touchUpInside)
        
        self.addSubview(femaleButton)
        
        let xConstraint2 = NSLayoutConstraint(item: femaleButton, attribute: .left, relatedBy: .equal, toItem: maleButton, attribute: .right, multiplier: 1, constant: 10)
        let yConstraint2 = NSLayoutConstraint(item: femaleButton, attribute: .centerY, relatedBy: .equal, toItem: maleButton, attribute: .centerY, multiplier: 1, constant: 0)
        let wConstraint2 = NSLayoutConstraint(item: femaleButton, attribute: .width, relatedBy: .equal, toItem: maleButton, attribute: .width, multiplier: 1, constant: 0)
        
        self.addConstraints([xConstraint2, yConstraint2, wConstraint2])
        
    }
    
    func buttonSelected (sender: FilterButton) {
        if (sender.isSelected) {
            sender.setupForUnselected()
        } else {
            // if it wasn't selected we enable it, but also we need to make sure if the other was selected that we deselect it. Currently age & gender are the only buttons that are one or the other. If we have any more in the future it would probably make sense to make a button group manager that can manage this behavior. Right now we only ever have 2 buttons in the group so easy to just deselect the other. If in the future we have more than 2 then we would need to go with an array of the other buttons
            let otherButton = sender == femaleButton ? maleButton : femaleButton
            otherButton.setupForUnselected()
            
            sender.setupForSelected()
        }
        filterDelegate?.updateFilterOptionsForFilterView()
    }
    
}

extension FilterGenderTableViewCell : UIFilterElement {
    func getSelectedOptions(filterOptions: FilterOptions) -> FilterOptions {
        var filterOptions = filterOptions
        if maleButton.isSelected {
            filterOptions.gender = Gender.Male
        } else if femaleButton.isSelected {
            filterOptions.gender = Gender.Female
        }
        return filterOptions
    }

    func setSelectedOptions(filterOptions: FilterOptions) {
        guard let gender = filterOptions.gender else {
            return
        }
        let selectedBtn = gender == .Female ? femaleButton : maleButton
        selectedBtn.setupForSelected()
    }
}


