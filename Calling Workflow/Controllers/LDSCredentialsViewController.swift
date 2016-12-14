//
//  LDSCredentialsViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 11/9/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class LDSCredentialsTableViewController: CallingsBaseTableViewController {

    var accountName : String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let accountName = accountName {
            do {
                let passwordItem = KeychainPasswordItem(service: KeychainConfiguration.serviceName, account: accountName, accessGroup: KeychainConfiguration.accessGroup)
                
                accountNameField.text = passwordItem.account
                passwordField.text = try passwordItem.readPassword()
            }
            catch {
                fatalError("Error reading password from keychain - \(error)")
            }
        }
        // Do any additional setup after loading the view.
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
    
//    override func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
//        return -0.1
//    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "LDS Account"
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
                cell?.inputField?.placeholder = "LDS Username"
            case 1:
                cell?.inputField?.placeholder = "Password"
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
            logInLDSUser()
            tableView.deselectRow(at: indexPath, animated: true)

        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func logInLDSUser() {
        print("loging in lds user")
        self.dismiss(animated: true, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
