//
//  NameCallingProposedTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/7/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class NameCallingProposedTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var currentCallingLabel: UILabel!
    
    @IBOutlet weak var callingInProcessLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
