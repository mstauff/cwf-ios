//
//  FilterApplyButtonTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/17/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterApplyButtonTableViewCell: FilterBaseTableViewCell {
    
    var cancelButton : UIButton = UIButton()
    var applyButton : UIButton = UIButton()
    let topLineView : UIView = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        topLineView.translatesAutoresizingMaskIntoConstraints = false
        topLineView.backgroundColor = .gray
        topLineView.isUserInteractionEnabled = false
        
        self.addSubview(topLineView)
        
        let lineLConstraint = NSLayoutConstraint(item: topLineView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0)
        let lineRConstraint = NSLayoutConstraint(item: topLineView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        let lineYConstraint = NSLayoutConstraint(item: topLineView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let lineHConstraint = NSLayoutConstraint(item: topLineView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 2)
        
        self.addConstraints([lineLConstraint, lineRConstraint, lineYConstraint, lineHConstraint])
        
        applyButton.setTitle(NSLocalizedString("Apply", comment: "apply"), for: .normal)
        applyButton.setTitleColor(UIColor.CWFDarkGreenColor, for: .normal)
        applyButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(applyButton)
        
        let applyRConstraint = NSLayoutConstraint(item: applyButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -15)
        let applyYConstraint = NSLayoutConstraint(item: applyButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 5)
        let applyHConstraint = NSLayoutConstraint(item: applyButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -5)
        
        self.addConstraints([applyRConstraint, applyYConstraint, applyHConstraint])
        
        cancelButton.setTitle(NSLocalizedString("Cancel", comment: "cancel"), for: .normal)
        cancelButton.setTitleColor(UIColor.gray, for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(cancelButton)
        
        let cancelRConstraint = NSLayoutConstraint(item: cancelButton, attribute: .right, relatedBy: .equal, toItem: applyButton, attribute: .left, multiplier: 1, constant: -15)
        let cancelYConstraint = NSLayoutConstraint(item: cancelButton, attribute: .top, relatedBy: .equal, toItem: applyButton, attribute: .top, multiplier: 1, constant: 0)
        let cancelWConstraint = NSLayoutConstraint(item: cancelButton, attribute: .width, relatedBy: .equal, toItem: applyButton, attribute: .width, multiplier: 1, constant: 0)
        self.addConstraints([cancelRConstraint, cancelYConstraint, cancelWConstraint])
    }
    
    class func getClassCellHeight() -> CGFloat {
        return 46
    }
}
