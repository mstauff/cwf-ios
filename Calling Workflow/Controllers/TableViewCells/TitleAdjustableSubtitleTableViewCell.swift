//
//  TitleAdjustableSubtitleTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/3/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class TitleAdjustableSubtitleTableViewCell: UITableViewCell {

    var titleLabel     : UILabel = UILabel()
    var subtitle       : UILabel = UILabel()
    var infoButton     : UIButton = UIButton()
    var buttonImageView: UIImageView = UIImageView()
    
    //MARK: - Life Cycle
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
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
    
    //MARK: - Cell Setup
    func setupCell() {
        
        let sideMarginSize:CGFloat = 15.0
        let verticalMarginSize:CGFloat = 10.0
        let spacing : CGFloat = 2.0
        
        //titleLabel.frame = CGRect(x: sideMarginSize, y: verticalMarginSize, width: self.frame.width - (2*sideMarginSize), height: 20)
        titleLabel.text = NSLocalizedString("Name", comment: "")
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(titleLabel)
       
        infoButton.backgroundColor = UIColor.clear
        infoButton.translatesAutoresizingMaskIntoConstraints = false
        
        buttonImageView.image = UIImage(named: "contacts")
        buttonImageView.translatesAutoresizingMaskIntoConstraints = false
        buttonImageView.isUserInteractionEnabled = false
        
        self.addSubview(infoButton)
        self.addSubview(buttonImageView)
        
        //let titleHConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-\(sideMarginSize)-[titleLabel]-\(spacing)-[infoButton]-|", options: .directionLeadingToTrailing, metrics: nil, views: ["titleLabel" : titleLabel, "infoButton" : infoButton])
        let titleXConstraint = NSLayoutConstraint(item: titleLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: sideMarginSize)
        let titleYConstraint = NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: verticalMarginSize)
        let titleWConstraint = NSLayoutConstraint(item: titleLabel, attribute: .trailing, relatedBy: .equal, toItem: infoButton, attribute: .leading, multiplier: 1, constant: spacing)
        let titleHConstraint = NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 20)

        let buttonHConstraint = NSLayoutConstraint(item: infoButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        let buttonVConstraint = NSLayoutConstraint(item: infoButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let buttonHeightConstraint = NSLayoutConstraint(item: infoButton, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        let buttonWidthConstraint = NSLayoutConstraint(item: infoButton, attribute: .width,  relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44)
        
        self.addConstraints([titleHConstraint, titleWConstraint, titleXConstraint, titleYConstraint, buttonHConstraint, buttonHeightConstraint, buttonVConstraint, buttonWidthConstraint])
        
        let buttonImageHeightConstraint = NSLayoutConstraint(item: buttonImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30)
        let buttonImageWidthConstraint = NSLayoutConstraint(item: buttonImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 30)
        let buttonImageHConstraint = NSLayoutConstraint(item: buttonImageView, attribute: .centerX, relatedBy: .equal, toItem: infoButton, attribute: .centerX, multiplier: 1, constant: 0)
        let buttonImageVConstraint = NSLayoutConstraint(item: buttonImageView, attribute: .centerY, relatedBy: .equal, toItem: infoButton, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([buttonImageWidthConstraint, buttonImageHeightConstraint, buttonImageHConstraint, buttonImageVConstraint])
        
        // init new left label
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = UIFont(name: subtitle.font.fontName, size: 15)
        subtitle.textColor = UIColor.lightGray
        subtitle.adjustsFontSizeToFitWidth = false
        subtitle.numberOfLines = 0
        
        //add to cell
        self.addSubview(subtitle)
        
        
        //add UI constraints
        let leadingMargin = sideMarginSize*2
        
        let xConstraint = NSLayoutConstraint(item: subtitle, attribute: .leading, relatedBy: .equal, toItem: self,       attribute: .leading, multiplier: 1, constant: leadingMargin)
        let yConstraint = NSLayoutConstraint(item: subtitle, attribute: .top,     relatedBy: .equal, toItem: titleLabel, attribute: .bottom,  multiplier: 1, constant: spacing)
        let wConstraint = NSLayoutConstraint(item: subtitle, attribute: .right,   relatedBy: .equal, toItem: infoButton, attribute: .left,    multiplier: 1, constant: -spacing)
        let hConstraint = NSLayoutConstraint(item: subtitle, attribute: .bottom,  relatedBy: .equal, toItem: self,       attribute: .bottom,  multiplier: 1, constant: -verticalMarginSize)
        
        self.addConstraints([xConstraint, yConstraint, wConstraint, hConstraint])
        
    }
    
    class func getHeightForCellForMember(member:Member) -> CGFloat {
        var cellHeight:CGFloat = 24 + 20
        // todo - need to change this to MemberCallings object
//        cellHeight += (22 * CGFloat(member.currentCallings.count))
        return cellHeight
    }
}
