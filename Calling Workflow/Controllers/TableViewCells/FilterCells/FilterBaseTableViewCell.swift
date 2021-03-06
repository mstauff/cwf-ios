//
//  FilterBaseTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/16/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class FilterBaseTableViewCell: UITableViewCell {
    
    var filterDelegate : FilterTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func getCellHeight() -> CGFloat {
        return 44
    }
    
}

protocol UIFilterElement {
    // get the filter options object based on the state of the UI
    func getSelectedOptions (filterOptions: FilterOptions) -> FilterOptions
    // set the UI based on the filter options object
    func setSelectedOptions (filterOptions: FilterOptions)
}
