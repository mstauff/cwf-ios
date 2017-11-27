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
    
    func removeProcessingSpinner () {
        if let spinnerView = self.view.subviews.first( where: { $0 is CWFSpinnerView } ) {
            spinnerView.removeFromSuperview()
        }
    }
}
