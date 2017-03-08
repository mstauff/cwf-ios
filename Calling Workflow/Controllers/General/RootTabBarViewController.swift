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
        // todo: put up a spinner

        let ldscdApi = LdscdRestApi()
        ldscdApi.getAppConfig() { (appConfig, error) in
            //check for valid logins on the keychain

            // Populate these locally - Don't commit to github
            let username = self.loginDictionary?["username"] as! String
            let password = self.loginDictionary?["password"] as! String
            let unitNum: Int64 = 0
            // todo - make this weak
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.callingManager.loadLdsData(forUnit: unitNum, username: username, password: password) { [weak self] (dataLoaded, loadingError) -> Void in
                self?.removeSpinner()
                let childView = self?.selectedViewController as? OrganizationTableViewController
                childView?.getOrgs()
                childView?.tableView.reloadData()
                if dataLoaded {
                    appDelegate?.callingManager.authorizeDataSource(currentVC: self!) { _, _, error in
                        if let error = error {
                            self?.showAlert(title: "Authentication Error", message: error.localizedDescription)
                        } else {
                                appDelegate?.callingManager.loadAppData() { success, hasOrgsToDelete, error in

                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                let loginVC = storyboard.instantiateViewController(withIdentifier: "LDSLogin")

                                let navController2 = UINavigationController()
                                navController2.addChildViewController(loginVC)

                                self?.present(navController2, animated: false, completion: nil)

                            }

                        }

                    }
                }
                else {
                    self?.showAlert(title: "Authentication Error", message: (loadingError?.localizedDescription)!)
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
