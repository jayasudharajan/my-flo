//
//  SignupVerifyEmailViewController.swift
//  Flo
//
//  Created by Matias Paillet on 5/28/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class SignupVerifyEmailViewController: FloBaseViewController {
    
    @IBOutlet fileprivate weak var btnResendEmail: UIButton!
    @IBOutlet fileprivate weak var txtDescription: UILabel!
    
    public var emailToVerify: String?
    
    // MARK: Lifecycle
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithCancel()
        
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    fileprivate func configureView() {
        
        // UI Customization
        let underlinedTerms = NSAttributedString(
            string: "resend_email".localized,
            attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue])
        btnResendEmail.titleLabel?.attributedText = underlinedTerms
        
        if let email = emailToVerify {
            let description = "\("an_email_has_been_sent_to".localized) \(email).  \("please_check_your_email_to_verify_you_account".localized)"
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 10
            
            let attrString = NSMutableAttributedString(string: description)
            attrString.addAttribute(.paragraphStyle,
                                    value: paragraphStyle,
                                    range: NSRange(location: 0, length: attrString.length))
            
            txtDescription.attributedText = attrString
        }
    }
    
    @IBAction fileprivate func resendEmail() {
        if let email = emailToVerify {
            showLoadingSpinner("loading".localized)
            var data = [String: AnyObject]()
            data["email"] = email as AnyObject
            
            FloApiRequest(
                controller: "v2/users/register/resend",
                method: .post,
                queryString: nil,
                data: data,
                done: { (error, _) in
                    self.hideLoadingSpinner()
                    if let e = error {
                        self.showPopup(error: e)
                    } else {
                        self.showPopup(title: "flo".localized, description: "the_verification_email_has_been_sent_again".localized)
                    }
                }
            ).unsecureFloRequest()
        }
    }
    
    @IBAction fileprivate func openEmailApp() {
        if let url = URL(string: "message://") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }
        
    }
    
    @IBAction override func goBack() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
}
