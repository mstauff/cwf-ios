//
//  LeftTitleRightLabelTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/6/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class LeftTitleRightLabelTableViewCell: UITableViewCell {

    let titleLabel : UILabel = UILabel()
    let dataLabel  : UILabel = UILabel()
    
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
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Name"
        self.contentView.addSubview(titleLabel)
        
        dataLabel.translatesAutoresizingMaskIntoConstraints = false
        dataLabel.textAlignment = NSTextAlignment.right
        self.contentView.addSubview(dataLabel)
        
        addConstraints()
    }
    
    func addConstraints() {
        let views = ["titleLabel": titleLabel, "dataLabel": dataLabel]
        let width = (1/3) * self.contentView.frame.width
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[titleLabel(\(width))]-[dataLabel]-20-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: views)
        self.contentView.addConstraints(hConstraint)
        
        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[titleLabel(>=20)]-5-|", options: NSLayoutFormatOptions.alignAllLeft, metrics: nil, views: views)
        self.contentView.addConstraints(vConstraint)
    }
    
    class func calculateHeight() -> CGFloat {
        var height : CGFloat = 0
        height += 44
        return height
    }

}
