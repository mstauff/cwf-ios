//
//  FilterButton.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/12/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterButton: UIButton {

    required init() {
        super.init(frame: .zero)
        setupForUnselected()
        self.layer.cornerRadius = 12.0
        self.titleLabel?.font = UIFont(name: (self.titleLabel?.font.fontName)!, size: 14)
        self.titleEdgeInsets.left = 5
        self.titleEdgeInsets.right = 5
        self.clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupForUnselected () {
        self.backgroundColor = UIColor.clear
        self.setTitleColor(UIColor.gray, for: .normal)
    }

    func setupForSelected () {
        self.backgroundColor = UIColor.CWFNavBarTintColor
        self.setTitleColor(.white, for: .normal)
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
