//
//  FloProtectViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 22/08/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class FloProtectViewController: FloBaseViewController {
    
    public var location: LocationModel!
    
    @IBOutlet fileprivate weak var locationNicknameLabel: UILabel!
    @IBOutlet fileprivate weak var manageAccountButton: UIButton!
    @IBOutlet fileprivate weak var statusView: UIView!
    @IBOutlet fileprivate weak var statusLabel: UILabel!
    @IBOutlet fileprivate var cardViews: [UIView]!
    @IBOutlet fileprivate weak var insuranceLabel: UILabel!
    @IBOutlet fileprivate weak var conciergeActionButton: UIButton!
    @IBOutlet fileprivate weak var conciergeShield1View: UIView!
    @IBOutlet fileprivate weak var conciergeShield2View: UIView!
    @IBOutlet fileprivate weak var conciergeHintView: UIView!
    
    @IBAction fileprivate func manageAccountAction() {
        if let url = URL(string: "https://user.meetflo.com/floprotect?source_id=ios&location=\(location.id)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
    @IBAction fileprivate func insuranceLetterAction() {
        if let url = URL(string: "https://user.meetflo.com/floprotect/insurance-letter?source_id=ios&location=\(location.id)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
    @IBAction fileprivate func deductibleGuaranteeAction() {
        if let url = URL(string: "https://user.meetflo.com/floprotect/deductible-guarantee?source_id=ios&location=\(location.id)"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
    @IBAction fileprivate func waterConciergeAction() {
        if location.floProtect {
            // TODO: - get the real subscription
            ChatHelper.setupAndStart(in: self.navigationController, status: "active_subscriber")
        } else {
            if let url = URL(string: "https://user.meetflo.com/floprotect?source_id=ios&location=\(location.id)"), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
            }
        }
    }
    @IBAction fileprivate func extendedWarrantyAction() {
        showPopup(
            title: "extended_warranty".localized,
            description: "extended_warranty_explanation".localized,
            options: [AlertPopupOption(title: "got_it".localized)]
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithBack(
            andTitle: "floprotect".localized,
            tint: StyleHelper.colors.white,
            titleColor: StyleHelper.colors.white
        )
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        locationNicknameLabel.text = location.nickname.isEmpty ? location.address : location.nickname
        statusView.layer.cornerRadius = statusView.frame.height / 2
        
        insuranceLabel.text = "download_letter_for_insurance".localized(args: [Calendar.current.component(.year, from: Date())])
        
        conciergeActionButton.layer.cornerRadius = conciergeActionButton.frame.height / 2
        conciergeActionButton.layer.shadowRadius = 8
        conciergeActionButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        conciergeActionButton.layer.shadowOpacity = 0.5
        conciergeActionButton.layer.masksToBounds = false
        
        conciergeShield1View.layer.cornerRadius = conciergeShield1View.frame.height / 2
        conciergeShield2View.layer.cornerRadius = conciergeShield2View.frame.height / 2
        
        conciergeHintView.layer.cornerRadius = 20
        conciergeHintView.layer.borderColor = UIColor(hex: "EBEFF5").cgColor
        conciergeHintView.layer.borderWidth = 1
        conciergeHintView.layer.shadowColor = StyleHelper.colors.blue.cgColor
        conciergeHintView.layer.shadowRadius = 8
        conciergeHintView.layer.shadowOffset = CGSize(width: 0, height: 8)
        conciergeHintView.layer.shadowOpacity = 0.2
        conciergeHintView.layer.masksToBounds = false
        
        for card in cardViews {
            card.layer.cornerRadius = 10
            card.layer.borderColor = UIColor(hex: "EBEFF5").cgColor
            card.layer.borderWidth = 1
        }
        
        if location.floProtect {
            manageAccountButton.setTitle("manage_your_account".localized + "  ", for: .normal)
            
            statusView.backgroundColor = StyleHelper.colors.green
            statusView.layer.shadowColor = StyleHelper.colors.gradientSecondaryGreen.cgColor
            statusView.layer.shadowRadius = 8
            statusView.layer.shadowOffset = CGSize(width: 0, height: 6)
            statusView.layer.shadowOpacity = 0.5
            statusView.layer.masksToBounds = false
            
            statusLabel.text = "on".localized.uppercased()
            
            conciergeActionButton.layer.shadowColor = StyleHelper.colors.gradientSecondaryGreen.cgColor
            conciergeActionButton.setTitle("open_chat".localized, for: .normal)
        } else {
            manageAccountButton.setTitle("activate_floprotect".localized + "  ", for: .normal)
            
            statusLabel.text = "off".localized.uppercased()
            
            conciergeActionButton.layer.shadowColor = StyleHelper.colors.cyan.cgColor
            conciergeActionButton.layer.addGradient(from: StyleHelper.colors.cyan, to: StyleHelper.colors.darkCyan, angle: 0)
            conciergeActionButton.setTitle("activate".localized, for: .normal)
            conciergeShield1View.backgroundColor = StyleHelper.colors.darkCyan
            conciergeShield2View.backgroundColor = StyleHelper.colors.darkCyan
        }
    }
    
    // MARK: - Overrides
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let floDetectFixtureVC = segue.destination as? FloDetectFixtureViewController {
            floDetectFixtureVC.location = location
        }
    }
    
}
