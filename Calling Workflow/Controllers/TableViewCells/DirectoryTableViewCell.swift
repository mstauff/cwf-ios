//
//  DirectoryTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 6/23/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class DirectoryTableViewCell: UITableViewCell {
    
    let nameLabel : UILabel = UILabel()
    let callingLabels : [UILabel] = []

    //MARK: - Life Cycle
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Setup
    func setupCell() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(nameLabel)
        
        let nameXConstraint = NSLayoutConstraint(item: nameLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 15)
        let nameYConstraint = NSLayoutConstraint(item: nameLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 2)
        let nameWConstraint = NSLayoutConstraint(item: nameLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -15)
        let nameHConstraint = NSLayoutConstraint(item: nameLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30)
        
        self.addConstraints([nameXConstraint, nameYConstraint, nameWConstraint, nameHConstraint])
        
        var lastView = nameLabel
        
        for callingLabel in callingLabels {
            callingLabel.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(callingLabel)
            
            let xConstraint = NSLayoutConstraint(item: callingLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 30)
            let yConstraint = NSLayoutConstraint(item: callingLabel, attribute: .top, relatedBy: .equal, toItem: lastView, attribute: .bottom, multiplier: 1, constant: 4)
            let wConstraint = NSLayoutConstraint(item: callingLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -15)
            let hConstraint = NSLayoutConstraint(item: callingLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 17)
            
            self.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
            
            lastView = callingLabel
        }
    }
    func setupCallingLabels(member: MemberCallings) {
        let currentLabel = UILabel()
        currentLabel.translatesAutoresizingMaskIntoConstraints = false
        for calling in member.callings{
            currentLabel.text = calling.nameWithTime
        }
        for calling in member.proposedCallings {
            currentLabel.text = calling.nameWithStatus
            currentLabel.textColor = UIColor.green
        }
        
        setupCell()
    }
}
