//
//  CallingPickerCustomTableViewCell.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 5/25/18.
//  Copyright © 2018 colsen. All rights reserved.
//

import UIKit

class CallingPickerCustomTableViewCell: UITableViewCell {

    let titleField : UITextField = UITextField()
    let doneButton : UIButton = UIButton()
    let firstButton : UIButton = UIButton()
    
    var delegate : CallingPickerCustomCellDelegate? = nil
    
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
        super.init(coder: aDecoder)
    }
    
    func setupCell() {
        //Add the textfield to the view
        titleField.translatesAutoresizingMaskIntoConstraints = false
        titleField.isHidden = true
        titleField.placeholder = NSLocalizedString("Calling Title", comment: "custom title for calling")
        
        self.addSubview(titleField)
        
        //Add the first button to the view
        firstButton.translatesAutoresizingMaskIntoConstraints = false
        firstButton.setTitle(NSLocalizedString("Add Custom Calling", comment: "Custom Calling"), for: .normal)
        firstButton.setTitleColor(UIColor.CWFNavBarTintColor, for: .normal)
        firstButton.addTarget(self, action: #selector(setupViewForInput), for: .touchUpInside)
        
        self.addSubview(firstButton)
        
        //add The done button to the view
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        doneButton.setTitle("Done", for: .normal)
        doneButton.setTitleColor(UIColor.CWFNavBarTintColor, for: .normal)
        doneButton.addTarget(self, action: #selector(returnCustomTitle), for: .touchUpInside)
        doneButton.isHidden = true
       
        self.addSubview(doneButton)

        // Add constraints for the first button
        let firstButtonXConstraint = NSLayoutConstraint(item: firstButton, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: CWFMarginFloat())
        let firstButtonYConstraint = NSLayoutConstraint(item: firstButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        let firstButtonWConstraint = NSLayoutConstraint(item: firstButton, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: -CWFMarginFloat())
        let firstButtonHConstraint = NSLayoutConstraint(item: firstButton, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        
        self.addConstraints([firstButtonXConstraint, firstButtonYConstraint, firstButtonWConstraint, firstButtonHConstraint])

        // Add constraints for the titleField
        let mainXConstraint = NSLayoutConstraint(item: titleField, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: CWFMarginFloat())
        let mainYConstraint = NSLayoutConstraint(item: titleField, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        let mainWConstraint = NSLayoutConstraint(item: titleField, attribute: .trailing, relatedBy: .equal, toItem: doneButton, attribute: .leading, multiplier: 1, constant: -5)
        let mainHConstraint = NSLayoutConstraint(item: titleField, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 22)
        
        self.addConstraints([mainXConstraint, mainYConstraint, mainWConstraint, mainHConstraint])
        
        //Done Button Constraints
        let doneXConstraint = NSLayoutConstraint(item: doneButton, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -CWFMarginFloat())
        let doneYConstraint = NSLayoutConstraint(item: doneButton, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        let doneWConstraint = NSLayoutConstraint(item: doneButton, attribute: .width, relatedBy: .equal, toItem: doneButton, attribute: .height, multiplier: 1, constant: 0)
        let doneHConstraint = NSLayoutConstraint(item: doneButton, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 1, constant: 0)
        
        self.addConstraints([doneXConstraint, doneYConstraint, doneWConstraint, doneHConstraint])
    }
    
    func setupViewForInput () {
        //setting up buttons to show for input
        print("button pressed")
        firstButton.isHidden = true
        doneButton.isHidden = false
        titleField.isHidden = false
        titleField.becomeFirstResponder()
    }
    
    func returnCustomTitle () {
        if let returnDelegate = delegate, let returnString = titleField.text {
            returnDelegate.setCustomTitle(titleString: returnString)
        }
    }
}
