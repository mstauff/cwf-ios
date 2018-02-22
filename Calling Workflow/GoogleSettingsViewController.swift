
import GoogleAPIClient
import GTMOAuth2
import UIKit

class GoogleSettingsViewController: CWFBaseViewController, AlertBox, GIDSignInUIDelegate, GIDSignInDelegate {
    
    var dataObject = ""
    
    var callingMgr : CWFCallingManagerService? = nil
    var reinitDelegate: InitializeAppDataDelegate? = nil

    var addBackButton : Bool = false
    
    @IBOutlet var output: UITextView!
    var signedIn = false
    var didSignOut = false
    var newSignIn = false

    @IBOutlet weak var signedInAsLabel: UILabel!
    @IBOutlet weak var resetDataBtn: UIButton!
    // this is the google signin button - we've replaced it with our own signin button that toggles the label based on state. It appears all the google version did when called is call sharedInstance().signIn()
//    @IBOutlet weak var signInView: GIDSignInButton!
    // Button to sign out of google
    
    @IBOutlet weak var signInOutBtn: UIButton!
    // button to reset google data (in case of some type of data corruption)
    @IBAction func resetDataClicked(_ sender: Any) {
        // initial warning box letting the user know what the next view does
        showAlert(title: "Warning", message: "This option is only to correct errors in individual organizations. If you are experiencing errors and unable to view certain organizations this option may correct it. It will destroy any in process calling data for the organization, and replace it with existing callings from lds.org. Do you want to select which organizations need reset?", includeCancel: true) { _ in
            self.performSegue(withIdentifier: "GoogleSettingsToResetData", sender: nil)
        }
    }

    @IBAction func signInOutClicked(_ sender: Any) {
        if signedIn {
            showAlert(title: "Change Ward Unit", message: "This will sign you out of the google drive account used by your current ward. You should only do this if you have moved out  of a ward.", includeCancel: true ) { _ in
                self.callingMgr?.dataSource.signOut()
                // set the signed in status so the UI can be updated
                self.setSigninStatus(false, inUnit: nil)
                // mark that there was a signed in user that signed out so we know how to reload data when we leave this view
                self.didSignOut = true
            }
        } else {
            GIDSignIn.sharedInstance().signIn()
            // afer signin we return to Orgs, so no need to update UI elements in this view
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Google Account Management"
        
        if (addBackButton) {
            let button = UIButton(type: .custom)
            button.setImage(UIImage.init(named: "backButton"), for: .normal)
            button.addTarget(self, action: #selector(dismissView), for: .touchUpInside)
            button.frame = CGRect(x: 0, y: 0, width: 53.0, height: 31.0)
            let backButton = UIBarButtonItem(customView: button)
            navigationItem.setLeftBarButton(backButton, animated: true)

        }

        // setup the callbacks for the google signin process
        GIDSignIn.sharedInstance().uiDelegate = self 
        GIDSignIn.sharedInstance().delegate = self

        // reset data button is not shown by default, only show if they're a unit admin
        resetDataBtn.isHidden = true
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
             self.callingMgr = appDelegate.callingManager
            resetDataBtn.isHidden = !self.callingMgr!.permissionMgr.hasPermission(unitRoles: self.callingMgr!.userRoles, domain: Domain.UnitGoogleAccount, permission: .Update )
            // if there's a username in the data source then they must have successfully logged in.
            if let userName = self.callingMgr?.dataSource.userName {
                var unitName : String
                // for right now we just display the unit number to confirm that the user is logged in.
                // if it's not a standard format user number (ldscd-cwf--24341@gmail.com), we can't parse out the unit number, so we just show the whole account name. Maybe eventually we'll pull the ward name from the current user json
                if let unitNum = self.callingMgr?.dataSource.unitNum {
                    // We have to be sure and pass an Int, not Int? to this init method. If it's Int? then the String becomes "Optional('47142')", the Optional text becomes part of the string
                    unitName = String( describing: unitNum )
                } else {
                    unitName = userName
                }
                setSigninStatus(true, inUnit: unitName)
            } else {
                setSigninStatus(false, inUnit: nil)
            }
        }
    }
    
    // When the view appears, ensure that the Drive API service is authorized
    // and perform API calls
    override func viewDidAppear(_ animated: Bool) {
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - GDISignIn delegate
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if error != nil {
            showAlert(title: "Sign-in Error", message: "There was an error signing in to your ward google drive account. Please try again", includeCancel: false, okCompletionHandler: nil)
        } else {
            showAlert(title: "Sign-in Success", message: "You have successfully signed in to your ward's google drive account.", includeCancel: false) { _ in
                self.dismiss(animated: true, completion: nil)
                self.navigationController?.popViewController(animated: true)
                self.newSignIn = true
            }
        }
        if let callingMgrSignInDelegate = callingMgr?.dataSource as? GIDSignInDelegate {
            callingMgrSignInDelegate.sign(signIn, didSignInFor: user, withError: error)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.newSignIn {
            // if there was a user that changed (signed out, then back in), we don't want to use any cached data. But if they just signed in for the first time (they didn't sign out first because they weren't logged in) then we can use cached data (this basically prevents us from having to reload all the lds.org data for first time users)
            self.reinitDelegate?.reinitApp(useCache: !self.didSignOut)
        }
    }
    
    func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }

    private func setSigninStatus( _ isSignedIn : Bool, inUnit unitName: String? ) {
        self.signedIn = isSignedIn
        if isSignedIn {
            self.signInOutBtn.setTitle("Sign Out", for: .normal)
            self.signedInAsLabel.text = unitName == nil ? "Signed In" : "Signed in to unit " + unitName!
        } else {
            self.signInOutBtn.setTitle("Sign In", for: .normal)
            self.signedInAsLabel.text = "You must sign in with your ward google account created for this app to begin using the app."
        }
    }
}
