//
//  DataSubdataTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 1/23/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class DataSubdataTableViewCell: UITableViewCell {
    @IBOutlet weak var mainLabel: UILabel!
    
    @IBOutlet weak var subLabel : UILabel?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    class func calculateHeight() -> CGFloat {
        var height: CGFloat = 0.0
        height += 60.0
        return height
    }

}
