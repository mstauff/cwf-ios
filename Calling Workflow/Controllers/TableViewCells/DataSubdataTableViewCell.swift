//
//  DataSubdataTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/23/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class DataSubdataTableViewCell: UITableViewCell {
    var mainLabel: UILabel = UILabel()
    
    let subLabel : UILabel = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setupCell() {
        mainLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(mainLabel)
        
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(subLabel)
        
        let mainXConstraint = NSLayoutConstraint(item: mainLabel, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: CWFMarginFloat())
        let mainYConstraint = NSLayoutConstraint(item: mainLabel, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 5)
        let mainWConstraint = NSLayoutConstraint(item: mainLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -CWFMarginFloat())
        let mainHConstraint = NSLayoutConstraint(item: mainLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 22)
        
        self.addConstraints([mainXConstraint, mainYConstraint, mainWConstraint, mainHConstraint])
        
        let subXConstraint = NSLayoutConstraint(item: subLabel, attribute: .leading, relatedBy: .equal, toItem: mainLabel, attribute: .leading, multiplier: 1, constant: CWFMarginFloat())
        let subYConstraint = NSLayoutConstraint(item: subLabel, attribute: .top, relatedBy: .equal, toItem: mainLabel, attribute: .bottom, multiplier: 1, constant: 2)
        let subWConstraint = NSLayoutConstraint(item: subLabel, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -CWFMarginFloat())
        let subHConstraint = NSLayoutConstraint(item: subLabel, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -5)
        
        self.addConstraints([subXConstraint, subYConstraint, subWConstraint, subHConstraint])
    }
    
    class func calculateHeight() -> CGFloat {
        var height: CGFloat = 5.0
        height += 60.0
        return height
    }

}
