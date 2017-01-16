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
            let unitNum : Int64 = 0
            
            guard appConfig != nil else {
                print( "No app config" )
                return
            }
            let ldsApi = LdsFileApi(appConfig: appConfig!)
            ldsApi.ldsSignin(username: username, password: password,  { (error) -> Void in
                if error != nil {
                    print( error!)
                } else {
                    ldsApi.getMemberList(unitNum: unitNum) { (members, error) -> Void in
                        if members != nil && !members!.isEmpty {
                            print( "First Member of unit:\(members![0])" )
                        } else {
                            print( "no user" )
                        }
                    }
                    
                    ldsApi.getOrgWithCallings(unitNum: unitNum ) { (org, error) -> Void in
                        if org != nil && !org!.children.isEmpty {
                            print( "First Org of unit:\(org!.children[0])" )
                            
                        } else {
                            print( "no org" )
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
