//
//  NotesTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 2/22/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class NotesTableViewCell: UITableViewCell, UITextViewDelegate {
    let notesLabel = NSLocalizedString("Notes", comment: "notes text label")
    
    var textContents : String? {
        get {
            return noteTextView.text == notesLabel ? nil : noteTextView.text
        }
    }

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
        self.noteTextView.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell() {
        noteTextView.translatesAutoresizingMaskIntoConstraints = false
        noteTextView.text = notesLabel
        self.addSubview(noteTextView)
        
        initConstraints()
    }
    
    func initConstraints() {
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==15)-[noteView]-(==15)-|", options: .alignAllCenterY, metrics: nil, views: ["noteView": noteTextView])
        self.addConstraints(hConstraint)
        
        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[noteView]-|", options: .alignAllCenterX, metrics: nil, views: ["noteView" : noteTextView])
        self.addConstraints(vConstraint)
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if noteTextView.text == notesLabel {
            noteTextView.text = ""
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if noteTextView.text != nil && noteTextView.text.isEmpty {
            noteTextView.text = notesLabel
        }
    }
    
}
