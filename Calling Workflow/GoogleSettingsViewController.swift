
import GoogleAPIClient
import GTMOAuth2
import UIKit

class GoogleSettingsViewController: CWFBaseViewController, AlertBox, GIDSignInUIDelegate, GIDSignInDelegate {
    
    var dataObject = ""
    
    var remoteDataSource : RemoteDataSource? = nil
    
    var addBackButton : Bool = false
    
    @IBOutlet var output: UITextView!
    @IBOutlet weak var resetDataBtn: UIButton!
    
    // Button to sign out of google
    @IBAction func signOutClicked(_ sender: Any) {
        showAlert(title: "Change Ward Unit", message: "This will sign you out of the google drive account used by your current ward. You should only do this if you have moved out  of a ward.", includeCancel: true ) { _ in
            GIDSignIn.sharedInstance().signOut()
        }
    }
    
    // button to reset google data (in case of some type of data corruption)
    @IBAction func resetDataClicked(_ sender: Any) {
        // initial warning box letting the user know what the next view does
        showAlert(title: "Warning", message: "This option is only to correct errors in individual organizations. If you are experiencing errors and unable to view certain organizations this option may correct it. It will destroy any in process calling data for the organization, and replace it with existing callings from lds.org. Do you want to select which organizations need reset?", includeCancel: true) { _ in
            self.performSegue(withIdentifier: "GoogleSettingsToResetData", sender: nil)
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
             let callingMgr = appDelegate.callingManager
            resetDataBtn.isHidden = !callingMgr.permissionMgr.hasPermission(unitRoles: callingMgr.userRoles, domain: Domain.UnitGoogleAccount, permission: .Update )
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
            }
        }
    }
    
    func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
}
