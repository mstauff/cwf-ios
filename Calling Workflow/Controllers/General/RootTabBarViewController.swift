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
    var globalDataSource = CWFCallingManagerService()

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
            let unitNum : Int64 = 0
            // todo - make this weak
            let appDelegate = UIApplication.shared.delegate as? AppDelegate
            appDelegate?.globalDataSource?.loadData(forUnit: unitNum, username: username, password: password) { (dataLoaded, error) -> Void in
                
                // todo: remove spinner
                if dataLoaded {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let loginVC = storyboard.instantiateViewController(withIdentifier: "LDSLogin")
                    
                    let navController2 = UINavigationController()
                    navController2.addChildViewController(loginVC)
                    
                    self.present(navController2, animated: false, completion: nil)
                    
                }
            }
        }
    }
    
}
