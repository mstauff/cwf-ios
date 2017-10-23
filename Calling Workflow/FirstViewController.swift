
//  FirstViewController.swift
//  Calling Workflow
//
//  Created by Matt Stauffer on 9/21/16.
//  Copyright © 2016 LDSCD. All rights reserved.
//

//import UIKit
//
//class FirstViewController: UIViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view, typically from a nib.
//    }
//
//    override func didReceiveMemoryWarning() {
//        super.didReceiveMemoryWarning()
//        // Dispose of any resources that can be recreated.
//    }
//
//
//}
//
import GoogleAPIClient
import GTMOAuth2
import UIKit

class FirstViewController: CWFBaseViewController, GIDSignInUIDelegate, GIDSignInDelegate {
    
    var dataObject = ""
    // TODO - need a constructor/init in the interface
    //    private let dataSource = RemoteDataSource()
//    private let callingMgr = CallingDataManager( initDataSource: RemoteDataSource() )
    
    var remoteDataSource : RemoteDataSource? = nil
    
    @IBOutlet var output: UITextView!
    
    @IBAction func signOutClicked(_ sender: Any) {
        GIDSignIn.sharedInstance().signOut()
        print( "signed out" )
    }

    //        callingMgr.updateOrgCallings(org: eq) { [weak weakSelf=self] error in
//            guard error == nil else {
//                print( "Error on update: " + error.debugDescription )
//                weakSelf?.showAlert(title: "Error Updating Data", message: error.debugDescription)
//                return
//            }
//            self.output.text = "Data Updated"
        
//        }
    
    // When the view loads, create necessary subviews
    // and initialize the Drive API service
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Google Account Management"
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self

        // todo - should implement optional GIDSignInUIDelegate methods to handle sign in results
        
    }
    
    // When the view appears, ensure that the Drive API service is authorized
    // and perform API calls
    override func viewDidAppear(_ animated: Bool) {
        
//        if callingMgr.dataSource.isAuthenticated {
//            self.output.text = "Authenticated! Good to go"
//        } else {
//            callingMgr.dataSource.authenticate(currentVC: self) {  [weak weakSelf=self]  _,_, error in
//                if let error = error {
//                    weakSelf?.showAlert(title: "Authentication Error", message: error.localizedDescription)
//                } else {
//                    weakSelf?.dismiss(animated: true, completion: nil)
//                }
//                
//            }
//        }
    }
    
    // Parse results and display
    //    func displayResultWithTicket(ticket : GTLServiceTicket,
    //                                 finishedWithObject response : GTLDriveFileList,
    //                                 error : NSError?) {
    //
    //        if let error = error {
    //            showAlert(title: "Error", message: error.localizedDescription)
    //            return
    //        }
    //
    //        var filesString = ""
    //
    //        if let files = response.files , !files.isEmpty {
    //            filesString += "Files:\n"
    //            for file in files as! [GTLDriveFile] {
    //                filesString += "\(file.name) (\(file.identifier))\n"
    //                self.configFile = file
    //            }
    //        } else {
    //            filesString = "No files found."
    //        }
    //        print( filesString )
    //        output.text = filesString
    //    }
    //
    
    // Creates the auth controller for authorizing access to Drive API
    // this has been moved to RemoteDataSource.authenticate()
    //    private func createAuthController() -> GTMOAuth2ViewControllerTouch {
    //        let scopeString = scopes.joined(separator: " ")
    //        return GTMOAuth2ViewControllerTouch(
    //            scope: scopeString,
    //            clientID: kClientID,
    //            clientSecret: nil,
    //            keychainItemName: kKeychainItemName,
    //            delegate: self,
    //            finishedSelector: #selector(viewController(vc:finishedWithAuth:error:))
    //        )
    //    }
    
    // Helper for showing an alert
    func showAlert(title : String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let ok = UIAlertAction(
            title: NSLocalizedString("OK", comment: "OK"),
            style: UIAlertActionStyle.default,
            handler: nil
        )
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: - GDISignIn delegate
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            print("There is an error")
        }
        else {
            print("Sign in successful")
            self.dismiss(animated: true, completion: nil)
            self.navigationController?.popViewController(animated: true)
        }
    }
}
