//
//  LDSCredentialsViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/9/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit
import Locksmith

struct LDSCredentialsVCEnums {
    enum SectionTypes : Int {
        case Credentials
        case Sync
        
        static let allValues = [Credentials, Sync]
        
        static var count : Int {
            get {
                return allValues.count
            }
        }
    }
    
    enum CredentialsItemType : Int {
        case Username
        case Password
        case SignInBtn
        case SignOutBtn

        static let allValues = [Username, Password, SignInBtn, SignOutBtn]
        
        static var count : Int {
            get {
                return allValues.count
            }
        }
    }    
}

class LDSCredentialsTableViewController: CWFBaseTableViewController, ProcessingSpinner, AlertBox {
    
    var userNameField : UITextField?
    var passwordField : UITextField?
    var signedIn = false
    var newSignIn = false
    
    var keychainDataDictionary: Dictionary<String, String>?

    var loginDelegate: LDSLoginDelegate? = nil
    var reinitDelegate: InitializeAppDataDelegate? = nil
    
    weak var callingMgr : CWFCallingManagerService? = nil
    
    var addBackButton : Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        

        userNameField = nil
        passwordField = nil
        
        keychainDataDictionary = Locksmith.loadDataForUserAccount(userAccount: "callingWorkFlow") as! Dictionary<String, String>?
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.callingMgr = appDelegate?.callingManager
        signedIn = keychainDataDictionary?["username"] != nil
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillDisappear(_ animated: Bool) {
        if newSignIn {
            reinitDelegate?.reinitApp(useCache: false)
        }
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        return 22.0
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case LDSCredentialsVCEnums.SectionTypes.Credentials.rawValue:
            return NSLocalizedString("LDS Account", comment: "LDS Account")
        case LDSCredentialsVCEnums.SectionTypes.Sync.rawValue:
            return NSLocalizedString("lds.org Data", comment: "Data")
        default:
            return ""
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return LDSCredentialsVCEnums.SectionTypes.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case LDSCredentialsVCEnums.SectionTypes.Credentials.rawValue:
            // if we're not signed in then we don't want to include a row for the sign out button
            return signedIn ? LDSCredentialsVCEnums.CredentialsItemType.count : (LDSCredentialsVCEnums.CredentialsItemType.count - 1)
        case LDSCredentialsVCEnums.SectionTypes.Sync.rawValue:
            return 1
        default:
            return 1
        }
    }
    
    private func initializeUsernameField( withUser username : String?) {

        initializeTextField(self.userNameField, withText: username, orPlaceholderText: NSLocalizedString("lds.org Username", comment: "lds.org Username"))
    }

    private func initializePasswordField( withPassword password : String?) {
        initializeTextField(self.passwordField, withText: password, orPlaceholderText: NSLocalizedString("lds.org Password", comment: "lds.org Password"))
    }

    private func initializeTextField( _ textField : UITextField?, withText textValue: String?, orPlaceholderText placeholderText : String?) {
        // technically this isn't really necessary, as setting textField.text to nil actually just sets it to "", but don't want to rely on that, in case it changes in the future
            let validTextValue = textValue == nil ? "" : textValue
            textField?.text = validTextValue
            let placeholder = placeholderText ?? ""
            textField?.placeholder = NSLocalizedString(placeholder, comment: placeholder)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell? = nil
        switch indexPath.section {
        case LDSCredentialsVCEnums.SectionTypes.Credentials.rawValue:
            switch indexPath.row {
            case LDSCredentialsVCEnums.CredentialsItemType.Username.rawValue:
                let usernameCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as? InputTableViewCell
                cell = usernameCell

                self.userNameField = usernameCell?.inputField
                initializeUsernameField( withUser: keychainDataDictionary?["username"])
            case LDSCredentialsVCEnums.CredentialsItemType.Password.rawValue:
                let passwordCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as? InputTableViewCell
                passwordCell?.inputField?.isSecureTextEntry = true
                cell = passwordCell

                self.passwordField = passwordCell?.inputField
                initializePasswordField(withPassword: keychainDataDictionary?["password"])
            case LDSCredentialsVCEnums.CredentialsItemType.SignInBtn.rawValue:
                cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath)
            case LDSCredentialsVCEnums.CredentialsItemType.SignOutBtn.rawValue:
                cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath)
                let btnText = NSLocalizedString("Sign Out", comment: "Sign Out")
                // the "button" is actually just a text label in the row. The sign-in button is defined in the storyboard. We don't currently have a component for it (although we probably should at some point, for these two buttons as well as the lds.org actions button on the calling details). So we just have to grab the label off the button and set the text (from "sign in" to "sign out...")
                if let btn = cell?.contentView.subviews.first(where: {$0 is UILabel}) as? UILabel {
                    btn.text = btnText
                }
            default:
                let inputCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as? InputTableViewCell
                inputCell?.textLabel?.text = nil
                cell = inputCell
            }
        case LDSCredentialsVCEnums.SectionTypes.Sync.rawValue:
            cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath)
            let btnText = NSLocalizedString("Refresh Data from lds.org", comment: "Sync")
            // the "button" is actually just a text label in the row. The sign-in button is defined in the storyboard. We don't currently have a component for it (although we probably should at some point, for these two buttons as well as the lds.org actions button on the calling details). So we just have to grab the label off the button and set the text (from "sign in" to "Refresh Data...")
            if let btn = cell?.contentView.subviews.first(where: {$0 is UILabel}) as? UILabel {
                btn.text = btnText

            }
        default:
            let inputCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as? InputTableViewCell
            inputCell?.inputField = nil
            cell = inputCell
        }
        return cell == nil ? UITableViewCell() : cell!
    }
    
    // MARK: Event Handlers
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case LDSCredentialsVCEnums.SectionTypes.Credentials.rawValue:
            switch indexPath.row {
                // no handler for username or password - the UITextField seems to consume the event, and even if it doesn't we were just doing the default action anyway
            case LDSCredentialsVCEnums.CredentialsItemType.SignInBtn.rawValue:
                userNameField?.resignFirstResponder()
                passwordField?.resignFirstResponder()

                prepareAndLogin()
                tableView.deselectRow(at: indexPath, animated: true)
                
            case LDSCredentialsVCEnums.CredentialsItemType.SignOutBtn.rawValue:
                userNameField?.resignFirstResponder()
                passwordField?.resignFirstResponder()

                logOutLDSUser()
                tableView.deselectRow(at: indexPath, animated: true)

            default:
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
        case LDSCredentialsVCEnums.SectionTypes.Sync.rawValue:
            userNameField?.resignFirstResponder()
            passwordField?.resignFirstResponder()
            tableView.deselectRow(at: indexPath, animated: true)
            
            let syncMessage = NSLocalizedString("This will update your app with any changes that have been made on lds.org since the time you launched the app. You should not need to do this on a regular basis, only if you know there has been a change made on lds.org that you are not seeing in the app yet. Do you want to proceed.", comment: "Resync")
            showAlert(title: NSLocalizedString("Sync Data", comment: "Sync"), message: syncMessage, includeCancel: true, okCompletionHandler: syncOkHandler)
            
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func prepareAndLogin() {
        let username = (self.userNameField?.text)!
        let password = (self.passwordField?.text)!
        //Show alert on empty strings
        if username == "" || password == "" {
            showAlert(title: "Login Error", message: "Enter username and password to login", includeCancel: false, okCompletionHandler: nil)
        } else  {
            self.startStaticFrameProcessingSpinner()
            do {
                try Locksmith.deleteDataForUserAccount(userAccount: "callingWorkFlow")
            } catch {
                print("error deleting login data")
            }
            // need to logout first. Otherwise getCurrentUser() may return the old user, even if the login failed.
            if signedIn {
                self.callingMgr?.logoutLdsUser() {
                    // Attempt to login
                    self.handleLogin(username: username, password: password)
                }
            } else {
                // no need to logout first, just login
                // Attempt to login
                self.handleLogin(username: username, password: password)
            }
        }
    }
    
    func handleLogin( username: String, password: String ) {
        self.ldsIdIsValid(username: username, password: password) { loggedIn, error in
            DispatchQueue.main.async {
                
                self.removeProcessingSpinner()
                guard error == nil, loggedIn else {
                    // todo - check error for network, vs. 403, etc.
                    self.showAlert(title: "Login Error", message: "Invalid username or password", includeCancel: false, okCompletionHandler: nil)
                    return
                }
                
                do {
                    try Locksmith.saveData(data: ["username": username, "password": password], forUserAccount: "callingWorkFlow")
                } catch {
                    print("error saving username")
                }
                if let loginDict = Locksmith.loadDataForUserAccount(userAccount: "callingWorkFlow") {
                    self.loginDelegate?.setLoginDictionary(returnedLoginDictionary: loginDict)
                }
                // mark that there has been a change in the signed in user so we can reload data when this VC returns
                self.newSignIn = true
                self.dismiss(animated: true, completion: nil)
                self.navigationController?.popViewController(animated: true)
            }
        }

    }

    func ldsIdIsValid(username: String, password: String, completionHandler: @escaping (Bool, Error?) -> Void) {
        if let callingManager = self.callingMgr {
            callingManager.getLdsUser(username: username, password: password, useCachedVersion: false) { user, error in
                guard error == nil, user != nil else {
                    completionHandler( false, error )
                    return
                }
                completionHandler( true, nil )
            }
        }
    }
    
    func logOutLDSUser() {
        showAlert(title: "Logout", message: "This will remove your lds.org credentials, and all lds.org data from your phone. It will not affect the data for any other users in your unit. Do you want to proceed?", includeCancel: true) { _ in
            
            self.startStaticFrameProcessingSpinner()
            do {
                try Locksmith.deleteDataForUserAccount(userAccount: "callingWorkFlow")
                self.signedIn = false
                self.initializeUsernameField(withUser: nil)
                self.initializePasswordField(withPassword: nil)
                self.keychainDataDictionary = Locksmith.loadDataForUserAccount(userAccount: "callingWorkFlow") as! Dictionary<String, String>?
                
                self.tableView.reloadData()
            }
            catch {
                print("error deleting login data")
            }
            self.callingMgr?.logoutLdsUser() {
                DispatchQueue.main.async {
                    self.removeProcessingSpinner()
                }
            }
        }
    }
    
    // handler for when user clicks ok on the sync warning, actually starts the sync process
    func syncOkHandler( alert: UIAlertAction ) {
        //Call to callingManager to resync
        if let callingService = self.callingMgr {
            self.startStaticFrameProcessingSpinner()
            callingService.reloadLdsData(forUser: nil, completionHandler: syncCompletionHandler)
        } else {
            // shouldn't happen - log/display error
        }
    }
    
    // completion handler for the sync completing
    func syncCompletionHandler( success: Bool, error: Error? ) {
        DispatchQueue.main.async { 
            self.removeProcessingSpinner()
            
            var completeMessage = "Data updated from lds.org"
            if !success {
                completeMessage = "Error communicating with lds.org. Please retry later."
            }
            
            self.showAlert(title: NSLocalizedString("Sync Complete", comment: "Sync"), message: completeMessage, includeCancel: false, okCompletionHandler: nil)
        }
    }
}
