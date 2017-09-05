//
//  SingleFieldTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/13/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class SingleFieldTableViewCell: UITableViewCell {
    
    let textField = UITextField()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupCell() {
        textField.text = ""
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(textField)
        

        setupConstraints()
        
    }
    
    func setupConstraints() {
        
        let views = ["textField": textField]
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "|-15-[textField]-15-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: views)
        self.addConstraints(hConstraint)
        let vConstraint = NSLayoutConstraint(item: textField, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        //let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "|-[textField]-|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: views)
        self.addConstraints([vConstraint])
    }
}
