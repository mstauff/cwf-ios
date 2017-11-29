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
    var firstSubviewLabel : UILabel = UILabel()
    var secondSubviewLabel : UILabel = UILabel()
    let thirdSubviewLabel : UILabel = UILabel()

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
        
        
        firstSubviewLabel.translatesAutoresizingMaskIntoConstraints = false
        firstSubviewLabel.lineBreakMode = .byTruncatingMiddle
            
        addSubview(firstSubviewLabel)
        
        let firstXConstraint = NSLayoutConstraint(item: firstSubviewLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 30)
        let firstYConstraint = NSLayoutConstraint(item: firstSubviewLabel, attribute: .top, relatedBy: .equal, toItem: nameLabel, attribute: .bottom, multiplier: 1, constant: 4)
        let firstWConstraint = NSLayoutConstraint(item: firstSubviewLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -15)
        let firstHConstraint = NSLayoutConstraint(item: firstSubviewLabel, attribute: .bottom, relatedBy: .lessThanOrEqual, toItem: self, attribute: .bottom, multiplier: 1, constant: -5)
        
        self.addConstraints([firstXConstraint, firstYConstraint, firstWConstraint, firstHConstraint])

        secondSubviewLabel.translatesAutoresizingMaskIntoConstraints = false
        secondSubviewLabel.lineBreakMode = .byTruncatingMiddle
        addSubview(secondSubviewLabel)
        
        let xConstraint = NSLayoutConstraint(item: secondSubviewLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 30)
        let yConstraint = NSLayoutConstraint(item: secondSubviewLabel, attribute: .top, relatedBy: .equal, toItem: firstSubviewLabel, attribute: .bottom, multiplier: 1, constant: 4)
        let wConstraint = NSLayoutConstraint(item: secondSubviewLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -15)
        let hConstraint = NSLayoutConstraint(item: secondSubviewLabel, attribute: .bottom, relatedBy: .lessThanOrEqual, toItem: self, attribute: .bottom, multiplier: 1, constant: -5)
        
        self.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])

        thirdSubviewLabel.translatesAutoresizingMaskIntoConstraints = false
        thirdSubviewLabel.lineBreakMode = .byTruncatingMiddle
        
        addSubview(thirdSubviewLabel)
        
        let thirdXConstraint = NSLayoutConstraint(item: thirdSubviewLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 30)
        let thirdYConstraint = NSLayoutConstraint(item: thirdSubviewLabel, attribute: .top, relatedBy: .equal, toItem: secondSubviewLabel, attribute: .bottom, multiplier: 1, constant: 4)
        let thirdWConstraint = NSLayoutConstraint(item: thirdSubviewLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -15)
        let thirdHConstraint = NSLayoutConstraint(item: thirdSubviewLabel, attribute: .bottom, relatedBy: .lessThanOrEqual, toItem: self, attribute: .bottom, multiplier: 1, constant: -5)
        
        self.addConstraints([thirdXConstraint, thirdYConstraint, thirdWConstraint, thirdHConstraint])
    }
    
    func setupCellLabels(member: MemberCallings) {
        nameLabel.text = member.member.name
      let callings = member.callings + member.proposedCallings
        switch callings.count {
        //Option one there are no callings set all calling labels to nil
        case 0:
            firstSubviewLabel.text = nil
            secondSubviewLabel.text = nil
            thirdSubviewLabel.text = nil
        
        //Option two there is one calling. Set the first calling text and the others to nil
        case 1:
            setupTextForLabel(calling: callings[0], member: member.member, label: firstSubviewLabel)
            secondSubviewLabel.text = nil
            thirdSubviewLabel.text = nil
        
        //Option three there are two callings. Set the first two and the third to nil
        case 2:
            setupTextForLabel(calling: callings[0], member: member.member, label: firstSubviewLabel)
            setupTextForLabel(calling: callings[1], member: member.member, label: secondSubviewLabel)
            thirdSubviewLabel.text = nil
        
        //Option four there is three callings. Set the text of all the subViews
        case 3:
            setupTextForLabel(calling: callings[0], member: member.member, label: firstSubviewLabel)
            setupTextForLabel(calling: callings[1], member: member.member, label: secondSubviewLabel)
            setupTextForLabel(calling: callings[2], member: member.member, label: thirdSubviewLabel)

        //Option five there are more than three callings. set the first two and then say there are more.
        default:
            setupTextForLabel(calling: callings[0], member: member.member, label: firstSubviewLabel)
            setupTextForLabel(calling: callings[1], member: member.member, label: secondSubviewLabel)
            thirdSubviewLabel.text = NSLocalizedString("\(callings.count - 2) more...", comment: "number of callings remaining")
            thirdSubviewLabel.textColor = UIColor.CWFGreyTextColor
        }
    }
    
    //Todo currently we are setting all inprogress callings to have green text. Do we need to change it?
    func setupTextForLabel(calling: Calling, member: Member, label: UILabel) {
        if calling.existingIndId == member.individualId {
            label.text = calling.nameWithTime
            label.textColor = UIColor.CWFGreyTextColor
        }
        else if calling.proposedIndId == member.individualId {
            label.text = calling.nameWithStatus
            label.textColor = UIColor.CWFGreenTextColor
        }
    }
    

}
