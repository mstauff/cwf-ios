//
//  FilterCallingNumberTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/12/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterCallingNumberTableViewCell: FilterBaseTableViewCell {

    var titleLabel : UILabel = UILabel()
    var numberButtonArray : [FilterButton] = []
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupTitle()
    }
    
    init(style: UITableViewCellStyle, reuseIdentifier: String?, numbers: [Int]?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupTitle()
        if numbers != nil {
            addNumberButtons(buttonsToAdd: numbers!)
        }
    }
    
    func setupTitle() {
        titleLabel.text = "Callings"
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .gray
        
        self.addSubview(titleLabel)
        
        let titleXConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
        let titleYConstraint = NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([titleXConstraint, titleYConstraint])
    }
    
    func addNumberButtons (buttonsToAdd: [Int]) {
        var lastView : UIView = titleLabel
        var buttonTag = 0
        for button in buttonsToAdd {
            let currentButton = FilterButton()
            currentButton.tag = buttonTag
            buttonTag += 1
            numberButtonArray.append(currentButton)
            
            if button != buttonsToAdd[buttonsToAdd.count-1]{
                currentButton.setTitle(String(button), for: UIControlState.normal)
            }
            else {
                currentButton.setTitle("\(button)+", for: .normal)
            }
            
            currentButton.addTarget(self, action: #selector(buttonSelected), for: .touchUpInside)
            
            self.addSubview(currentButton)
            
            let xConstraint = NSLayoutConstraint(item: currentButton, attribute: .left, relatedBy: .equal, toItem: lastView, attribute: .right, multiplier: 1, constant: 5)
            let yConstraint = NSLayoutConstraint(item: currentButton, attribute: .centerY, relatedBy: .equal, toItem: lastView, attribute: .centerY, multiplier: 1, constant: 0)
            
            self.addConstraints([xConstraint, yConstraint])
            
            lastView = currentButton
            
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    func buttonSelected (sender: FilterButton) {
        if sender.isSelected {
            sender.setupForUnselected()
            sender.isSelected = false
        }
        else {
//            for button in numberButtonArray {
//                button.isSelected = false
//                button.setupForUnselected()
//            }
//        
            sender.isSelected = true
            sender.setupForSelected()
        }
    }
    
    override func getSelectedOptions(filterOptions: FilterOptionsObject) -> FilterOptionsObject {
        for button in numberButtonArray {
            if button.isSelected {
                if filterOptions.callings == nil {
                    filterOptions.callings = [0: false, 1: false, 2: false, 3: false,]
                }
                filterOptions.callings?[button.tag] = true
            }
            else {
                filterOptions.callings?[button.tag] = false
            }
        }
        return filterOptions
    }
    
    override func getCellHeight() -> CGFloat {
        return 44
    }
}
