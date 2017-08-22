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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell() {
        //button.frame = CGRect(x: 0, y: 0, width: 100, height: 20)
        self.contentView.addSubview(button)

        let xConstraint = NSLayoutConstraint(item: button, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: button, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1, constant: 0)
        let wConstraint = NSLayoutConstraint(item: button, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailing, multiplier: 1, constant: 0)
        let hConstraint = NSLayoutConstraint(item: button, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1, constant: 0)
        
        self.addConstraints([xConstraint, yConstraint, hConstraint])
    }
    
    func isButtonSelected() -> Bool {
        return button.isSelected
    }
}
