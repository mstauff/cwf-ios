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
    
    /** Creates the spinner view of the size specified by the given CGRect. This version was created because the other init (using constraints) didn't work well if the base view controller was a UITableViewController. There was issues with the constraints since they appeared to be relative to elements of the table. This ignores that and just positions itself on the screen independent of the table rows. */
    init( withAbsoluteFrame frame: CGRect) {
        super.init(frame:frame)
        // todo - should be able to move these 4 lines to a setupSpinner() method to share common elements between this and the other init
        spinner.center = CGPoint(x: frame.midX, y: frame.midY)
        setupSpinner()
        addSubview(spinner)
    }
    
    func setupSpinner() {
        self.translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
    }
    
    /** Create the spinner view with text using relative constraints */
    init(frame: CGRect, title: NSString) {
        super.init(frame: frame)
        setupSpinner()

        textLabel.text = ""
        textLabel.textColor = UIColor.white
        textLabel.translatesAutoresizingMaskIntoConstraints = false
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
