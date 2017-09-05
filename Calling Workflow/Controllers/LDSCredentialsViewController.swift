//
//  LDSCredentialsViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/9/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit
import Locksmith

class LDSCredentialsTableViewController: CWFBaseTableViewController {
    
    var userNameField : UITextField?
    var passwordField : UITextField?
    
    var keychainDataDictionary: Dictionary<String, String>?
    
    var delegate : LDSLoginDelegate? = nil
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameField = nil
        passwordField = nil
        
        keychainDataDictionary = Locksmith.loadDataForUserAccount(userAccount: "callingWorkFlow") as! Dictionary<String, String>?
        
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
        case 0:
            return NSLocalizedString("LDS Account", comment: "LDS Account")
        default:
            return ""
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        default:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as? InputTableViewCell

            switch indexPath.row {
            case 0:
                if (keychainDataDictionary?["username"] != nil) {
                    cell?.inputField?.text = keychainDataDictionary?["username"]
                }
                else {
                    cell?.inputField?.placeholder = NSLocalizedString("LDS Username", comment: "LDS.org Username")
                }
                self.userNameField = cell?.inputField
                
            case 1:
                if (keychainDataDictionary?["password"] != nil) {
                    cell?.inputField.text = keychainDataDictionary?["password"]
                }
                else {
                    cell?.inputField?.placeholder = NSLocalizedString("Password", comment: "Password")
                }
                cell?.inputField?.isSecureTextEntry = true
                passwordField = cell?.inputField 
                
            default:
                cell?.textLabel?.text = nil
            }
            return cell!
            
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "buttonCell", for: indexPath)
            
            return cell
            
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "inputCell", for: indexPath) as? InputTableViewCell
            cell?.inputField = nil
            return cell!
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            tableView.deselectRow(at: indexPath, animated: true)

        case 1:
            userNameField?.resignFirstResponder()
            passwordField?.resignFirstResponder()
            
            logInLDSUser(username: (self.userNameField?.text)!, password: (passwordField?.text)!)
            tableView.deselectRow(at: indexPath, animated: true)
            
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
}
