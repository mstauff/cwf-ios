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
        
        static let allValues = [Username, Password, SignInBtn]
        
        static var count : Int {
            get {
                return allValues.count
            }
        }
    }
    
}

class LDSCredentialsTableViewController: CWFBaseTableViewController, ProcessingSpinner {
    
    var userNameField : UITextField?
    var passwordField : UITextField?
    
    var keychainDataDictionary: Dictionary<String, String>?
    
    var delegate : LDSLoginDelegate? = nil
    
    weak var callingMgr : CWFCallingManagerService? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameField = nil
        passwordField = nil
        
        keychainDataDictionary = Locksmith.loadDataForUserAccount(userAccount: "callingWorkFlow") as! Dictionary<String, String>?
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        self.callingMgr = appDelegate?.callingManager
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            return LDSCredentialsVCEnums.CredentialsItemType.count
        case LDSCredentialsVCEnums.SectionTypes.Sync.rawValue:
            return 1
        default:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell? = nil
        switch indexPath.section {
        case LDSCredentialsVCEnums.SectionTypes.Credentials.rawValue:
            switch indexPath.row {
            case LDSCredentialsVCEnums.CredentialsItemType.Username.rawValue:
                let usernameCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as? InputTableViewCell
                if (keychainDataDictionary?["username"] != nil) {
                    usernameCell?.inputField?.text = keychainDataDictionary?["username"]
                } else {
                    usernameCell?.inputField?.placeholder = NSLocalizedString("LDS Username", comment: "LDS.org Username")
                }
                self.userNameField = usernameCell?.inputField
                cell = usernameCell
            case LDSCredentialsVCEnums.CredentialsItemType.Password.rawValue:
                let passwordCell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as? InputTableViewCell
                if (keychainDataDictionary?["password"] != nil) {
                    passwordCell?.inputField.text = keychainDataDictionary?["password"]
                }
                else {
                    passwordCell?.inputField?.placeholder = NSLocalizedString("Password", comment: "Password")
                }
                passwordCell?.inputField?.isSecureTextEntry = true
                passwordField = passwordCell?.inputField
            case LDSCredentialsVCEnums.CredentialsItemType.SignInBtn.rawValue:
                cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath)
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
                
            case LDSCredentialsVCEnums.CredentialsItemType.Username.rawValue, LDSCredentialsVCEnums.CredentialsItemType.Password.rawValue:
                tableView.deselectRow(at: indexPath, animated: true)
                
            case LDSCredentialsVCEnums.CredentialsItemType.SignInBtn.rawValue:
                userNameField?.resignFirstResponder()
                passwordField?.resignFirstResponder()
                
                logInLDSUser(username: (self.userNameField?.text)!, password: (passwordField?.text)!)
                tableView.deselectRow(at: indexPath, animated: true)
                
            default:
                tableView.deselectRow(at: indexPath, animated: true)
            }
            
        case LDSCredentialsVCEnums.SectionTypes.Sync.rawValue:
            userNameField?.resignFirstResponder()
            passwordField?.resignFirstResponder()
            tableView.deselectRow(at: indexPath, animated: true)
            
            let syncMessage = NSLocalizedString("This will update your app with any changes that have been made on lds.org since the time you launched the app. You should not need to do this on a regular basis. Do you want to proceed.", comment: "Resync")
            let syncAlert = UIAlertController(title: NSLocalizedString("Sync Data", comment: "Sync"), message: syncMessage, preferredStyle: UIAlertControllerStyle.alert)
            
            let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.destructive, handler: syncOkHandler)
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: UIAlertActionStyle.cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                print("Cancelled")
            })
            
            syncAlert.addAction(okAction)
            syncAlert.addAction(cancelAction)
            
            self.present(syncAlert, animated: true, completion: nil)
            
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func logInLDSUser(username: String, password: String) {
        //Show alert on empty strings
        if (username == "" || password == "") {
            let alertview = UIAlertController(title: "Login Error", message: "Enter username and password to login", preferredStyle: UIAlertControllerStyle.alert)
            let alertAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: UIAlertActionStyle.default, handler: nil)
            alertview.addAction(alertAction)
            self.present(alertview, animated: true, completion: nil)
        }
            // Check if the id and password are valid
        else if (ldsIdIsValid(username: username, password: password)) {
            do {
                try Locksmith.deleteDataForUserAccount(userAccount: "callingWorkFlow")
            }
            catch {
                print("error deleting login data")
            }
            
            do {
                try Locksmith.saveData(data: ["username": username, "password": password], forUserAccount: "callingWorkFlow")
            }
            catch{
                print("error saving username")
            }
            
            self.dismiss(animated: true, completion: nil)
        }
            // Show alert on bad info
        else {
            let alertview = UIAlertController(title: "Login Error", message: "Invalid username or password.", preferredStyle: UIAlertControllerStyle.alert)
            let alertAction = UIAlertAction(title: NSLocalizedString("Ok", comment: ""), style: UIAlertActionStyle.default, handler: nil)
            alertview.addAction(alertAction)
            self.present(alertview, animated: true, completion: nil)
        }
    }
    
    func ldsIdIsValid(username: String, password: String) -> Bool {
        if (true) {
            return true
        }
        else {
            return false
        }
    }
    
    
    func syncOkHandler( alert: UIAlertAction ) {
        //Call to callingManager to resync
        if let callingService = self.callingMgr {
            self.startStaticFrameProcessingSpinner()
            
            callingService.reloadLdsData(forUser: nil, completionHandler: syncCompletionHandler)
            
        } else {
            // shouldn't happen - log/display error
        }
    }
    
    func syncCompletionHandler( success: Bool, error: Error? ) {
        DispatchQueue.main.async {
            self.removeProcessingSpinner()
            
            var completeMessage = "Data updated from lds.org"
            if !success {
                completeMessage = "Error communicating with lds.org. Please retry later."
            }
            let completeAlert = UIAlertController(title: NSLocalizedString("Sync Complete", comment: "Sync"), message: completeMessage, preferredStyle: UIAlertControllerStyle.alert)
            
            let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: UIAlertActionStyle.cancel, handler: {
                (alert: UIAlertAction!) -> Void in
                // nothing to do, just let the dialog be dismissed
            })
            
            completeAlert.addAction(okAction)
            
            self.present(completeAlert, animated: true, completion: nil)
        }
    }
}
