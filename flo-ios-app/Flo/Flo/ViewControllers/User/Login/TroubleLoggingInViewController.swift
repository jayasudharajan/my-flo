//
//  TroubleLoggingInViewController.swift
//  Flo
//
//  Created by Matias Paillet on 5/28/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class TroubleLoggingInViewController: FloBaseViewController {
    
    @IBOutlet fileprivate weak var txtDescription: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithCancel()
        
        configureView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    fileprivate func configureView() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        
        let attrString = NSMutableAttributedString(
            string: "having_difficulty_logging_into_your_flo_account".localized
        )
        attrString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attrString.length))
        
        txtDescription.attributedText = attrString
    }
    
    @IBAction fileprivate func openResetPassword() {
        let emailInputView = AlertPopupEmailHeader.getInstance()
        showPopup(
            title: "reset_password".localized,
            description: "reset_password_instructions_will_be_emailed".localized,
            inputView: emailInputView,
            acceptButtonText: "submit".localized,
            acceptButtonAction: {
                self.showLoadingSpinner("loading".localized)
                let email = emailInputView.getEmail()
                let data = ForgotPasswordModel(email: email)
                FloApiRequest(
                    controller: "v1/users/requestreset/user",
                    method: .post,
                    queryString: nil,
                    data: data.jsonify(),
                    done: { (error, _) in
                        self.hideLoadingSpinner()
                        if let e = error {
                            self.showPopup(error: e)
                        } else {
                            self.showPopup(
                                title: "reset_password".localized,
                                description: "if_account_exists_password_reset_email_sent_to".localized + " " + email + "."
                            )
                        }
                    }
                ).unsecureFloRequest()
            },
            cancelButtonText: "cancel".localized
        )
    }
}
