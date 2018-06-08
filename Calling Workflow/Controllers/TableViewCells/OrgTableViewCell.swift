//
//  OrgTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 4/24/18.
//  Copyright © 2018 colsen. All rights reserved.
//

import UIKit

class OrgTableViewCell: UITableViewCell {

    @IBOutlet weak var conflictButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
