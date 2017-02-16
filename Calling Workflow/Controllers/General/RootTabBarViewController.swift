//
//  RootTabBarViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 12/1/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class RootTabBarViewController: UITabBarController {

    // eventually this only lives in AppDelegate, but we need to figure out the communication between app delegate and VC when all the data is loaded.
    var callingManager = CWFCallingManagerService()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        signIntoLDSAPI()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
    func signIntoLDSAPI() {
        // todo: put up a spinner
        let ldscdApi = LdscdRestApi()
        ldscdApi.getAppConfig() { (appConfig, error) in

            // Populate these locally - Don't commit to github
            let username = ""
            let password = ""
            let unitNum: Int64 = 0
            // todo - make this weak
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            self.callingManager.loadLdsData(forUnit: unitNum, username: username, password: password) { [weak weakSelf = self ] (dataLoaded, error) -> Void in

                    // todo: remove spinner
                    if dataLoaded {
                        weakSelf?.callingManager.authorizeDataSource(currentVC: self) { [weak weakSelf = self]  _, _, error in
                            if let error = error {
                                weakSelf?.showAlert(title: "Authentication Error", message: error.localizedDescription)
                            } else {
                                if let validOrg = weakSelf?.callingManager.appDataOrg {
                                    weakSelf?.callingManager.loadAppData() { success, hasOrgsToDelete, error in

                                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                        let loginVC = storyboard.instantiateViewController(withIdentifier: "LDSLogin")

                                        let navController2 = UINavigationController()
                                        navController2.addChildViewController(loginVC)

                                        weakSelf?.present(navController2, animated: false, completion: nil)

                                    }

                                }

                            }

                        }
                    }
//                }
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


}
