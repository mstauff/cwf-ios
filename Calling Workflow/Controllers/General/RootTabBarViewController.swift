//
//  RootTabBarViewController.swift
//  Calling Workflow
//
//  Created by Chad Olsen on 12/1/16.
//  Copyright © 2016 colsen. All rights reserved.
//

import UIKit

class RootTabBarViewController: UITabBarController {

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
        let ldscdApi = LdscdRestApi()
        ldscdApi.getAppConfig() { (appConfig, error) in

            // Populate these locally - Don't commit to github
            let username = ""
            let password = ""
            let unitNum = 0
            
            guard appConfig != nil else {
                print( "No app config" )
                return
            }
            let ldsApi = LdsRestApi(appConfig: appConfig!)
            ldsApi.ldsSignin(username: username, password: password,  { (error) -> Void in
                if error != nil {
                    
                    print( error!)
                } else {
                    ldsApi.getMemberList(unitNum: Int64(unitNum)) { (members, error) -> Void in
                        if members != nil && !members!.isEmpty {
                            print( members![0] )
                            
                        } else {
                            print( "no user" )
                        }
                        
                    }
                }
            })
            
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LDSLogin")
        
        let navController2 = UINavigationController()
        navController2.addChildViewController(loginVC)
        
        self.present(navController2, animated: false, completion: nil)
        
    }

}
