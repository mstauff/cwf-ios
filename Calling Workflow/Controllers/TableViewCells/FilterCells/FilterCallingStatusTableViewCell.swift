//
//  FilterCallingStatusTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 6/16/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterCallingStatusTableViewCell: FilterBaseTableViewCell {

    var cellTitle : UILabel = UILabel()
    var statusButtonArray : [FilterButton] = []
    var callingStatuses : [CallingStatus] = []
    
    init(style: UITableViewCellStyle, reuseIdentifier: String?, callingStatuses : [CallingStatus]) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.callingStatuses = callingStatuses
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.callingStatuses = self.callingStatuses.filter() { !appDelegate.callingManager.statusToExcludeForUnit.contains(item: $0)}
        }
        setupCellTitle()
        setupStatusButtons()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCellTitle() {
        cellTitle.translatesAutoresizingMaskIntoConstraints = false
        cellTitle.numberOfLines = 0
        cellTitle.text = NSLocalizedString("Calling Status", comment: "")
        cellTitle.textColor = UIColor.CWFGreyTextColor

        self.addSubview(cellTitle)
        
        let xConstraint = NSLayoutConstraint(item: cellTitle, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 15)
        let yConstraint = NSLayoutConstraint(item: cellTitle, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 5)
        let wConstraint = NSLayoutConstraint(item: cellTitle, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -15)
        let hConstraint = NSLayoutConstraint(item: cellTitle, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30)
        
        self.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
    }
    
    func setupStatusButtons(){

        var buttonPosition = 0
        var lastElement : FilterButton? = nil
        var isFirst = true

        for buttonText in callingStatuses {
            let currentButton = FilterButton()
            currentButton.callingStatusOption = buttonText
            currentButton.setTitle(buttonText.description, for: .normal)
            currentButton.addTarget(self, action: #selector(buttonSelected(sender:)), for: .touchUpInside)
            currentButton.titleLabel?.adjustsFontSizeToFitWidth = true
            
            statusButtonArray.append(currentButton)
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
        let remainder : Double = Double(CallingStatus.userValues.count)/3.0 - Double(CallingStatus.userValues.count/3)
        if remainder != 0 {
            return CGFloat(30 + 29*((CallingStatus.userValues.count/3)+1))
        }
        else {
            return CGFloat(30 + 29*(CallingStatus.userValues.count/3))
        }
    }
}

extension FilterCallingStatusTableViewCell : UIFilterElement {
    /** Set the filter options based on what the user selected in the UI */
    func getSelectedOptions(filterOptions: FilterOptions) -> FilterOptions {
        var filterOptions = filterOptions
        // filter out anything that hasn't been selected. The callingStatusOption should always be set, but we make sure before we ! it
        // then we convert from the button to just the status it represents to go in the filterOptions
        filterOptions.callingStatuses = statusButtonArray.filter( { $0.isSelected && $0.callingStatusOption != nil } ).map( { $0.callingStatusOption! } )
        
        return filterOptions
    }

    /** Set the state of elements in the UI based on any filters that are set in the options */
    func setSelectedOptions(filterOptions: FilterOptions) {
        guard filterOptions.callingStatuses.isNotEmpty else {
            return
        }
        
        for button in statusButtonArray {
            if let btnStatus = button.callingStatusOption, filterOptions.callingStatuses.contains(item: btnStatus) {
                button.setupForSelected()
            }
        }
    }
}
