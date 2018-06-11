//
//  CWFAccordionRootTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 3/9/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class UIButtonWithOrg: UIButton {
    var buttonOrg : Org? = nil
}

class CWFAccordionRootTableViewCell: UITableViewCell {
    
    let titleLabel : UILabel = UILabel()
    let newButton : UIButtonWithOrg = UIButtonWithOrg()

    
    //MARK: - Life Cycle
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCell()
    }
    
    init(style: UITableViewCellStyle, reuseIdentifier: String?, subtitleCount: Int) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setupCell () {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontSizeToFitWidth = true
        
        newButton.translatesAutoresizingMaskIntoConstraints = false
        newButton.setBackgroundImage(UIImage.init(named:"add"), for: .normal)
        newButton.isHidden = true
        
        
        addSubview(titleLabel)
        addSubview(newButton)
        
        let buttonHeightConstraint = NSLayoutConstraint(item: newButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44)
        let buttonWidthConstraint = NSLayoutConstraint(item: newButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 44)
        let buttonHConstraint = NSLayoutConstraint(item: newButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        let buttonVConstraint = NSLayoutConstraint(item: newButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        addConstraints([buttonWidthConstraint, buttonHeightConstraint, buttonHConstraint, buttonVConstraint])
        
        let titleHeightConstraint = NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44)
        let titleLeftConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
        let titleRightConstraint = NSLayoutConstraint(item: titleLabel, attribute: .right, relatedBy: .equal, toItem: newButton, attribute: .left, multiplier: 1, constant: -5)
        let titleVConstraint = NSLayoutConstraint(item: titleLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        addConstraints([titleHeightConstraint, titleLeftConstraint, titleRightConstraint, titleVConstraint])

    }
    
    class func getCellHeight () -> CGFloat {
        return 50.0
    }
}
