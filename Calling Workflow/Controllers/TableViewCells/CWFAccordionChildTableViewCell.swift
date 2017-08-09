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
    var warningButton : UIButton = UIButton()
    
    var callingForCell : Calling? = nil
    
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

        warningButton.translatesAutoresizingMaskIntoConstraints = false
        warningButton.backgroundColor = UIColor.CWFWarningBackgroundColor
        warningButton.setImage(UIImage.init(named: "warning"), for: .normal)
        //warningButton.isHidden = false
        
        title.translatesAutoresizingMaskIntoConstraints = false
        title.adjustsFontSizeToFitWidth = true
        title.minimumScaleFactor = 0.6
        title.lineBreakMode = .byTruncatingMiddle
        
        first_subtitle.translatesAutoresizingMaskIntoConstraints = false
        first_subtitle.font = UIFont(name: first_subtitle.font.fontName, size: 14.0)
        first_subtitle.adjustsFontSizeToFitWidth = true
        first_subtitle.textColor = UIColor.CWFDarkGreenColor

        second_subtitle.translatesAutoresizingMaskIntoConstraints = false
        second_subtitle.adjustsFontSizeToFitWidth = true
        second_subtitle.font = UIFont(name: second_subtitle.font.fontName, size: 14.0)

        self.addSubview(warningButton)
        self.addSubview(title)
        self.addSubview(first_subtitle)
        self.addSubview(second_subtitle)
        
        let buttonXConstraint = NSLayoutConstraint(item: warningButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        let buttonYConstraint = NSLayoutConstraint(item: warningButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let buttonHConstraint = NSLayoutConstraint(item: warningButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        let buttonWConstraint = NSLayoutConstraint(item: warningButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 50)
        
        self.addConstraints([buttonXConstraint, buttonYConstraint, buttonHConstraint, buttonWConstraint])

        let titleHConstraint = NSLayoutConstraint(item: title, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 2 * horizontalMargin)
        let titleWidthConstraint = NSLayoutConstraint(item: title, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -15)
        let titleHeightConstraint = NSLayoutConstraint(item: title, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 20)
        let titleVConstraint = NSLayoutConstraint(item: title, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 5)
        //let titleBConstraint = NSLayoutConstraint(item: title, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .bottom, multiplier: 1, constant: -5)
        
        self.addConstraints([titleWidthConstraint, titleHeightConstraint, titleHConstraint, titleVConstraint])

        let subWidthConstraint = NSLayoutConstraint(item: first_subtitle, attribute: .right, relatedBy: .equal, toItem: title, attribute: .right, multiplier: 1, constant: 0)
//        let subHeightConstraint = NSLayoutConstraint(item: first_subtitle, attribute: .bottom, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 20)
        let subHConstraint = NSLayoutConstraint(item: first_subtitle, attribute: .leading, relatedBy: .equal, toItem: title, attribute: .leading, multiplier: 1, constant: horizontalMargin*2)
        let subVConstraint = NSLayoutConstraint(item: first_subtitle, attribute: .top, relatedBy: .equal, toItem: title, attribute: .bottom, multiplier: 1, constant: 5)
        
        self.addConstraints([subWidthConstraint, subHConstraint, subVConstraint])
        
        let secondSubWConstraint = NSLayoutConstraint(item: second_subtitle, attribute: .trailing, relatedBy: .equal, toItem: title, attribute: .trailing, multiplier: 1, constant: 0)
        let secondSubHConstraint = NSLayoutConstraint(item: second_subtitle, attribute: .top, relatedBy: .equal, toItem: first_subtitle, attribute: .bottom, multiplier: 1, constant: 5)
        let secondSubXConstraint = NSLayoutConstraint(item: second_subtitle, attribute: .leading, relatedBy: .equal, toItem: first_subtitle, attribute: .leading, multiplier: 1, constant: 0)
        let secondSubYConstraint = NSLayoutConstraint(item: second_subtitle, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -5)
        
        self.addConstraints([secondSubWConstraint, secondSubHConstraint, secondSubXConstraint, secondSubYConstraint])

    }
    
    class func getCellHeight () -> CGFloat {
        return 50.0
    }

}
