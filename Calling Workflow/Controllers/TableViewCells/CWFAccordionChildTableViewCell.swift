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
    var first_subtitle  : UILabel = UILabel()
    var second_subtitle : UILabel = UILabel()
    
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
        
        first_subtitle.translatesAutoresizingMaskIntoConstraints = false
        first_subtitle.font = UIFont(name: first_subtitle.font.fontName, size: 12.0)
        first_subtitle.adjustsFontSizeToFitWidth = true
        first_subtitle.textColor = UIColor.CWFDarkGreenColor

        second_subtitle.translatesAutoresizingMaskIntoConstraints = false
        second_subtitle.adjustsFontSizeToFitWidth = true
        
        self.addSubview(title)
        self.addSubview(first_subtitle)
        self.addSubview(second_subtitle)
        
       
        let titleWidthConstraint = NSLayoutConstraint(item: title, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -15)
        let titleHeightConstraint = NSLayoutConstraint(item: title, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 20)
        let titleHConstraint = NSLayoutConstraint(item: title, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 2 * horizontalMargin)
        let titleVConstraint = NSLayoutConstraint(item: title, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 5)
        let titleBConstraint = NSLayoutConstraint(item: title, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .bottom, multiplier: 1, constant: -5)
        
        self.addConstraints([titleWidthConstraint, titleHeightConstraint, titleHConstraint, titleVConstraint, titleBConstraint])

        let subWidthConstraint = NSLayoutConstraint(item: first_subtitle, attribute: .right, relatedBy: .equal, toItem: title, attribute: .right, multiplier: 1, constant: 0)
        let subHeightConstraint = NSLayoutConstraint(item: first_subtitle, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 15)
        let subHConstraint = NSLayoutConstraint(item: first_subtitle, attribute: .leading, relatedBy: .equal, toItem: title, attribute: .leading, multiplier: 1, constant: 0)
        let subVConstraint = NSLayoutConstraint(item: first_subtitle, attribute: .top, relatedBy: .equal, toItem: title, attribute: .bottom, multiplier: 1, constant: 2)
        
        self.addConstraints([subWidthConstraint, subHeightConstraint, subHConstraint, subVConstraint])
        
        let secondSubWConstraint = NSLayoutConstraint(item: second_subtitle, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -horizontalMargin)
        let secondSubHConstraint = NSLayoutConstraint(item: second_subtitle, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 20)
        let secondSubXConstraint = NSLayoutConstraint(item: second_subtitle, attribute: .leading, relatedBy: .equal, toItem: first_subtitle, attribute: .leading, multiplier: 1, constant: 0)
        let secondSubYConstraint = NSLayoutConstraint(item: second_subtitle, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -5)
        
        self.addConstraints([secondSubWConstraint, secondSubHConstraint, secondSubXConstraint, secondSubYConstraint])

    }
    
    class func getCellHeight () -> CGFloat {
        return 50.0
    }

}
