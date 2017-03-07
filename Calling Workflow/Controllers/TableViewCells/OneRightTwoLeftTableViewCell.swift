//
//  OneRightTwoLeftTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/7/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class OneRightTwoLeftTableViewCell: UITableViewCell {

    let titleLabel : UILabel = UILabel()
    let dataLabel  : UILabel = UILabel()
    let subdataLabel : UILabel = UILabel()
    
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
        self.addSubview(titleLabel)
        
        dataLabel.translatesAutoresizingMaskIntoConstraints = false
        dataLabel.textAlignment = NSTextAlignment.right
        self.addSubview(dataLabel)
        
        subdataLabel.translatesAutoresizingMaskIntoConstraints = false
        subdataLabel.textAlignment = NSTextAlignment.right
        subdataLabel.font = UIFont(name: subdataLabel.font.fontName, size: 14)
        self.addSubview(subdataLabel)
        
        addConstraints()
    }
    
    func addConstraints() {
        let views = ["titleLabel" : titleLabel, "dataLabel" : dataLabel, "subdataLabel" : subdataLabel]
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[titleLabel]-[dataLabel(==titleLabel)]-15-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: views)
        self.addConstraints(hConstraint)
        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[dataLabel][subdataLabel]-|", options: NSLayoutFormatOptions.alignAllRight, metrics: nil, views: views)
        self.addConstraints(vConstraint)
    }
    
    class func calculateHeight() -> CGFloat {
        var height : CGFloat = 0
        height += 60
        return height
    }
    
}
