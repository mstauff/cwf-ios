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

        // todo - we need a retry button (see VTS 229), but also need a flag to control whether we show the retry, or just blank screen
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
            
            // we only get to this point if we've already been through getLogin() which handles forwarding us to lds.org settings if there are no creds.
            let username = self.loginDictionary?["username"] as! String
            let password = self.loginDictionary?["password"] as! String
            var unitNum: Int64?

            appDelegate?.callingManager.appConfig = appConfig ?? AppConfig()
            // todo - need to also hit google drive to get the user so we can use the unit number if needed to disambiguate lds units
            appDelegate?.callingManager.getLdsUser(username: username, password: password) { [weak self] (ldsUser, error) in
                guard error == nil, let validUser = ldsUser else {
                    self?.removeSpinner()

                    print( "Error logging in to lds.org: " + error.debugDescription )
                    var errorMsg = "Error logging in to lds.org. Please try again later"
                    if let err = error as NSError?, err.code == ErrorConstants.notAuthorized {
                        // it's a bad lds.org credentials issue
                        errorMsg = "Invalid lds.org user. Please check your username and password"
                        // showAlert
                        self?.showAlert(title: "Error", message: errorMsg, includeCancel: false) { _ in
                            // need to forward to lds.org credentials in settings - presentLdsLogin()
                        }
                    } else {
                        self?.showAlert(title: "Error", message: errorMsg, includeCancel: false, okCompletionHandler: nil)
                    }
                    return
                }
                
                let potentialUnitNums : [Int64] = appDelegate?.callingManager.getUnits(forUser: validUser) ?? []
                if potentialUnitNums.isEmpty {
                    let errorMsg = "Error: You do not currently have any callings that are authorized to use this application"
                    print( errorMsg )
                    self?.removeSpinner()
                    self?.showAlert(title: "Error", message: errorMsg, includeCancel: false, okCompletionHandler: nil)
                    // todo - in this case we flip the flag for showing the retry button. In this case there's no need for a retry
                } else if potentialUnitNums.count == 1 {
                    unitNum = potentialUnitNums[0]
                } else {
                    // todo - if unitNum is still nil at this point we need to disambiguate somehow
                    // We might be able to make use of the google account name to know what unit number to use, but we would need to refactor the loading of data from google drive to separate the signin from loading data (we need the signin to get the email account)
                    // there are unit names in the current-user.json, we're just not doing anything with them right now.
                }
                
                // todo - need to figure out a way to reconcile lds.org unit is same as google drive credentials
                if let validUnitNum = unitNum {
                    appDelegate?.callingManager.loadLdsData(forUnit: validUnitNum, ldsUser: validUser) { [weak self] (dataLoaded, loadingError) -> Void in
                        // todo - if we change this callback to provide the unitdata then ldsOrgUnit could be made private. Will that work????
                        let childView = self?.selectedViewController as? OrganizationTableViewController
                        if dataLoaded, let callingMgr = appDelegate?.callingManager, let ldsOrg = callingMgr.ldsOrgUnit {
                            // todo - rename hasDataSourceCredentials - indicate that it's also signing in
                            callingMgr.hasDataSourceCredentials(forUnit: validUnitNum ) { (hasCredentials, signInError) -> Void in
                                if hasCredentials  {
                                    callingMgr.loadAppData(ldsUnit: ldsOrg ) { success, hasOrgsToDelete, error in
                                        self?.removeSpinner()
                                        if success {
                                            childView?.organizationsToDisplay = appDelegate?.callingManager.appDataOrg?.children
                                        }
                                        // todo - still need to deal with hasOrgsToDelete
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
            // todo - combine this with presentLdsOrgLogin() - probably use this code as guts - presentLdsOrgLogin() isn't currently being called so it is likely insufficient
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
