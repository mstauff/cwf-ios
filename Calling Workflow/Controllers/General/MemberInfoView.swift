//
//  MemberInfoView.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 3/2/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit

class MemberInfoView: UIView {
    
    var memberToView: Member?
    
    var infoView : UIView = UIView()
    var headerView : UIView = UIView()

    var tapRecognizer: UIGestureRecognizer? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.75)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView(member: Member, parentView: UIView) {
        self.memberToView = member
        
        setupInfoView()

        setupHeaderView()
        
        tapRecognizer = UITapGestureRecognizer(target: self, action:#selector(dismissMemberDetails(_:)))
        parentView.addGestureRecognizer(tapRecognizer!)


    }
    
    func setupHeaderView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor.CWFNavBarTintColor
        
        self.addSubview(headerView)

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = UIColor.white
        nameLabel.text = memberToView?.name
        
        headerView.addSubview(nameLabel)
        
        let headerWidthConstraint = NSLayoutConstraint(item: headerView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0)
        let headerHeightConstraint = NSLayoutConstraint(item: headerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44)
        let headerHorizontalConstraint = NSLayoutConstraint(item: headerView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let headerVirticalConstraint = NSLayoutConstraint(item: headerView, attribute: .bottom, relatedBy: .equal, toItem: infoView, attribute: .top, multiplier: 1, constant: 0)
        
        self.addConstraints([headerWidthConstraint, headerHeightConstraint, headerHorizontalConstraint, headerVirticalConstraint])

        let hConstraint = NSLayoutConstraint(item: nameLabel, attribute: .centerX, relatedBy: .equal, toItem: headerView, attribute: .centerX, multiplier: 1, constant: 0)
        let vConstraint = NSLayoutConstraint(item: nameLabel, attribute: .centerY, relatedBy: .equal, toItem: headerView, attribute: .centerY, multiplier: 1, constant: 0)
        self.addConstraints([hConstraint, vConstraint])

    }
    
    func setupInfoView() {
        
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.backgroundColor = UIColor.white
        
        
        self.addSubview(infoView)
        
        let infoHConstraint = NSLayoutConstraint(item: infoView, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 0.5, constant: 0)
        let infoWConstraint = NSLayoutConstraint(item: infoView, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1, constant: 0)
        let infoVConstraint = NSLayoutConstraint(item: infoView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        let infoHoConstraint = NSLayoutConstraint(item: infoView, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        
        self.addConstraints([infoHConstraint, infoWConstraint, infoVConstraint, infoHoConstraint])
        
        let callingsText = UILabel()
        callingsText.font = UIFont(name: callingsText.font.fontName, size: 14)
        callingsText.textColor = UIColor.gray
        callingsText.translatesAutoresizingMaskIntoConstraints = false
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        callingsText.text = appDelegate?.callingManager.getCallingsForMemberAsStringWithMonths(member: memberToView!)
        callingsText.numberOfLines = 0
        
        infoView.addSubview(callingsText)

        let firstBar = UIView()
        firstBar.translatesAutoresizingMaskIntoConstraints = false
        firstBar.backgroundColor = UIColor.darkGray

        infoView.addSubview(firstBar)
        let phoneLabel = UILabel()
        phoneLabel.translatesAutoresizingMaskIntoConstraints = false
        phoneLabel.textColor = UIColor.gray
        phoneLabel.text = memberToView?.phone
        
        infoView.addSubview(phoneLabel)
        
        let secondBar = UIView()
        secondBar.translatesAutoresizingMaskIntoConstraints = false
        secondBar.backgroundColor = UIColor.darkGray
        
        infoView.addSubview(secondBar)
        
        let emailLabel = UILabel()
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        emailLabel.textColor = UIColor.darkGray
        emailLabel.text = memberToView?.email
        infoView.addSubview(emailLabel)

        let emailButton = UIButton()
        emailButton.translatesAutoresizingMaskIntoConstraints = false
        emailButton.backgroundColor = UIColor.green
        //infoView.addSubview(emailButton)
        
        let views = ["callings": callingsText, "firstBar": firstBar, "phone": phoneLabel, "secondBar": secondBar, "emailLabel": emailLabel, "emailButton": emailButton]
        let callingsHConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==15)-[callings]-(==15)-|", options: .alignAllCenterY, metrics: nil, views: views)
        let bar1Hconstraint = NSLayoutConstraint(item: firstBar, attribute: .width, relatedBy: .equal, toItem: infoView, attribute: .width, multiplier: 1, constant: 0)
        let bar2Hconstraint = NSLayoutConstraint(item: secondBar, attribute: .width, relatedBy: .equal, toItem: infoView, attribute: .width, multiplier: 1, constant: 0)
        //let emailHConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==10)-[emailButton(==44)]-[emailLabel]-(==15)-|", options: .alignAllCenterY, metrics: nil, views: views)
        
        let callingsVConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(==0)-[callings(==44)]-[firstBar(==2)]-[phone(==44)]-[secondBar(==2)]-[emailLabel(==44)]-(>=0)-|", options: .alignAllLeft, metrics: nil, views: views)
//        let emailHeightConstraint = NSLayoutConstraint(item: emailButton, attribute: .height, relatedBy: .equal, toItem: emailButton, attribute: .width, multiplier: 1, constant: 0)
//        let emailVConstraint = NSLayoutConstraint(item: emailButton, attribute: .centerY, relatedBy: .equal, toItem: emailLabel, attribute: .centerY, multiplier: 1, constant: 0)
        
        self.addConstraints(callingsHConstraint)
        self.addConstraints([bar1Hconstraint, bar2Hconstraint])
        //self.addConstraints(emailHConstraint)
        self.addConstraints(callingsVConstraint)
        //self.addConstraints([emailVConstraint, emailHeightConstraint])
        
    }
    
    func dismissMemberDetails(_ sender:UITapGestureRecognizer) {
        print("tapped")
        self.removeFromSuperview()
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
