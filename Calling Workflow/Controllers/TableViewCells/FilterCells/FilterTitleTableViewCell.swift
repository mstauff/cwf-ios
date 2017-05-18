//
//  FilterTitleTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/9/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterTitleTableViewCell: FilterBaseTableViewCell {

    let titleLabel : UILabel = UILabel()
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
        
    init(style: UITableViewCellStyle, reuseIdentifier: String?, title: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.selectionStyle = .none
        titleLabel.text = title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = UIColor.gray
        titleLabel.font = UIFont(name: titleLabel.font.fontName, size: 24)
        
        
        self.addSubview(titleLabel)
        
        let titleLConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
        let titleRConstraint = NSLayoutConstraint(item: titleLabel, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -15)
        let titleHConstraint = NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        let titleYConstraint = NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([titleLConstraint, titleRConstraint, titleHConstraint, titleYConstraint])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getCellHeight() -> CGFloat {
        return 44
    }
    
}
