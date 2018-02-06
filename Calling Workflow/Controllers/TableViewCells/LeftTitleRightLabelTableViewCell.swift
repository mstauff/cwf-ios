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
    var dataLabel  : UILabel = UILabel()
    var warningButton : UIButton = UIButton()
    
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
        titleLabel.text = NSLocalizedString("Name", comment: "")
        self.contentView.addSubview(titleLabel)
        
        dataLabel.translatesAutoresizingMaskIntoConstraints = false
        dataLabel.textAlignment = .right
        dataLabel.adjustsFontSizeToFitWidth = true
        self.contentView.addSubview(dataLabel)
        
        warningButton.translatesAutoresizingMaskIntoConstraints = false
        warningButton.setTitle("⚠️", for: .normal)
        warningButton.isHidden = true
        
        self.contentView.addSubview(warningButton)
        
        addConstraints()
    }
    
    func addConstraints() {
        let views : [String: UIView] = ["titleLabel": titleLabel, "dataLabel": dataLabel, "warningButton": warningButton]
        let width = (1/4) * self.contentView.frame.width
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-15-[titleLabel(\(width))]-[warningButton(<=44)]-[dataLabel]-20-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: views)
        self.contentView.addConstraints(hConstraint)
        
        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[titleLabel(>=20)]-5-|", options: NSLayoutFormatOptions.alignAllLeft, metrics: nil, views: views)
        self.contentView.addConstraints(vConstraint)
        
        let dataVConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[dataLabel(>=20)]-5-|", options: NSLayoutFormatOptions.alignAllLeft, metrics: nil, views: views)
        self.contentView.addConstraints(dataVConstraint)
        
        let warningVConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[warningButton(>=20)]-5-|", options: NSLayoutFormatOptions.alignAllLeft, metrics: nil, views: views)
        self.contentView.addConstraints(warningVConstraint)
    }
    
    class func calculateHeight() -> CGFloat {
        var height : CGFloat = 0
        height += 44
        return height
    }

}
