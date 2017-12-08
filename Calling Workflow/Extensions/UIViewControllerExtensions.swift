//
//  UIViewControllerExtensions.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 11/22/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import Foundation
protocol ProcessingSpinner {
}

extension ProcessingSpinner where Self:UIViewController {
    
    func startProcessingSpinner( labelText : String ) {
        let spinView = CWFSpinnerView(frame: CGRect.zero, title: NSLocalizedString(labelText, comment: labelText) as NSString)
        
        self.view.addSubview(spinView)
        
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==0)-[spinnerView]-(==0)-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: ["spinnerView": spinView])
        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[spinnerView]-|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: ["spinnerView": spinView])
        
        self.view.addConstraints(hConstraint)
        self.view.addConstraints(vConstraint)
    }
    
    /** This version of the spinner uses exact positioning rather than relative constraints. The other method is preferred, but it won't work in cases where the root view controller is a UITableViewController rather than a UIViewController (the constraints don't work correctly when adding to a UITableViewController */
    func startStaticFrameProcessingSpinner() {
        let x = UIScreen.main.bounds.size.width
        let y = UIScreen.main.bounds.size.height
        let sizeRect = CGRect.init(x: 0, y: 0, width: x, height:y )
        let spinView = CWFSpinnerView( withAbsoluteFrame:sizeRect)
        
        self.view.addSubview(spinView)

    }
    
    func removeProcessingSpinner () {
        if let spinnerView = self.view.subviews.first( where: { $0 is CWFSpinnerView } ) {
            spinnerView.removeFromSuperview()
        }
    }
}
