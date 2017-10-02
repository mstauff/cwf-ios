//
//  RootTabBarViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 12/1/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit
import Locksmith

class RootTabBarViewController: UITabBarController, LDSLoginDelegate {
    
    var loginDictionary : Dictionary<String, Any>?
    var spinnerView : CWFSpinnerView?
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBar.isTranslucent = false
        
        // check the keychain for stored LDS.org credentials
        self.getLogin()
        
        //signIntoLDSAPI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Login to ldsapi
    func signIntoLDSAPI() {
        startSpinner()
        
        let ldscdApi = LdscdRestApi()
        ldscdApi.getAppConfig() { (appConfig, error) in
            
            let username = self.loginDictionary?["username"] as! String
            let password = self.loginDictionary?["password"] as! String
            var unitNum: Int64?
            // todo - make this weak
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.callingManager.appConfig = appConfig ?? AppConfig()
            appDelegate?.callingManager.getLdsUser(username: username, password: password) { [weak self] (ldsUser, error) in
                guard error == nil, let validUser = ldsUser else {
                    // todo - check error for bad username/password vs. network failure (on our end or lds.org end)
                    print( "Error logging in to lds.org: " + error.debugDescription )
                    self?.removeSpinner()
                    self?.presentSettingsView()
                    return
                }
                
                let potentialUnitNums = appDelegate?.callingManager.getUnits(forUser: validUser) ?? []
                if potentialUnitNums.isEmpty {
                    let errorMsg = "Error: No Permissions for app"
                    print( errorMsg )
                    self?.removeSpinner()
                    // todo - pop a warning about user requirements
                } else if potentialUnitNums.count == 1 {
                    unitNum = potentialUnitNums[0]
                } else {
                    // todo - need to disambiguate
                    // there are unit names in the current-user.json, we're just not doing anything with them right now.
                }
                
                // todo - need to figure out a way to reconcile lds.org unit is same as google drive credentials
                if let validUnitNum = unitNum {
                    appDelegate?.callingManager.loadLdsData(forUnit: validUnitNum, ldsUser: validUser) { [weak self] (dataLoaded, loadingError) -> Void in
                        // todo - if we change this callback to provide the unitdata then ldsOrgUnit could be made private. Will that work????
                        let childView = self?.selectedViewController as? OrganizationTableViewController
                        if dataLoaded, let callingMgr = appDelegate?.callingManager, let ldsOrg = callingMgr.ldsOrgUnit {
                            callingMgr.hasDataSourceCredentials(forUnit: 0 ) { (hasCredentials, signInError) -> Void in
                                if hasCredentials  {
                                    callingMgr.loadAppData(ldsUnit: ldsOrg ) { success, hasOrgsToDelete, error in
                                        self?.removeSpinner()
                                        if success {
                                            childView?.organizationsToDisplay = appDelegate?.callingManager.appDataOrg?.children
                                        }
                                        // eventually we'll need to pull the last viewed tab from some state storage and then show that tab (and maybe reload data)
                                    }
                                }else {
                                    self?.removeSpinner()
                                    self?.showAlert(title: "Invalid Google Account", message: "You need to go to the Settings page, Sharing/Sync Options & then sign in with the ward google account to proceed")
                                    print( "No creds - forward to settings!")
                                    self?.presentSettingsView()
                                }
                            }
                        } else {
                            self?.removeSpinner()
                            print( "Error loading data from LDS.org")
                            let alertText = loadingError?.localizedDescription ?? "Unknown Error"
                            self?.showAlert(title: "LDS.org Communication Error", message: alertText)
                        }
                    
                    }
                }
            }
        }
    }
    
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: "OK",
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    func presentSettingsView() {
        // todo - like below, if we don't have google creds we need to forward to the settings screen.
    }
    
    func presentLdsOrgLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LDSLogin")
        
        let navController2 = UINavigationController()
        navController2.addChildViewController(loginVC)
        
        self.present(navController2, animated: false, completion: nil)
        

    }
    
    func getLogin() {
        
        //get login from keychain
        if let ldsLoginData = Locksmith.loadDataForUserAccount(userAccount: "callingWorkFlow") {
            setLoginDictionary(returnedLoginDictionary: ldsLoginData)
        }
        else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LDSLogin") as? LDSCredentialsTableViewController
            loginVC?.delegate = self
            let navController2 = UINavigationController()
            navController2.addChildViewController(loginVC!)
            
            self.present(navController2, animated: false, completion: nil)
            
        }
        
    }
    
    
    // MARK: - Login Delegate
    func setLoginDictionary(returnedLoginDictionary: Dictionary<String, Any>) {
        loginDictionary = returnedLoginDictionary
        signIntoLDSAPI()
    }
    
    // MARK: - Spinner Setup
    
    func startSpinner() {
        let spinnerView = CWFSpinnerView(frame: CGRect.zero, title: NSLocalizedString("Loging In", comment: "") as NSString)
//        spinnerView.translatesAutoresizingMaskIntoConstraints = false
//        spinnerView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        
//        let textLabel = UILabel()
//        textLabel.text = "Loging In"
//        textLabel.textColor = UIColor.white
//        textLabel.translatesAutoresizingMaskIntoConstraints = false
//        
//        let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
//        spinner.startAnimating()
//        spinner.translatesAutoresizingMaskIntoConstraints = false
//        
//        spinnerView.addSubview(textLabel)
//        spinnerView.addSubview(spinner)
        
        self.view.addSubview(spinnerView)
        self.spinnerView = spinnerView
        
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==0)-[spinnerView]-(==0)-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: ["spinnerView": spinnerView])
        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[spinnerView]-|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: ["spinnerView": spinnerView])
        
        self.view.addConstraints(hConstraint)
        self.view.addConstraints(vConstraint)
        
//        let spinnerHConstraint = NSLayoutConstraint(item: spinner, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: spinnerView, attribute: .centerX, multiplier: 1, constant: 0)
//        let textHConstraint = NSLayoutConstraint(item: textLabel, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: spinnerView, attribute: .centerX, multiplier: 1, constant: 0)
//        let spinnerVConstraint = NSLayoutConstraint(item: spinner, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: spinnerView, attribute: .centerY, multiplier: 1, constant: 0)
//        let textVConstraint = NSLayoutConstraint(item: textLabel, attribute: .bottom, relatedBy: .equal, toItem: spinner, attribute: .top, multiplier: 1, constant: -15)
//        
//        self.view.addConstraints([spinnerHConstraint, textHConstraint, spinnerVConstraint, textVConstraint])
    }
    
    func removeSpinner () {
        self.spinnerView?.removeFromSuperview()
    }
    
}
