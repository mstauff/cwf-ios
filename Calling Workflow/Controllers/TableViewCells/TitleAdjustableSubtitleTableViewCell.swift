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
    
    func setupCell(subtitleCount: Int) {
        
        let sideMarginSize:CGFloat = 15.0
        let verticalMarginSize:CGFloat = 10.0
        let spacing : CGFloat = 2.0
        titleLabel.frame = CGRect(x: sideMarginSize, y: verticalMarginSize, width: self.frame.width - (2*sideMarginSize), height: 20)
        titleLabel.text = "Name"
        self.addSubview(titleLabel)
        if subtitleCount > 0 {
            for i in 0...subtitleCount-1 {
                let newLeftLabel = UILabel()
                newLeftLabel.frame = CGRect(x: 2 * sideMarginSize, y: titleLabel.frame.size.height + verticalMarginSize + ((spacing * CGFloat(i)) + CGFloat(i) * 20), width: 2/3*(self.frame.size.width - (2*sideMarginSize)), height: 20)
                newLeftLabel.font = UIFont(name: newLeftLabel.font.fontName, size: 15)
                newLeftLabel.text = "Subtitle"
                newLeftLabel.textColor = UIColor.lightGray
                self.leftSubtitles.append(newLeftLabel)
                self.addSubview(newLeftLabel)
                
                let newRightLabel = UILabel()
                newRightLabel.frame = CGRect(x: newLeftLabel.frame.size.width + spacing, y: titleLabel.frame.size.height + verticalMarginSize + ((spacing * CGFloat(i)) + CGFloat(i) * 20), width: 1/3*(self.frame.size.width - (2*sideMarginSize)), height: 20)
                newRightLabel.font = UIFont(name: newRightLabel.font.fontName, size: 15)
                newRightLabel.text = "Subtitle"
                newRightLabel.textColor = UIColor.lightGray
                newRightLabel.textAlignment = NSTextAlignment.right
                self.rightSubtitles.append(newRightLabel)
                self.addSubview(newRightLabel)

            }
        }
 
    }
    class func getHeightForCellForMember(member:Member) -> CGFloat {
        var cellHeight:CGFloat = 20 + 20
        cellHeight += (22 * CGFloat(member.currentCallings.count))
        print("memberCallings \(member.currentCallings.count)")
        return cellHeight
    }

}
