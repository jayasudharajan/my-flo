//
//  AppV2PopupViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 18/10/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class AppV2PopupViewController: UIViewController {
    
    fileprivate static let kWasShown = "AppV2PopupWasShown"
    fileprivate static let kOldAppKey = "LAST_RATE_REQ"
    public static var needsToBeShown: Bool {
        return UserDefaults.standard.bool(forKey: kOldAppKey) && !UserDefaults.standard.bool(forKey: kWasShown)
    }
    
    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var explanationLabel: UILabel!
    @IBOutlet fileprivate weak var dismissButton: UIButton!
    
    @IBAction fileprivate func linkAction() {
        if let url = URL(string: "https://youtu.be/f35gctshj1I"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction fileprivate func dismissAction() {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        containerView.layer.cornerRadius = 10
        
        let attributedExplanation = NSMutableAttributedString(
            string: "We've simplified the interface, and your app now supports multiple locations and devices all within one account.\n\nHave multiple accounts and want to merge into one? Simply reach out to us at support@meetflo.com.\n\nNeed help using the app? Check out our app overview video by clicking here.",
            attributes: [
                NSAttributedString.Key.font: StyleHelper.font(sized: .small),
                NSAttributedString.Key.foregroundColor: UIColor(hex: "808E9E")
            ]
        )
        attributedExplanation.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 252, length: 36))
        explanationLabel.attributedText = attributedExplanation
        
        dismissButton.layer.cornerRadius = dismissButton.frame.height / 2
        dismissButton.layer.addGradient(from: StyleHelper.colors.cyan, to: StyleHelper.colors.darkCyan, angle: 90)
        
        // Background blur effect
        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurEffectView.frame = view.frame
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurEffectView)
        view.sendSubviewToBack(blurEffectView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UserDefaults.standard.set(true, forKey: AppV2PopupViewController.kWasShown)
        UserDefaults.standard.removeObject(forKey: AppV2PopupViewController.kOldAppKey)
    }
    
    // MARK: - Instantiation
    public class func getInstance() -> UIViewController {
        return UIStoryboard(name: "Common", bundle: nil).instantiateViewController(withIdentifier: AppV2PopupViewController.storyboardId)
    }
}
