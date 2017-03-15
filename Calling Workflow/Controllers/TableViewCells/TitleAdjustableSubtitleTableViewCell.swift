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
    var leftSubtitles  : [UILabel] = []
    var rightSubtitles : [UILabel] = []
    var infoButton     : UIButton = UIButton()
    var buttonImageView: UIImageView = UIImageView()
    
    //MARK: - Life Cycle
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCell(subtitleCount: 0)
    }

    init(style: UITableViewCellStyle, reuseIdentifier: String?, subtitleCount: Int) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCell(subtitleCount: subtitleCount)
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
    func setupCell(subtitleCount: Int) {
        
        let sideMarginSize:CGFloat = 15.0
        let verticalMarginSize:CGFloat = 10.0
        let spacing : CGFloat = 2.0
        
        //titleLabel.frame = CGRect(x: sideMarginSize, y: verticalMarginSize, width: self.frame.width - (2*sideMarginSize), height: 20)
        titleLabel.text = "Name"
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
        let titleHConstraint = NSLayoutConstraint(item: titleLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: sideMarginSize)
        let titleWidthConstraint = NSLayoutConstraint(item: titleLabel, attribute: .right, relatedBy: .equal, toItem: infoButton, attribute: .left, multiplier: 1, constant: spacing)
        let titleVConstraint = NSLayoutConstraint(item: titleLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: verticalMarginSize)
        let titleHeightConstraint = NSLayoutConstraint(item: titleLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 20)

        let buttonHConstraint = NSLayoutConstraint(item: infoButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        let buttonVConstraint = NSLayoutConstraint(item: infoButton, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let buttonHeightConstraint = NSLayoutConstraint(item: infoButton, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        let buttonWidthConstraint = NSLayoutConstraint(item: infoButton, attribute: .width,  relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44)
        
        self.addConstraints([titleHConstraint, titleWidthConstraint, titleVConstraint, titleHeightConstraint, buttonHConstraint, buttonHeightConstraint, buttonVConstraint, buttonWidthConstraint])
        
        let buttonImageHeightConstraint = NSLayoutConstraint(item: buttonImageView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 30)
        let buttonImageWidthConstraint = NSLayoutConstraint(item: buttonImageView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1, constant: 30)
        let buttonImageHConstraint = NSLayoutConstraint(item: buttonImageView, attribute: .centerX, relatedBy: .equal, toItem: infoButton, attribute: .centerX, multiplier: 1, constant: 0)
        let buttonImageVConstraint = NSLayoutConstraint(item: buttonImageView, attribute: .centerY, relatedBy: .equal, toItem: infoButton, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints([buttonImageWidthConstraint, buttonImageHeightConstraint, buttonImageHConstraint, buttonImageVConstraint])
        
        var previousView : UIView = titleLabel
        
        if subtitleCount > 0 {
            for _ in 0...subtitleCount-1 {
                // init new left label
                let newLeftLabel = UILabel()
                newLeftLabel.translatesAutoresizingMaskIntoConstraints = false
                newLeftLabel.font = UIFont(name: newLeftLabel.font.fontName, size: 15)
                newLeftLabel.text = "Subtitle"
                newLeftLabel.textColor = UIColor.lightGray
                newLeftLabel.adjustsFontSizeToFitWidth = true
                //add to cell
                self.leftSubtitles.append(newLeftLabel)
                self.addSubview(newLeftLabel)
                
                // Add right label
                let newRightLabel = UILabel()
                newRightLabel.translatesAutoresizingMaskIntoConstraints = false
                newRightLabel.font = UIFont(name: newRightLabel.font.fontName, size: 15)
                newRightLabel.text = "Subtitle"
                newRightLabel.textColor = UIColor.lightGray
                newRightLabel.textAlignment = NSTextAlignment.right
                
                //Add rightLabel to cell
                self.rightSubtitles.append(newRightLabel)
                self.addSubview(newRightLabel)
                
                //add UI constraints
                let leadingMargin = sideMarginSize*2
                let hConstraint = NSLayoutConstraint(item: newLeftLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: leadingMargin)
                let rightHConstraint = NSLayoutConstraint(item: newRightLabel, attribute: .right, relatedBy: .equal, toItem: infoButton, attribute: .left, multiplier: 1, constant: -spacing)
                let sConstraint = NSLayoutConstraint(item: newLeftLabel, attribute: .right, relatedBy: .equal, toItem: newRightLabel, attribute: .left, multiplier: 1, constant: -spacing)
                let vConstraint = NSLayoutConstraint(item: newLeftLabel, attribute: .top, relatedBy: .equal, toItem: previousView, attribute: .bottom, multiplier: 1, constant: spacing*3)
                let rightVConstraint = NSLayoutConstraint(item: newRightLabel, attribute: .top, relatedBy: .equal, toItem: newLeftLabel, attribute: .top, multiplier: 1, constant: 0)
                let rightWConstraint = NSLayoutConstraint(item: newRightLabel, attribute: .width, relatedBy: .equal, toItem: titleLabel, attribute: .width, multiplier: (1.0/3.0), constant: 0)
                
                self.addConstraints([hConstraint, rightHConstraint, sConstraint])
                self.addConstraints([vConstraint, rightVConstraint, rightWConstraint])
                
                previousView = newLeftLabel

            }
        }
 
    }
    
    class func getHeightForCellForMember(member:Member) -> CGFloat {
        var cellHeight:CGFloat = 24 + 20
        cellHeight += (22 * CGFloat(member.currentCallings.count))
        return cellHeight
    }
}
