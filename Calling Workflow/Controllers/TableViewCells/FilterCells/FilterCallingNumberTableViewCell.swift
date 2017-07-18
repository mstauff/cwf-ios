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
        titleLabel.textColor = UIColor.CWFGreyTextColor
        
        self.addSubview(titleLabel)
        
        let titleXConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
        let titleYConstraint = NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([titleXConstraint, titleYConstraint])
    }
    
    /**
     The number's for the number of callings. They are currently designed to be a series of successive increasing numbers, with the last one representing the last number and greater (i.e. 0, 1, 2, 3+). You can easily change the number of elements by just providing fewer or more numbers, but if deviating from the pattern code changes will probably be required. So changing to 0, 1, 2+ can be done via params, but if you want 2,4,6  then that would likely require code changes
     */
    func addNumberButtons (buttonsToAdd: [Int]) {
        var lastView : UIView = titleLabel
        for buttonInt in buttonsToAdd {
            let currentButton = FilterButton()
            // we also store the numerical value that the button represents in the button tag
            currentButton.tag = buttonInt
            numberButtonArray.append(currentButton)
            
            currentButton.setTitle(String(buttonInt), for: UIControlState.normal)
            // add the + to the last element
            if buttonInt == buttonsToAdd.last {
                currentButton.setTitle("\(buttonInt)+", for: .normal)
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
        }
        else {
            sender.setupForSelected()
        }
    }
    
    override func getCellHeight() -> CGFloat {
        return 44
    }
}

extension FilterCallingNumberTableViewCell : UIFilterElement {
    func getSelectedOptions( filterOptions: FilterOptions) -> FilterOptions {
        var filter = filterOptions
        var atLeastOneSelected = false
        var numCallingsSelections : [Int:Bool] = [:]
        // we're creating a dictionary of the number of callings and whether it should be filtered. i.e. [0:false, 1:true, 2:false, 3:false]
        // For some filters just adding the true elements  to the list would suffice, but because the last element in this list is always x+ (so 3 or more callings) the filter object needs to know the max value that was in the list to know where to apply the x+ behavior. So for this list of filter options we need to include all elements whether they're true or false (unless they're all false, then we can just leave it nil because there's nothing for the filter object to do).
        for button in numberButtonArray {
            numCallingsSelections[button.tag] = button.isSelected
            atLeastOneSelected = atLeastOneSelected || button.isSelected
        }
        if atLeastOneSelected {
            filter.callings = numCallingsSelections
        }
        return filter
    }
    
    func setSelectedOptions(filterOptions: FilterOptions) {
        guard let callings = filterOptions.callings  else {
            return
        }
        
        for (callingIdx, btnSelected) in callings {
            if callingIdx < numberButtonArray.count {
               let currentBtn = numberButtonArray[callingIdx]
                currentBtn.isSelected = btnSelected
                if btnSelected {
                    currentBtn.setupForSelected()
                }
            }
        }
    }

}
