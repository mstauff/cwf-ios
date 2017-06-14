//
//  NameCallingProposedTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/7/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class NameCallingProposedTableViewCell: UITableViewCell {

    var nameLabel: UILabel = UILabel()
    
    var currentCallingLabel: UILabel = UILabel()
    
    var callingInProcessLabel: UILabel = UILabel()
    
    //MARK: - Life Cycle
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
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

    func setupCell() {
        let horizontalMargin : CGFloat = 15.0
        let verticalMargin : CGFloat = 10.0
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(nameLabel)

        let nameLConstraint = NSLayoutConstraint(item: nameLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: horizontalMargin)
        let nameRConstraint = NSLayoutConstraint(item: nameLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -horizontalMargin)
        let nameYConstraint = NSLayoutConstraint(item: nameLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: verticalMargin)
        let nameHConstraint = NSLayoutConstraint(item: nameLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 22)
        
        self.addConstraints([nameLConstraint, nameRConstraint, nameYConstraint, nameHConstraint])
        
        callingInProcessLabel.translatesAutoresizingMaskIntoConstraints = false
        callingInProcessLabel.numberOfLines = 0
        callingInProcessLabel.font = UIFont(name: callingInProcessLabel.font.fontName, size: 14)
        
        self.addSubview(callingInProcessLabel)
        
        let inProcessXConstraint = NSLayoutConstraint(item: callingInProcessLabel, attribute: .leading, relatedBy: .equal, toItem: nameLabel, attribute: .leading, multiplier: 1, constant: horizontalMargin)
        let inProcessYConstraint = NSLayoutConstraint(item: callingInProcessLabel, attribute: .top, relatedBy: .equal, toItem: nameLabel, attribute: .bottom, multiplier: 1, constant: 0)
        let inProcessWConstraint = NSLayoutConstraint(item: callingInProcessLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -horizontalMargin)
        let inProcessHConstraint = NSLayoutConstraint(item: callingInProcessLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 20)
        
        self.addConstraints([inProcessXConstraint, inProcessYConstraint, inProcessWConstraint, inProcessHConstraint])
        
        currentCallingLabel.translatesAutoresizingMaskIntoConstraints = false
        currentCallingLabel.numberOfLines = 0
        currentCallingLabel.font = UIFont(name: currentCallingLabel.font.fontName, size: 14)
        
        self.addSubview(currentCallingLabel)

        let currentXConstraint = NSLayoutConstraint(item: currentCallingLabel, attribute: .leading, relatedBy: .equal, toItem: callingInProcessLabel, attribute: .leading, multiplier: 1, constant: 0)
        let currentYConstraint = NSLayoutConstraint(item: currentCallingLabel, attribute: .top, relatedBy: .equal, toItem: callingInProcessLabel, attribute: .bottom, multiplier: 1, constant: 0)
        let currentWConstraint = NSLayoutConstraint(item: currentCallingLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -horizontalMargin)
        let currentHConstraint = NSLayoutConstraint(item: currentCallingLabel, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -verticalMargin)
        
        self.addConstraints([currentXConstraint, currentYConstraint, currentWConstraint, currentHConstraint])
        
    }
    
}
