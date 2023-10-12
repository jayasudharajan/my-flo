//
//  LoginViewController.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/30/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import UIKit
import Embrace

internal class LoginViewController: FloBaseViewController {
    
    public var authErrorMessage: String?
    fileprivate var emailBackup: String?
    
    @IBOutlet fileprivate weak var versionLabel: UILabel!
    @IBOutlet fileprivate weak var floLogoImageView: UIImageView!
    @IBOutlet fileprivate weak var emailTextField: UITextField!
    @IBOutlet fileprivate weak var passwordTextField: UITextField!
    @IBOutlet fileprivate weak var loginButton: UIButton!
    @IBOutlet fileprivate weak var signupButton: UIButton!
    
    @IBAction fileprivate func loginAction(_ sender: AnyObject) {
        if !validateEmail() || !validatePassword() {
            return
        }
        
        let loginModel = UserOAuthModel(
            username: (emailTextField.text ?? "").lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
            password: (passwordTextField.text ?? ""),
            grantType: .password
        )
        
        performLogin(loginModel)
    }
    
    fileprivate func performLogin(_ loginModel: UserOAuthModel) {
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        
        showLoadingSpinner("logging_in".localized)
        
        FloApiRequest(
            controller: "v1/oauth2/token",
            method: .post,
            queryString: nil,
            data: loginModel.userJson,
            done: { (error, data) in
                if error != nil {
                    self.hideLoadingSpinner()
                    self.showPopup(
                        title: "flo_error".localized + " 003",
                        description: "invalid_username_or_password".localized,
                        options: [AlertPopupOption(title: "ok".localized)]
                    )
                } else {
                    self.parseLoginData(data)
                }
            }
        ).unsecureFloRequest()
        
        // Clean sensitive data for security reasons
        loginModel.username = ""
        loginModel.password = ""
    }
    
    @IBAction fileprivate func signupAction(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Registration", bundle: nil)
        
        if let signupViewController = storyboard.instantiateViewController(
            withIdentifier: SignupViewController.storyboardId) as? SignupViewController {
            signupViewController.prefilledEmail = self.emailTextField.text
            self.navigationController?.pushViewController(signupViewController, animated: true)
        }
    }
    
    @IBAction fileprivate func setupGuideAction() {
        TrackingManager.shared.track(TrackingManager.kEventSetupGuide)
        if let url = URL(string: "https://meetflo.com/setup") {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction fileprivate func goToTroubleLoggingIn() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        
        if let controller = storyboard.instantiateViewController(
            withIdentifier: TroubleLoggingInViewController.storyboardId) as? TroubleLoggingInViewController {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        versionLabel.text = "v" + Bundle.main.versionNumber
        FloApiRequest.shouldMockServices(shouldMock: false)
        
        // End startup moment for Embrace
        Embrace.sharedInstance()?.endAppStartup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Clear user and password everytime the screen shows
        passwordTextField.text = ""
        emailTextField.text = ""
        
        // Configure view to listen for go-to-background events
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // Tracking reset
        TrackingManager.shared.reset()
        
        // Cleaning local storage
        StatusManager.shared.stopTracking()
        RatingHelper.cleanTimer()
        
        // UI customization
        passwordTextField.addSecureTextEntrySwitch()
        
        if let message = authErrorMessage {
            showPopup(title: message)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Observers callback methods
    @objc fileprivate func appMovedToBackground() {
        emailBackup = emailTextField.text
        emailTextField.text = ""
        emailTextField.resignFirstResponder()
        
        passwordTextField.text = ""
        passwordTextField.resignFirstResponder()
    }
    
    @objc fileprivate func appMovedToForeground() {
        if let email = emailBackup, !email.isEmpty {
            emailTextField.text = email
        }
    }
    
    // MARK: - Textfields protocol methods
    override public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField != passwordTextField {
            _ = super.textFieldShouldEndEditing(textField)
        }
        return true
    }
    
    override public func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == emailTextField {
            _ = validateEmail()
        } else {
            _ = validatePassword()
        }
    }
    
    // MARK: - Text fields validation
    fileprivate func validateEmail() -> Bool {
        emailTextField.resignFirstResponder()
        let email = emailTextField.text ?? ""
        
        if !email.isValidEmail() {
            emailTextField.displayError("please_enter_a_valid_email".localized)
            return false
        }
        
        return true
    }
    
    fileprivate func validatePassword() -> Bool {
        passwordTextField.resignFirstResponder()
        let password = passwordTextField.text ?? ""
        
        if password.isEmpty {
            passwordTextField.displayError("password_not_empty".localized)
            return false
        }
        
        return true
    }
    
    // MARK: - Login callback
    fileprivate func parseLoginData(_ data: AnyObject?) {
        if let auth = OAuthModel(data) {
            UserSessionManager.shared.upsertAuthorization(auth)
            let email = (emailTextField.text ?? "").lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            
            SecAddSharedWebCredential(
                "meetflo.com" as CFString,
                email as CFString,
                (passwordTextField.text ?? "") as CFString
            ) { error in
                if let e = error {
                    LoggerHelper.log(e.localizedDescription, level: .error)
                }
            }
            
            UserSessionManager.shared.getUser { (error, _) in
                if let e = error {
                    self.showPopup(error: e)
                } else {
                    LocationsManager.shared.getAll { success in
                        self.hideLoadingSpinner()
                        if success {
                            TrackingManager.shared.identify(auth.userId, email: email)
                            AWSPinpointManager.shared.loginUser(withId: auth.userId)
                            AWSPinpointManager.shared.logEvent("login", withParams: ["email": email])
                            self.goToDashboard()
                        } else {
                            self.showPopup(description: "something_went_wrong_please_retry".localized)
                        }
                    }
                }
            }
        } else {
            hideLoadingSpinner()
            showPopup(description: "something_went_wrong_please_retry".localized)
        }
    }
    
    // MARK: - Navigation
    fileprivate func goToDashboard() {
        DispatchQueue.main.async {
            self.passwordTextField.text = ""
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let entryPoint = storyboard.instantiateViewController(withIdentifier: TabBarController.storyboardId) as? TabBarController {
            UIApplication.shared.keyWindow?.rootViewController = entryPoint
            UIApplication.shared.keyWindow?.makeKeyAndVisible()
        }
    }
    
    // MARK: - Demo mode
    @IBAction fileprivate func enterDemoMode() {
        FloApiRequest.shouldMockServices(shouldMock: true)
        
        let loginModel = UserOAuthModel(
            username: "demo@mode.com",
            password: "Demomode1",
            grantType: .password
        )
        
        performLogin(loginModel)
    }
    
}
