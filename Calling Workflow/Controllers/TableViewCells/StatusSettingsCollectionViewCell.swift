//
//  StatusSettingsCollectionViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 8/14/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class StatusSettingsCollectionViewCell: UICollectionViewCell {
    
    let button : FilterButton = FilterButton()
    var callingStatus : CallingStatus? = nil
    var delegate : StatusSettingsCollectionViewCellDelegate? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //self.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell() {
        button.frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        button.addTarget(self, action: #selector(buttonSelected(sender:)), for: .touchUpInside)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        
        self.contentView.addSubview(button)

//        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[button(100)]-|", options: .alignAllCenterY, metrics: nil, views: ["button" : button])
//        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[button(40)]-|", options: .alignAllCenterX, metrics: nil, views: ["button" : button])
        
//        addConstraints(hConstraint)
//        addConstraints(vConstraint)
        
//        let xConstraint = NSLayoutConstraint(item: button, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1, constant: 0)
//        let yConstraint = NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1, constant: 0)
//        let wConstraint = NSLayoutConstraint(item: button, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailing, multiplier: 1, constant: 0)
//        let hConstraint = NSLayoutConstraint(item: button, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .bottom, multiplier: 1, constant: 40)
//        
//        self.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
    }
    
    override func prepareForReuse() {
        if button.isSelected {
            if let cellDelegate = delegate, let status = callingStatus {
                cellDelegate.updateStatusSettings(status: status)
            }
        }
    }
    
    func isButtonSelected() -> Bool {
        return button.isSelected
    }
    func buttonSelected (sender: FilterButton) {
        if sender.isSelected {
            sender.setupForUnselected()
        }
        else {
            sender.setupForSelected()
        }
    }
    
}
