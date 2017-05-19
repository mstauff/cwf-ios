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
    var spinnerView : UIView?
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

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
            // todo - this should come from the lds current user call - we need to break loadLdsData into a signin & currentUser as one, then memberList & org callings as another
            let unitNum: Int64 = 12345
            // todo - make this weak
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            // todo - need to break out loadLdsData into an authWithLds(), getCurrentUser(), initPermissions (once implemented) & then load data. If the auth. fails then use presentLDS..() below to login
            appDelegate?.callingManager.loadLdsData(forUnit: unitNum, username: username, password: password) { [weak self] (dataLoaded, loadingError) -> Void in
                let childView = self?.selectedViewController as? OrganizationTableViewController
                childView?.getOrgs()
                childView?.tableView.reloadData()
                if dataLoaded {
                    appDelegate?.callingManager.hasDataSourceCredentials(forUnit: 0 ) { (hasCredentials, signInError) -> Void in
                        if hasCredentials  {
                            appDelegate?.callingManager.loadAppData() { success, hasOrgsToDelete, error in
                                self?.removeSpinner()
                                // todo - OrgTableVC.reloadData()
                                // eventually we'll need to pull the last viewed tab from some state storage and then show that tab (and maybe reload data)
                            }
                        }else {
                            self?.removeSpinner()
                            print( "No creds - forward to settings!")
                            self?.presentSettingsView()
                        }
                    }
                } else {
                    self?.removeSpinner()
                    print( "Error loading data from LDS.org")
                    self?.showAlert(title: "LDS.org Communication Error", message: (loadingError?.localizedDescription)!)
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
        let spinnerView = UIView()
        spinnerView.translatesAutoresizingMaskIntoConstraints = false
        spinnerView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        
        let textLabel = UILabel()
        textLabel.text = "Loging In"
        textLabel.textColor = UIColor.white
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        spinnerView.addSubview(textLabel)
        spinnerView.addSubview(spinner)
        
        self.view.addSubview(spinnerView)
        self.spinnerView = spinnerView
        
        let hConstraint = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==0)-[spinnerView]-(==0)-|", options: NSLayoutFormatOptions.alignAllCenterY, metrics: nil, views: ["spinnerView": spinnerView])
        let vConstraint = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[spinnerView]-|", options: NSLayoutFormatOptions.alignAllCenterX, metrics: nil, views: ["spinnerView": spinnerView])
        
        self.view.addConstraints(hConstraint)
        self.view.addConstraints(vConstraint)
        
        let spinnerHConstraint = NSLayoutConstraint(item: spinner, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: spinnerView, attribute: .centerX, multiplier: 1, constant: 0)
        let textHConstraint = NSLayoutConstraint(item: textLabel, attribute: NSLayoutAttribute.centerX, relatedBy: .equal, toItem: spinnerView, attribute: .centerX, multiplier: 1, constant: 0)
        let spinnerVConstraint = NSLayoutConstraint(item: spinner, attribute: NSLayoutAttribute.centerY, relatedBy: .equal, toItem: spinnerView, attribute: .centerY, multiplier: 1, constant: 0)
        let textVConstraint = NSLayoutConstraint(item: textLabel, attribute: .bottom, relatedBy: .equal, toItem: spinner, attribute: .top, multiplier: 1, constant: -15)
        
        self.view.addConstraints([spinnerHConstraint, textHConstraint, spinnerVConstraint, textVConstraint])
    }
    
    func removeSpinner () {
        self.spinnerView?.removeFromSuperview()
    }
    
}
