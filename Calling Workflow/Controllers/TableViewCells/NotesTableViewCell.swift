//
//  NotesTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/22/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class NotesTableViewCell: UITableViewCell {
    
    let noteTextView : UITextView = UITextView()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupCell()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell() {
        noteTextView.translatesAutoresizingMaskIntoConstraints = false
        noteTextView.text = "Notes"
        self.addSubview(noteTextView)
        
        initConstraints()
    }
    
    func initConstraints() {
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==15)-[noteView]-(==15)-|", options: .alignAllCenterY, metrics: nil, views: ["noteView": noteTextView])
        self.addConstraints(hConstraint)
        
        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[noteView]-|", options: .alignAllCenterX, metrics: nil, views: ["noteView" : noteTextView])
        self.addConstraints(vConstraint)
    }

}
