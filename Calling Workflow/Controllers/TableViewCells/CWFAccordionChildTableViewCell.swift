//
//  CWFAccordionChildTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 3/9/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class CWFAccordionChildTableViewCell: UITableViewCell {
    var title : UILabel = UILabel()
    var subtitle : UILabel = UILabel()
    var rightItem : UILabel = UILabel()
    
    //MARK: - Life Cycle
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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCell() {
        let horizontalMargin : CGFloat = 15.0
        self.backgroundColor = UIColor.groupTableViewBackground

        title.translatesAutoresizingMaskIntoConstraints = false
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.6
        title.lineBreakMode = .byTruncatingMiddle
        
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = UIFont(name: subtitle.font.fontName, size: 12.0)
        subtitle.adjustsFontSizeToFitWidth = true
        
        rightItem.translatesAutoresizingMaskIntoConstraints = false
        rightItem.adjustsFontSizeToFitWidth = true
        rightItem.textColor = UIColor.CWFDarkGreenColor
        
        self.addSubview(title)
        self.addSubview(subtitle)
        self.addSubview(rightItem)
        
        let rightItemWidthConstraint = NSLayoutConstraint(item: rightItem, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: (1/3), constant: 0)
        let rightItemHeightConstraint = NSLayoutConstraint(item: rightItem, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        let rightItemHConstraint = NSLayoutConstraint(item: rightItem, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -horizontalMargin)
        let rightItemVConstraint = NSLayoutConstraint(item: rightItem, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        
        self.addConstraints([rightItemWidthConstraint, rightItemHeightConstraint, rightItemHConstraint, rightItemVConstraint])
       
        let titleWidthConstraint = NSLayoutConstraint(item: title, attribute: .right, relatedBy: .equal, toItem: rightItem, attribute: .left, multiplier: 1, constant: -5)
        let titleHeightConstraint = NSLayoutConstraint(item: title, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 20)
        let titleHConstraint = NSLayoutConstraint(item: title, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 2 * horizontalMargin)
        let titleVConstraint = NSLayoutConstraint(item: title, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 5)
        
        let subWidthConstraint = NSLayoutConstraint(item: subtitle, attribute: .right, relatedBy: .equal, toItem: title, attribute: .right, multiplier: 1, constant: 0)
        let subHeightConstraint = NSLayoutConstraint(item: subtitle, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 15)
        let subHConstraint = NSLayoutConstraint(item: subtitle, attribute: .leading, relatedBy: .equal, toItem: title, attribute: .leading, multiplier: 1, constant: 0)
        let subVConstraint = NSLayoutConstraint(item: subtitle, attribute: .top, relatedBy: .equal, toItem: title, attribute: .bottom, multiplier: 1, constant: 2)
        
        self.addConstraints([titleWidthConstraint, titleHeightConstraint, titleHConstraint, titleVConstraint])
        self.addConstraints([subWidthConstraint, subHeightConstraint, subHConstraint, subVConstraint])
        
    }
    
    class func getCellHeight () -> CGFloat {
        return 50.0
    }

}
