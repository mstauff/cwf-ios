//
//  FilterAgeTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/16/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterAgeTableViewCell: FilterBaseTableViewCell {

    let titleLabel : UILabel = UILabel()
    var youthButton : FilterButton = FilterButton()
    var adultButton : FilterButton = FilterButton()
    
    let youthLabel = "\(FilterConstants.youthMinAge)-\(FilterConstants.youthMaxAge)"
    let adultLabel = "\(FilterConstants.adultMinAge)+"
    
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTitle()
        setupAgeButtons()
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
        titleLabel.text = NSLocalizedString("Age", comment: "")
        titleLabel.textColor = UIColor.CWFGreyTextColor
        
        self.addSubview(titleLabel)
        
        let hConstraint = NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        let lConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
        let xConstraint = NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([hConstraint, lConstraint, xConstraint])
    }
    
    func setupAgeButtons() {
        
        youthButton.setTitle(youthLabel, for: UIControlState.normal)
        youthButton.addTarget(self, action: #selector(buttonSelected), for: .touchUpInside)
        youthButton.tag = 1
        
        self.addSubview(youthButton)
        
        let xConstraint = NSLayoutConstraint(item: youthButton, attribute: .left, relatedBy: .equal, toItem: titleLabel, attribute: .right, multiplier: 1, constant: 10)
        let yConstraint = NSLayoutConstraint(item: youthButton, attribute: .centerY, relatedBy: .equal, toItem: titleLabel, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([xConstraint, yConstraint])
        
        adultButton.setTitle(adultLabel, for: UIControlState.normal)
        adultButton.tag = 2
        adultButton.addTarget(self, action: #selector(buttonSelected), for: .touchUpInside)
        
        self.addSubview(adultButton)
        
        let xConstraint2 = NSLayoutConstraint(item: adultButton, attribute: .left, relatedBy: .equal, toItem: youthButton, attribute: .right, multiplier: 1, constant: 10)
        let yConstraint2 = NSLayoutConstraint(item: adultButton, attribute: .centerY, relatedBy: .equal, toItem: youthButton, attribute: .centerY, multiplier: 1, constant: 0)
        let wConstraint2 = NSLayoutConstraint(item: adultButton, attribute: .width, relatedBy: .equal, toItem: youthButton, attribute: .width, multiplier: 1, constant: 0)
        
        self.addConstraints([xConstraint2, yConstraint2, wConstraint2])
        
    }
    
    func buttonSelected (sender: FilterButton) {
        // if the button is selected then we just need to deselect it
        if sender.isSelected {
            sender.setupForUnselected()
        } else {
            // if it wasn't selected we enable it, but also we need to make sure if the other was selected that we deselect it. Currently age & gender are the only buttons that are one or the other. If we have any more in the future it would probably make sense to make a button group manager that can manage this behavior. Right now we only ever have 2 buttons in the group so easy to just deselect the other. If in the future we have more than 2 then we would need to go with an array of the other buttons
            let otherButton = sender == adultButton ? youthButton : adultButton
            otherButton.setupForUnselected()
        
            sender.setupForSelected()
        }
    }
    

}

extension FilterAgeTableViewCell : UIFilterElement {
    func getSelectedOptions(filterOptions: FilterOptions) -> FilterOptions {
        var filterOptions = filterOptions
        if youthButton.isSelected {
            filterOptions.minAge = FilterConstants.youthMinAge
            filterOptions.maxAge = FilterConstants.youthMaxAge
        } else if adultButton.isSelected {
            filterOptions.minAge = FilterConstants.adultMinAge
            filterOptions.maxAge = nil
        }
        return filterOptions
    }
    
    func setSelectedOptions(filterOptions: FilterOptions) {
        if let minAge = filterOptions.minAge {
            if minAge == FilterConstants.youthMinAge {
                youthButton.setupForSelected()
            } else if minAge == FilterConstants.adultMinAge {
                adultButton.setupForSelected()
            }
        }
    }
    
}
