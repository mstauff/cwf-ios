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
    var genderButtonArray : [FilterButton] = []
        
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
        titleLabel.text = "Gender"
        titleLabel.textColor = .gray
        
        self.addSubview(titleLabel)
        
        let hConstraint = NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        let lConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
        let xConstraint = NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([hConstraint, lConstraint, xConstraint])
    }
    
    func setupAgeButtons() {
        
        let maleButton = FilterButton()
        genderButtonArray.append(maleButton)
        maleButton.setTitle("Male", for: UIControlState.normal)
        maleButton.translatesAutoresizingMaskIntoConstraints = false
        maleButton.addTarget(self, action: #selector(buttonSelected), for: .touchUpInside)
        
        self.addSubview(maleButton)
        
        let xConstraint = NSLayoutConstraint(item: maleButton, attribute: .left, relatedBy: .equal, toItem: titleLabel, attribute: .right, multiplier: 1, constant: 10)
        let yConstraint = NSLayoutConstraint(item: maleButton, attribute: .centerY, relatedBy: .equal, toItem: titleLabel, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([xConstraint, yConstraint])
        
        let femaleButton = FilterButton()
        genderButtonArray.append(femaleButton)
        femaleButton.setTitle("Female", for: UIControlState.normal)
        femaleButton.translatesAutoresizingMaskIntoConstraints = false
        femaleButton.layoutMargins = .init(top: 5, left: 5, bottom: 5, right: 5)
        
        femaleButton.addTarget(self, action: #selector(buttonSelected), for: .touchUpInside)
        
        self.addSubview(femaleButton)
        
        let xConstraint2 = NSLayoutConstraint(item: femaleButton, attribute: .left, relatedBy: .equal, toItem: maleButton, attribute: .right, multiplier: 1, constant: 10)
        let yConstraint2 = NSLayoutConstraint(item: femaleButton, attribute: .centerY, relatedBy: .equal, toItem: maleButton, attribute: .centerY, multiplier: 1, constant: 0)
        let wConstraint2 = NSLayoutConstraint(item: femaleButton, attribute: .width, relatedBy: .equal, toItem: maleButton, attribute: .width, multiplier: 1, constant: 0)
        
        self.addConstraints([xConstraint2, yConstraint2, wConstraint2])
        
    }
    
    func buttonSelected (sender: FilterButton) {
        for button in genderButtonArray {
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


