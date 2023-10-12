//
//  SignupTermsViewController.swift
//  Flo
//
//  Created by Matias Paillet on 5/27/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class SignupTermsViewController: FloBaseViewController {
    
    @IBAction fileprivate func firstButtonAction() {
        if let url = URL(string: "https://support.meetflo.com/hc/en-us/articles/230089687-Terms-of-Service") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }
    }
    @IBAction fileprivate func secondButtonAction() {
        if let url = URL(string: "https://support.meetflo.com/hc/en-us/articles/230425728-Privacy-Statement") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }
    }
    @IBAction fileprivate func thirdButtonAction() {
        if let url = URL(string: "https://support.meetflo.com/hc/en-us/articles/230089707-Limited-Warranty") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }
    }
    @IBAction fileprivate func fourthButtonAction() {
        if let url = URL(string: "https://support.meetflo.com/hc/en-us/articles/230425668-End-User-License-Agreement") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithBack(
            andTitle: "legal_and_policies".localized,
            tint: StyleHelper.colors.white,
            titleColor: StyleHelper.colors.white
        )
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
    }
    
    // MARK: - Overrides
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
}
