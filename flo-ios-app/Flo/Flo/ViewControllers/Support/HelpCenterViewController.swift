//
//  HelpCenterViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 23/08/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import IQKeyboardManager

internal class HelpCenterViewController: FloBaseViewController {
    
    public var location: LocationModel?
    
    @IBOutlet fileprivate var cardViews: [UIView]!
    @IBOutlet fileprivate weak var conciergeActionButton: UIButton!
    @IBOutlet fileprivate weak var conciergeShield1View: UIView!
    @IBOutlet fileprivate weak var conciergeShield2View: UIView!
    
    @IBAction fileprivate func waterConciergeAction() {
        if let location = location {
            if location.floProtect {
                // TODO: - get the real subscription
                ChatHelper.setupAndStart(in: self.navigationController, status: "active_subscriber")
            } else {
                if let url = URL(string: "https://user.meetflo.com/floprotect?source_id=ios&location=\(location.id)"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    
    @IBAction fileprivate func supportArticlesAction() {
        if let url = URL(string: "https://support.meetflo.com/hc/en-us"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction fileprivate func setupGuideAction() {
       TrackingManager.shared.track(TrackingManager.kEventSetupGuide)
       if let url = URL(string: "https://meetflo.com/setup") {
           UIApplication.shared.openURL(url)
       }
    }
    
    @IBAction fileprivate func goToContactUs() {
       TrackingManager.shared.track(TrackingManager.kEventSetupGuide)
       if let url = URL(string: "https://support.meetflo.com/hc/en-us/requests/new") {
           UIApplication.shared.openURL(url)
       }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar(with: "help_center".localized)
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        conciergeActionButton.layer.cornerRadius = conciergeActionButton.frame.height / 2
        conciergeActionButton.layer.shadowRadius = 8
        conciergeActionButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        conciergeActionButton.layer.shadowOpacity = 0.5
        conciergeActionButton.layer.masksToBounds = false
        
        conciergeShield1View.layer.cornerRadius = conciergeShield1View.frame.height / 2
        conciergeShield2View.layer.cornerRadius = conciergeShield2View.frame.height / 2
        
        for card in cardViews {
            card.layer.cornerRadius = 10
            card.layer.borderColor = UIColor(hex: "EBEFF5").cgColor
            card.layer.borderWidth = 1
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        location = LocationsManager.shared.selectedLocation
        for layer in conciergeActionButton.layer.sublayers ?? [] where layer is FloGradientLayer {
            layer.removeFromSuperlayer()
            break
        }
        
        if location?.floProtect == true {
            conciergeActionButton.layer.shadowColor = StyleHelper.colors.gradientSecondaryGreen.cgColor
            conciergeActionButton.setTitle("open".localized, for: .normal)
            conciergeShield1View.backgroundColor = StyleHelper.colors.green
            conciergeShield2View.backgroundColor = StyleHelper.colors.green
        } else {
            conciergeActionButton.layer.shadowColor = StyleHelper.colors.cyan.cgColor
            conciergeActionButton.layer.addGradient(from: StyleHelper.colors.cyan, to: StyleHelper.colors.darkCyan, angle: 0)
            conciergeActionButton.setTitle("activate".localized, for: .normal)
            conciergeShield1View.backgroundColor = StyleHelper.colors.darkCyan
            conciergeShield2View.backgroundColor = StyleHelper.colors.darkCyan
        }
        
        //Re-enable IQKeyboard Manager
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().isEnableAutoToolbar = true
        IQKeyboardManager.shared().shouldResignOnTouchOutside = true
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }

}
