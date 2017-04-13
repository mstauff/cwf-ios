//
//  CWFButtonTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 4/11/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class CWFButtonTableViewCell: UITableViewCell {
    
    let cellButton = UIButton(type: UIButtonType.roundedRect)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.setupCell()
    }
    
    func setupCell() {
        cellButton.setTitle("Calling Actions", for: UIControlState.normal)
        cellButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(cellButton)
        
        let heightConstraint = NSLayoutConstraint(item: cellButton, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: -10)
        let widthConstraint  = NSLayoutConstraint(item: cellButton, attribute: .width,  relatedBy: .equal, toItem: self, attribute: .width,  multiplier: 1, constant: -10)
        let xConstraint = NSLayoutConstraint(item: cellButton, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let yConstraint = NSLayoutConstraint(item: cellButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([heightConstraint, widthConstraint, xConstraint, yConstraint])
        
    }
}
