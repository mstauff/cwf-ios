//
//  RootTabBarViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 12/1/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit
import Locksmith

class RootTabBarViewController: UITabBarController, LDSLoginDelegate, InitializeAppDataDelegate, ProcessingSpinner, AlertBox {
    
    var loginDictionary : Dictionary<String, Any>?
    weak var appDelegate : AppDelegate?
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.tabBar.isTranslucent = false
        let ldscdApi = LdscdRestApi()
        // to avoid going to the app config server, use this line. It will just use what's defined in NetworkConstants
        //        ldscdApi.appConfig = AppConfig()
        ldscdApi.getAppConfig() { (appConfig, error) in
            DispatchQueue.main.async {
                
                if error != nil {
                    // just print it out, we'll use a default app config below
                    print("Error retrieving app config from ldscd (redhat) server:" + error.debugDescription)
                }
                self.appDelegate?.callingManager.appConfig = appConfig ?? AppConfig()
                // check the keychain for stored LDS.org credentials
                self.getLogin()
                
            }
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // If we're re initing based on login changes (in settings) then usecache should be false to force refresh
    // if we're retrying from the button (due to network error, should be true)
    func reinitApp( useCache: Bool ) {
        loadLdsAndAppData(useCache: useCache)
        self.selectedIndex = 0
    }
    
    
    // MARK: - Login to ldsapi
    func loadLdsAndAppData( useCache: Bool) {
        
        startProcessingSpinner( labelText: "Logging In" )
        
        // some tests fail (it's during test/init code, not during the test itself) if this is inside the getAppConfig callback. So get the reference before the call.
        // we only get to this point if we've already been through getLogin() which handles forwarding us to lds.org settings if there are no creds.
        let username = self.loginDictionary?["username"] as! String
        let password = self.loginDictionary?["password"] as! String
        var unitNum: Int64?
        
        // todo - need to also hit google drive to get the user so we can use the unit number if needed to disambiguate lds units
        appDelegate?.callingManager.getLdsUser(username: username, password: password, useCachedVersion: useCache) { [weak self] (ldsUser, error) in
            guard error == nil, let validUser = ldsUser else {
                print( "Error logging in to lds.org: " + error.debugDescription )
                DispatchQueue.main.async {
                    self?.removeProcessingSpinner()
                    
                    var errorMsg = "Error logging in to lds.org. Please try again later"
                    if let err = error as NSError?, err.code == ErrorConstants.notAuthorized {
                        // it's a bad lds.org credentials issue
                        errorMsg = "Invalid lds.org user. Please check your username and password"
                        // showAlert
                        self?.showAlert(title: "Error", message: errorMsg, includeCancel: false) { _ in
                            self?.presentLdsOrgLogin()
                        }
                    } else {
                        self?.showAlert(title: "Error", message: errorMsg, includeCancel: false, okCompletionHandler: nil)
                    }
                }
                return
            }
            
            let potentialUnitNums : [Int64] = self?.appDelegate?.callingManager.getUnits(forUser: validUser) ?? []
            if potentialUnitNums.isEmpty {
                let errorMsg = "Error: You do not currently have any callings that are authorized to use this application"
                print( errorMsg )
                DispatchQueue.main.async {
                    self?.removeProcessingSpinner()
                    self?.showAlert(title: "Error", message: errorMsg, includeCancel: false, okCompletionHandler: nil)
                }
            } else if potentialUnitNums.count == 1 {
                unitNum = potentialUnitNums[0]
            } else {
                // todo - if unitNum is still nil at this point we need to disambiguate somehow
                // We might be able to make use of the google account name to know what unit number to use, but we would need to refactor the loading of data from google drive to separate the signin from loading data (we need the signin to get the email account)
                // there are unit names in the current-user.json, we're just not doing anything with them right now.
            }
            
            if let validUnitNum = unitNum {
                self?.appDelegate?.callingManager.loadLdsData(forUnit: validUnitNum, ldsUser: validUser, useCachedVersion: useCache) { [weak self] (dataLoaded, loadingError) -> Void in
                    // todo - if we change this callback to provide the unitdata then ldsOrgUnit could be made private. Will that work????
                    let childView = self?.selectedViewController as? OrganizationTableViewController
                    if dataLoaded, let callingMgr = self?.appDelegate?.callingManager, let ldsOrg = callingMgr.ldsOrgUnit {
                        // todo - rename hasDataSourceCredentials - indicate that it's also signing in
                        callingMgr.hasDataSourceCredentials(forUnit: validUnitNum ) { (hasCredentials, signInError) -> Void in
                            if hasCredentials  {
                                callingMgr.loadAppData(ldsUnit: ldsOrg ) { success, hasOrgsToDelete, error in
                                    self?.removeSpinner()
                                    if success {
                                        childView?.organizationsToDisplay = self?.appDelegate?.callingManager.appDataOrg?.children
                                    }
                                    // todo - still need to deal with hasOrgsToDelete
                                }
                            }else {
                                DispatchQueue.main.async {
                                    self?.removeProcessingSpinner()
                                    self?.showDriveSignInAlert(title: NSLocalizedString("Invalid Google Account", comment: "invalid google account"), message:NSLocalizedString("You need to go to the Settings page, Sharing/Sync Options & then sign in with the ward google account to proceed", comment: "Notify user that they are going to the settings") )
                                    print( "No creds - forward to settings!")
                                    self?.presentDriveSignInView()
                                }
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self?.removeProcessingSpinner()
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
        loginVC?.addBackButton = true
        loginVC?.reinitDelegate = self
        
        let navController2 = UINavigationController()
        navController2.addChildViewController(loginVC!)
        
        self.selectedIndex = 3
        self.present(navController2, animated: false, completion: nil)
    }
    
    func presentLdsOrgLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LDSLogin") as? LDSCredentialsTableViewController
        loginVC?.loginDelegate = self
        loginVC?.reinitDelegate = self
        
        let navController2 = UINavigationController()
        navController2.addChildViewController(loginVC!)
        
        self.present(navController2, animated: false, completion: nil)
    }
    
    
    func getLogin() {
        //get login from keychain
        if let ldsLoginData = Locksmith.loadDataForUserAccount(userAccount: "callingWorkFlow") {
            setLoginDictionary(returnedLoginDictionary: ldsLoginData)
            loadLdsAndAppData( useCache: false )
            
        } else {
            presentLdsOrgLogin()
        }
    }
    
    
    // MARK: - Login Delegate
    func setLoginDictionary(returnedLoginDictionary: Dictionary<String, Any>) {
        loginDictionary = returnedLoginDictionary
    }
    
    // MARK: - Spinner Setup
    func removeSpinner () {
        DispatchQueue.main.async {
            self.removeProcessingSpinner()
        }
    }
}
