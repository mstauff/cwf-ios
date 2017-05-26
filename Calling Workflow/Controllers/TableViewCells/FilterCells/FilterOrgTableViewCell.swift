//
//  FilterOrgTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/16/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterOrgTableViewCell: FilterBaseTableViewCell {

    let titleLabel : UILabel = UILabel()
    var upperClassButtons : [FilterButton] = []
    var lowerClassButtons : [FilterButton] = []
    
    //MARK: - init
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTitle(titleString: "Title")
    }
    
    init(style: UITableViewCellStyle, reuseIdentifier: String?, title: String, upperClasses: [String]?, lowerClasses: [String]? ) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupTitle(titleString: title)
        
        if upperClasses != nil {
            addClasses(classNames: upperClasses!, belowView: titleLabel, isUpper: true)
            if lowerClasses != nil {
                addClasses(classNames: lowerClasses!, belowView: upperClassButtons[0], isUpper: false)
            }
        }
        else {
            addClasses(classNames: lowerClasses!, belowView: titleLabel, isUpper: false)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Setup
    
    func setupTitle(titleString: String) {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = titleString
        titleLabel.textColor = .gray
        
        self.addSubview(titleLabel)
        
        let lConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
        let yConstraint = NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 5)
        
        self.addConstraints([lConstraint, yConstraint])
    }
    
    func addClasses(classNames: [String], belowView: UIView, isUpper: Bool) {
        var previousView: UIView = self
        
        for buttonName in classNames {
            let currentButton = FilterButton()
            currentButton.translatesAutoresizingMaskIntoConstraints = false
            currentButton.setTitle(buttonName, for: .normal)
            currentButton.addTarget(self, action: #selector(buttonSelected(sender:)), for: .touchUpInside)
            self.addSubview(currentButton)

            if isUpper {
                upperClassButtons.append(currentButton)
            }
            else {
                lowerClassButtons.append(currentButton)
            }
            
            let yConstraint = NSLayoutConstraint(item: currentButton, attribute: .top, relatedBy: .equal, toItem: belowView, attribute: .bottom, multiplier: 1, constant: 5)
            var xConstraint = NSLayoutConstraint()
            
            if buttonName == classNames[0] {
                xConstraint = NSLayoutConstraint(item: currentButton, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
            }
            else {
                xConstraint = NSLayoutConstraint(item: currentButton, attribute: .left, relatedBy: .equal, toItem: previousView, attribute: .right, multiplier: 1, constant: 15)
            }
            
            self.addConstraints([xConstraint, yConstraint])
            
            previousView = currentButton
        }
    }
    
    func buttonSelected (sender: FilterButton) {
        if (sender.isSelected){
            sender.isSelected = false
            sender.setupForUnselected()
        }
        else {
            if upperClassButtons.contains(item: sender) {
                for button in upperClassButtons {
                    button.isSelected = false
                    button.setupForUnselected()
                }
                
                sender.isSelected = true
                sender.setupForSelected()
                
            }
            else {
                for button in lowerClassButtons {
                    button.isSelected = false
                    button.setupForUnselected()
                }
                
                if sender.isSelected == false {
                    sender.isSelected = true
                    sender.setupForSelected()
                }
                else {
                    sender.isSelected = false
                    sender.isSelected = true
                }

            }
        }
    }

    override func getSelectedOptions(filterOptions: FilterOptionsObject) -> FilterOptionsObject {
//        for button in upperClassButtons {
//            if button.tag
//        }
        return filterOptions
    }
    
    override func getCellHeight() -> CGFloat {
        return 100
    }
}
