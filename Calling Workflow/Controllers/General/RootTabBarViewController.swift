//
//  RootTabBarViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 12/1/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit
import Locksmith

class RootTabBarViewController: UITabBarController, LDSLoginDelegate, ProcessingSpinner, AlertBox {
    
    var loginDictionary : Dictionary<String, Any>?
    
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
        
        startProcessingSpinner( labelText: "Logging In" )
        
        // some tests fail (it's during test/init code, not during the test itself) if this is inside the getAppConfig callback. So get the reference before the call.
        weak var appDelegate = UIApplication.shared.delegate as? AppDelegate
        let ldscdApi = LdscdRestApi()
        // to avoid going to the app config server, use this line. It will just use what's defined in NetworkConstants
//        ldscdApi.appConfig = AppConfig()
        ldscdApi.getAppConfig() { (appConfig, error) in

            if error != nil {
                // just print it out, we'll use a default app config below
                print( "Error retrieving app config from ldscd (redhat) server:" + error.debugDescription )
            }
            
            let username = self.loginDictionary?["username"] as! String
            let password = self.loginDictionary?["password"] as! String
            var unitNum: Int64?
            appDelegate?.callingManager.appConfig = appConfig ?? AppConfig()
            appDelegate?.callingManager.getLdsUser(username: username, password: password) { [weak self] (ldsUser, error) in
                guard error == nil, let validUser = ldsUser else {
                    print( "Error logging in to lds.org: " + error.debugDescription )
                    var errorMsg = "Error logging in to lds.org. Please try again later"
                    if let err = error as? NSError, err.code == ErrorConstants.notAuthorized {
                        // it's a bad lds.org credentials issue
                        errorMsg = "Invalid lds.org user. Please check your username and password"
                    }
                    self?.removeSpinner()
                    self?.showAlert(title: "Error", message: errorMsg, includeCancel: false, okCompletionHandler: nil)
                    return
                }
                
                let potentialUnitNums = appDelegate?.callingManager.getUnits(forUser: validUser) ?? []
                if potentialUnitNums.isEmpty {
                    let errorMsg = "Error: You do not currently have any callings that are authorized to use this application"
                    print( errorMsg )
                    self?.removeSpinner()
                    self?.showAlert(title: "Error", message: errorMsg, includeCancel: false, okCompletionHandler: nil)
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
                                    self?.showDriveSignInAlert(title: NSLocalizedString("Invalid Google Account", comment: "invalid google account"), message:NSLocalizedString("You need to go to the Settings page, Sharing/Sync Options & then sign in with the ward google account to proceed", comment: "Notify user that they are going to the settings") )
                                    print( "No creds - forward to settings!")
                                    self?.presentDriveSignInView()
                                }
                            }
                        } else {
                            self?.removeSpinner()
                            print( "Error loading data from LDS.org")
                            let alertText = loadingError?.localizedDescription ?? "Unknown Error"
                            self?.showAlert(title: "LDS.org Communication Error", message: alertText, includeCancel: false, okCompletionHandler: nil)
                        }
                    }
                }
            }
        }
    }
    
    func showDriveSignInAlert(title: String, message: String) {
        self.showAlert(title: title, message: message, includeCancel: false) {
            (alert: UIAlertAction!) -> Void in
            self.presentDriveSignInView()
        }
    }
    
    func presentDriveSignInView() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "FirstViewController") as? GoogleSettingsViewController
        let navController2 = UINavigationController()
        navController2.addChildViewController(loginVC!)
        
        self.present(navController2, animated: false, completion: nil)
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
        } else {
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
     func removeSpinner () {
        DispatchQueue.main.async {
            self.removeProcessingSpinner()
        }
    }
    
}
