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
    var ageButtonArray : [FilterButton] = []
      
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
        titleLabel.text = "Age"
        titleLabel.textColor = .gray
        
        self.addSubview(titleLabel)
        
        let hConstraint = NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        let lConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
        let xConstraint = NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([hConstraint, lConstraint, xConstraint])
    }
    
    func setupAgeButtons() {
        
        let youthButton = FilterButton()
        ageButtonArray.append(youthButton)
        youthButton.setTitle("12-18", for: UIControlState.normal)
        youthButton.addTarget(self, action: #selector(buttonSelected), for: .touchUpInside)
        youthButton.tag = 1
        
        self.addSubview(youthButton)
        
        let xConstraint = NSLayoutConstraint(item: youthButton, attribute: .left, relatedBy: .equal, toItem: titleLabel, attribute: .right, multiplier: 1, constant: 10)
        let yConstraint = NSLayoutConstraint(item: youthButton, attribute: .centerY, relatedBy: .equal, toItem: titleLabel, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([xConstraint, yConstraint])
        
        let adultButton = FilterButton()
        ageButtonArray.append(adultButton)
        adultButton.setTitle("18+", for: UIControlState.normal)
        adultButton.tag = 2
        adultButton.addTarget(self, action: #selector(buttonSelected), for: .touchUpInside)
        
        self.addSubview(adultButton)
        
        let xConstraint2 = NSLayoutConstraint(item: adultButton, attribute: .left, relatedBy: .equal, toItem: youthButton, attribute: .right, multiplier: 1, constant: 10)
        let yConstraint2 = NSLayoutConstraint(item: adultButton, attribute: .centerY, relatedBy: .equal, toItem: youthButton, attribute: .centerY, multiplier: 1, constant: 0)
        let wConstraint2 = NSLayoutConstraint(item: adultButton, attribute: .width, relatedBy: .equal, toItem: youthButton, attribute: .width, multiplier: 1, constant: 0)
        
        self.addConstraints([xConstraint2, yConstraint2, wConstraint2])
        
    }
    
    func buttonSelected (sender: FilterButton) {
        if sender.isSelected {
            sender.isSelected = false
            sender.setupForUnselected()
        }
        else {
            for button in ageButtonArray {
                button.isSelected = false
                button.setupForUnselected()
            }
        
            sender.isSelected = true
            sender.setupForSelected()
        }
        filterDelegate?.updateFilterOptionsForFilterView() 
    }
    
    override func getSelectedOptions(filterOptions: FilterOptionsObject) -> FilterOptionsObject {
        for button in ageButtonArray {
            switch button.tag {
            case 1:
                if (button.isSelected) {
                    filterOptions.minAge = 12
                    filterOptions.maxAge = 18
                }
            case 2:
                if button.isSelected {
                    filterOptions.minAge = 18
                    filterOptions.maxAge = nil
                }
            default:
                print("button with no tag selected")
            }
        }
        return filterOptions
    }

}
