//
//  ResetDataTableViewCell.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 12/15/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit
import Foundation

class MultiSelectTableViewCell : UITableViewCell {
    let titleLabel = UILabel()
    var isChecked = false {
        didSet {
            self.accessoryType = isChecked ? .checkmark : .none
        }
    }
    
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
    
    func setupCell () {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.adjustsFontSizeToFitWidth = true
        addSubview(titleLabel)
    }
    
    /** There's not a way to register an event handler with the cell, to automatically toggle itself, so we added this method for the TableViewController to call this method when the row is clicked. */
    func cellPressed() {
        isChecked = !isChecked
    }
    
    class func getCellHeight () -> CGFloat {
        return 50.0
    }

}
