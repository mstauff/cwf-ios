//
//  CWFAccordionRootTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 3/9/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class CWFAccordionRootTableViewCell: UITableViewCell {
    
    let titleLabel : UILabel = UILabel()
    let newButton : UIButton = UIButton()
    
    
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
        
        let buttonHeightConstraint = NSLayoutConstraint(item: newButton, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        let buttonWidthConstraint = NSLayoutConstraint(item: newButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 44)
        let buttonHConstraint = NSLayoutConstraint(item: newButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        let buttonVConstraint = NSLayoutConstraint(item: newButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        
        addConstraints([buttonWidthConstraint, buttonHeightConstraint, buttonHConstraint, buttonVConstraint])
        
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[titleLabel]-[newButton]-|", options: .alignAllFirstBaseline, metrics: nil, views: ["titleLabel" : titleLabel, "newButton" : newButton])
        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[titleLabel]-|", options: .alignAllLeading, metrics: nil, views: ["titleLabel" : titleLabel])
        
        addConstraints(hConstraint)
        addConstraints(vConstraint)
    }
    
    class func getCellHeight () -> CGFloat {
        return 50.0
    }
}