//
//  CWFSpinnerView.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 8/22/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class CWFSpinnerView: UIView {

    let textLabel : UILabel = UILabel()
    let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
    
    init(frame: CGRect, title: NSString) {
        super.init(frame: frame)
        self.translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)

        textLabel.text = "Loging In"
        textLabel.textColor = UIColor.white
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(textLabel)
        addSubview(spinner)

        let spinnerHConstraint = NSLayoutConstraint(item: spinner, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let textHConstraint = NSLayoutConstraint(item: textLabel, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let spinnerVConstraint = NSLayoutConstraint(item: spinner, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        let textVConstraint = NSLayoutConstraint(item: textLabel, attribute: .bottom, relatedBy: .equal, toItem: spinner, attribute: .top, multiplier: 1, constant: -15)
        
        addConstraints([spinnerHConstraint, textHConstraint, spinnerVConstraint, textVConstraint])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
