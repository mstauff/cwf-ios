//
//  MemberInfoView.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 3/2/17.
//  Copyright © 2017 colsen. All rights reserved.
//

import UIKit
import MessageUI
import MapKit
import CoreLocation

class MemberInfoView: UIViewController, MFMailComposeViewControllerDelegate, MKMapViewDelegate {
    
    var memberToView: MemberCallings?
    
    var infoView : UIView = UIView()
    var headerView : UIView = UIView()
    var isDown : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        let tapRecognizer = UITapGestureRecognizer(target: self, action:#selector(dismissMemberDetails(_:)))
        self.view.addGestureRecognizer(tapRecognizer)
        
        let swipeUpRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(swipeUpAction(_:)))
        swipeUpRecognizer.direction = .up
        self.view.addGestureRecognizer(swipeUpRecognizer)
        self.setupView()
    }
    
    
    func setupView() {
        if (isDown) {
            setupInfoView()

            setupHeaderView()
            
        
        }
        else {
            setupInfoView()
            setupHeaderView()
        }
    }
    
    func setupHeaderView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor.CWFNavBarTintColor
        
        self.view.addSubview(headerView)

        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = UIColor.white
        nameLabel.text = memberToView?.member.name
        
        headerView.addSubview(nameLabel)
        
        if isDown == false {
            let headerWidthConstraint = NSLayoutConstraint(item: headerView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0)
            let headerHeightConstraint = NSLayoutConstraint(item: headerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44)
            let headerHorizontalConstraint = NSLayoutConstraint(item: headerView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
            let headerVirticalConstraint = NSLayoutConstraint(item: headerView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .topMargin, multiplier: 1, constant: 0)
            
            self.view.addConstraints([headerWidthConstraint, headerHeightConstraint, headerHorizontalConstraint, headerVirticalConstraint])

        }
        else {
            let headerWidthConstraint = NSLayoutConstraint(item: headerView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0)
            let headerHeightConstraint = NSLayoutConstraint(item: headerView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44)
            let headerHorizontalConstraint = NSLayoutConstraint(item: headerView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
            let headerVirticalConstraint = NSLayoutConstraint(item: headerView, attribute: .bottom, relatedBy: .equal, toItem: infoView, attribute: .top, multiplier: 1, constant: 0)
            
            self.view.addConstraints([headerWidthConstraint, headerHeightConstraint, headerHorizontalConstraint, headerVirticalConstraint])
        }
        
        let hConstraint = NSLayoutConstraint(item: nameLabel, attribute: .centerX, relatedBy: .equal, toItem: headerView, attribute: .centerX, multiplier: 1, constant: 0)
        let vConstraint = NSLayoutConstraint(item: nameLabel, attribute: .centerY, relatedBy: .equal, toItem: headerView, attribute: .centerY, multiplier: 1, constant: 0)
        self.view.addConstraints([hConstraint, vConstraint])

    }
    
    func setupInfoView() {
        
        infoView.translatesAutoresizingMaskIntoConstraints = false
        infoView.backgroundColor = UIColor.white
        
        self.view.addSubview(infoView)
        
        let infoHConstraint = NSLayoutConstraint(item: infoView, attribute: .height, relatedBy: .equal, toItem: self.view, attribute: .height, multiplier: 0.45, constant: 0)
        let infoWConstraint = NSLayoutConstraint(item: infoView, attribute: .width, relatedBy: .equal, toItem: self.view, attribute: .width, multiplier: 1, constant: 0)
        let infoVConstraint = NSLayoutConstraint(item: infoView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        let infoHoConstraint = NSLayoutConstraint(item: infoView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
        
        self.view.addConstraints([infoHConstraint, infoWConstraint, infoVConstraint, infoHoConstraint])

        let callingBar = MemberInfoBarItemView()
        let callingText = (memberToView?.callings.namesWithTime() ?? "") + (memberToView?.proposedCallings.namesWithStatus() ?? "")
        callingBar.setupInfoBarItem(dataText: callingText, icon: nil)
        if callingBar.dataLabel.text == "" {
            callingBar.backgroundColor = UIColor.lightGray
        }

        infoView.addSubview(callingBar)
        
        let callingBarConstraintH = NSLayoutConstraint(item: callingBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 54)
        let callingBarConstraintW = NSLayoutConstraint(item: callingBar, attribute: .width, relatedBy: .equal, toItem: infoView, attribute: .width, multiplier: 1, constant: 0)
        let callingBarConstraintV = NSLayoutConstraint(item: callingBar, attribute: .top, relatedBy: .equal, toItem: infoView, attribute: .top, multiplier: 1, constant: 0)
        let callingBarConstraintO = NSLayoutConstraint(item: callingBar, attribute: .left, relatedBy: .equal, toItem: infoView, attribute: .left, multiplier: 1, constant: 0)
        
        infoView.addConstraints([callingBarConstraintH, callingBarConstraintW, callingBarConstraintO, callingBarConstraintV])
        
        let firstBar = UIView()
        firstBar.translatesAutoresizingMaskIntoConstraints = false
        firstBar.backgroundColor = UIColor.darkGray

        infoView.addSubview(firstBar)
        
        let fBarConstraintH = NSLayoutConstraint(item: firstBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 3)
        let fBarConstraintW = NSLayoutConstraint(item: firstBar, attribute: .width, relatedBy: .equal, toItem: infoView, attribute: .width, multiplier: 1, constant: 0)
        let fBarConstraintX = NSLayoutConstraint(item: firstBar, attribute: .left, relatedBy: .equal, toItem: infoView, attribute: .left, multiplier: 1, constant: 0)
        let fBarConstraintY = NSLayoutConstraint(item: firstBar, attribute: .top, relatedBy: .equal, toItem: callingBar, attribute: .bottom, multiplier: 1, constant: 0)
        
        infoView.addConstraints([fBarConstraintH, fBarConstraintW, fBarConstraintX, fBarConstraintY])
        
        // Get the phone numbers to display
        
        var lastView: UIView = firstBar
        var phoneNumberAndTypeArray: [(phone: String, type: String)] = []
       
        if let individualPhone = memberToView?.member.individualPhone {
            phoneNumberAndTypeArray.append((individualPhone, "Individual"))
        }
        if let housePhone = memberToView?.member.householdPhone {
            phoneNumberAndTypeArray.append((housePhone, "Household"))
        }
        for phoneAndType in phoneNumberAndTypeArray {
            let currentPhoneBar = MemberInfoBarItemView()
            currentPhoneBar.setupInfoBarItem(dataText: phoneAndType.phone, icon: UIImage.init(named: "phoneIcon"))
            currentPhoneBar.iconImageView?.addTarget(self, action: #selector(callButtonPressed), for: .touchUpInside)
            
            infoView.addSubview(currentPhoneBar)
            
            let phoneConstraintH = NSLayoutConstraint(item: currentPhoneBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 54.0)
            let phoneConstraintW = NSLayoutConstraint(item: currentPhoneBar, attribute: .width, relatedBy: .equal, toItem: infoView, attribute: .width, multiplier: 1, constant: 0)
            let phoneConstraintX = NSLayoutConstraint(item: currentPhoneBar, attribute: .left, relatedBy: .equal, toItem: infoView, attribute: .left, multiplier: 1, constant: 0)
            let phoneConstraintY = NSLayoutConstraint(item: currentPhoneBar, attribute: .top, relatedBy: .equal, toItem: lastView, attribute: .bottom, multiplier: 1, constant: 0)
            
            infoView.addConstraints([phoneConstraintH, phoneConstraintW, phoneConstraintX, phoneConstraintY])
            
            lastView = currentPhoneBar
        }
        
        
        
        
        let secondBar = UIView()
        secondBar.translatesAutoresizingMaskIntoConstraints = false
        secondBar.backgroundColor = UIColor.darkGray
        
        infoView.addSubview(secondBar)
        
        let sBarConstraintH = NSLayoutConstraint(item: secondBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 3)
        let sBarConstraintW = NSLayoutConstraint(item: secondBar, attribute: .width, relatedBy: .equal, toItem: infoView, attribute: .width, multiplier: 1, constant: 0)
        let sBarConstraintX = NSLayoutConstraint(item: secondBar, attribute: .left, relatedBy: .equal, toItem: infoView, attribute: .left, multiplier: 1, constant: 0)
        let sBarConstraintY = NSLayoutConstraint(item: secondBar, attribute: .top, relatedBy: .equal, toItem: lastView, attribute: .bottom, multiplier: 1, constant: 0)
        
        infoView.addConstraints([sBarConstraintH, sBarConstraintW, sBarConstraintX, sBarConstraintY])
        lastView = secondBar
        
        if let emailString = memberToView?.member.individualEmail {
            let emailBar = MemberInfoBarItemView()
            emailBar.setupInfoBarItem(dataText: emailString, icon: UIImage.init(named: "emailIcon"))
            emailBar.iconImageView?.addTarget(self, action: #selector(emailButtonPressed), for: .touchUpInside)
            
            infoView.addSubview(emailBar)
            
            let emailConstraintH = NSLayoutConstraint(item: emailBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 54.0)
            let emailConstraintW = NSLayoutConstraint(item: emailBar, attribute: .width, relatedBy: .equal, toItem: infoView, attribute: .width, multiplier: 1, constant: 0)
            let emailConstraintX = NSLayoutConstraint(item: emailBar, attribute: .left, relatedBy: .equal, toItem: infoView, attribute: .left, multiplier: 1, constant: 0)
            let emailConstraintY = NSLayoutConstraint(item: emailBar, attribute: .top, relatedBy: .equal, toItem: lastView, attribute: .bottom, multiplier: 1, constant: 0)
            
            infoView.addConstraints([emailConstraintH, emailConstraintW, emailConstraintX, emailConstraintY])
            lastView = emailBar
        }
        else {
            let emailBar = MemberInfoBarItemView()
            emailBar.setupInfoBarItem(dataText: "No Individual Email", icon: UIImage.init(named: "emailIcon"))
            infoView.addSubview(emailBar)
            
            let emailConstraintH = NSLayoutConstraint(item: emailBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 54.0)
            let emailConstraintW = NSLayoutConstraint(item: emailBar, attribute: .width, relatedBy: .equal, toItem: infoView, attribute: .width, multiplier: 1, constant: 0)
            let emailConstraintX = NSLayoutConstraint(item: emailBar, attribute: .left, relatedBy: .equal, toItem: infoView, attribute: .left, multiplier: 1, constant: 0)
            let emailConstraintY = NSLayoutConstraint(item: emailBar, attribute: .top, relatedBy: .equal, toItem: lastView, attribute: .bottom, multiplier: 1, constant: 0)
            
            infoView.addConstraints([emailConstraintH, emailConstraintW, emailConstraintX, emailConstraintY])
            lastView = emailBar
        }
        
        let thirdBar = UIView()
        thirdBar.translatesAutoresizingMaskIntoConstraints = false
        thirdBar.backgroundColor = UIColor.darkGray
        
        infoView.addSubview(thirdBar)
        let tBarConstraintH = NSLayoutConstraint(item: thirdBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 3)
        let tBarConstraintW = NSLayoutConstraint(item: thirdBar, attribute: .width, relatedBy: .equal, toItem: infoView, attribute: .width, multiplier: 1, constant: 0)
        let tBarConstraintX = NSLayoutConstraint(item: thirdBar, attribute: .left, relatedBy: .equal, toItem: infoView, attribute: .left, multiplier: 1, constant: 0)
        let tBarConstraintY = NSLayoutConstraint(item: thirdBar, attribute: .top, relatedBy: .equal, toItem: lastView, attribute: .bottom, multiplier: 1, constant: 0)
        
        infoView.addConstraints([tBarConstraintH, tBarConstraintW, tBarConstraintX, tBarConstraintY])
        lastView = thirdBar
        
        let addressBar = MemberInfoBarItemView()
        if let addressText = memberToView?.member.getAddressAsString() {
            addressBar.setupInfoBarItem(dataText: addressText, icon: UIImage.init(named: "gps"))
            addressBar.iconImageView?.addTarget(self, action: #selector(locationButtonPressed), for: .touchUpInside)
        }
        else {
            addressBar.setupInfoBarItem(dataText: "No Address Available", icon: nil)
        }
        infoView.addSubview(addressBar)
        
        let addressConstraintH = NSLayoutConstraint(item: addressBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 54)
        let addressConstraintW = NSLayoutConstraint(item: addressBar, attribute: .width, relatedBy: .equal, toItem: infoView, attribute: .width, multiplier: 1, constant: 0)
        let addressConstraintX = NSLayoutConstraint(item: addressBar, attribute: .left, relatedBy: .equal, toItem: infoView, attribute: .left, multiplier: 1, constant: 0)
        let addressConstraintY = NSLayoutConstraint(item: addressBar, attribute: .top, relatedBy: .equal, toItem: lastView, attribute: .bottom, multiplier: 1, constant: 0)
        
        infoView.addConstraints([addressConstraintH, addressConstraintW, addressConstraintX, addressConstraintY])

    }
    
    //MARK: - Button Actions
    func callButtonPressed() {
        if var phoneString = memberToView?.member.phone {
            phoneString = "tel://\(phoneString)"
            UIApplication.shared.openURL(URL(string: phoneString)!)
        }
    }
    
    func locationButtonPressed() {
        if let address = memberToView?.member.streetAddress {
            
            let mapVC = CWFMapViewController()
            let navController = UINavigationController(rootViewController: mapVC)
            mapVC.addressToDisplay = address
            
            present(navController, animated: true, completion: nil)
        }
    }
    
    func emailButtonPressed() {
        if let emailAddress = memberToView?.member.email {
            if MFMailComposeViewController.canSendMail() {
                let mailVC = MFMailComposeViewController()
                mailVC.mailComposeDelegate = self
                mailVC.setToRecipients([emailAddress])
                mailVC.setSubject(NSLocalizedString("Subject for email", comment: ""))
                mailVC.setMessageBody(NSLocalizedString("Email message string", comment: ""), isHTML: false)
                
                present(mailVC, animated: true, completion: nil)
            }
            else {
                let alert = UIAlertController(title: NSLocalizedString("Cannnot Send Email", comment: "email error"), message:NSLocalizedString("Check your email settings", comment: "email error message") , preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: NSLocalizedString("OK", comment: ""), style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func textButtonPressed () {
    
    }
    
    func dismissMemberDetails(_ sender:UITapGestureRecognizer) {
        print("tapped")
        self.dismiss(animated: true, completion: nil)
    }
  
    func swipeUpAction (_ gesture: UIGestureRecognizer) {
        if (isDown) {
            isDown = false
            self.setupView()
        }
        
    }
    
    //MARK: - Email Delegate
    private func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    //MARK: - Map View Delegate
    
}


// MARK: - Class to add memberinfoBar to memberinfoview
class MemberInfoBarItemView : UIView {
    
    var iconImageView : UIButton?
    
    var dataLabel : UILabel = UILabel()
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        self.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupInfoBarItem(dataText: String, icon: UIImage?) {
        
        dataLabel.text = dataText
        dataLabel.numberOfLines = 0
        dataLabel.font = UIFont(name: dataLabel.font.fontName, size: 14)
        dataLabel.textColor = UIColor.CWFGreyTextColor
        dataLabel.translatesAutoresizingMaskIntoConstraints = false

        
        if (icon != nil) {

            iconImageView = UIButton()
            iconImageView?.setImage(icon, for: .normal)
            iconImageView?.translatesAutoresizingMaskIntoConstraints = false

            self.addSubview(iconImageView!)
            
            let iconConstraintH = NSLayoutConstraint(item: iconImageView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 44)
            let iconConstraintW = NSLayoutConstraint(item: iconImageView!, attribute: .width, relatedBy: .equal, toItem: iconImageView, attribute: .height, multiplier: 1, constant: 0)
            let iconConstraintY = NSLayoutConstraint(item: iconImageView!, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
            let iconConstraintX = NSLayoutConstraint(item: iconImageView!, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
            self.addConstraints([iconConstraintH, iconConstraintW, iconConstraintX, iconConstraintY])
            
            self.addSubview(dataLabel)
            
            let labelConstraintH = NSLayoutConstraint(item: dataLabel, attribute: .height, relatedBy: .equal, toItem: iconImageView, attribute: .height, multiplier: 1, constant: 0)
            let labelConstraintL = NSLayoutConstraint(item: dataLabel, attribute: .left, relatedBy: .equal, toItem: iconImageView!, attribute: .right, multiplier: 1, constant: 10)
            let labelConstraintR = NSLayoutConstraint(item: dataLabel, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -15)
            let labelConstraintY = NSLayoutConstraint(item: dataLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
            
            self.addConstraints([labelConstraintH, labelConstraintL, labelConstraintR, labelConstraintY])
            
        }
        else {
            self.addSubview(dataLabel)
            
            let labelConstraintH = NSLayoutConstraint(item: dataLabel, attribute: .height, relatedBy: .equal, toItem: self, attribute: .height, multiplier: 0.80, constant: 0)
            let labelConstraintL = NSLayoutConstraint(item: dataLabel, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 15)
            let labelConstraintR = NSLayoutConstraint(item: dataLabel, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -15)
            let labelConstraintY = NSLayoutConstraint(item: dataLabel, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
            
            self.addConstraints([labelConstraintH, labelConstraintL, labelConstraintR, labelConstraintY])
            
        }
    }
    
    
}
