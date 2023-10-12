//
//  FloUIViewController.swift
//  Flo
//
//  Created by Maurice Bachelor on 5/25/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import UIKit

extension UIViewController {
    
    public class var storyboardId: String {
        return String(describing: self)
    }
    
    // MARK: - Show popups helping methods
    internal func showPopup(error: FloRequestErrorModel) {
        let alert = AlertPopupViewController.getInstance(title: error.title, description: error.message)
        alert.addOption(AlertPopupOption(title: "ok".localized))
        
        present(alert, animated: true, completion: nil)
    }
    
    internal func showPopup(
        title: String = "error_popup_title".localized,
        description: String? = nil,
        options: [AlertPopupOption] = [AlertPopupOption(title: "ok".localized)]
    ) {
        let alert = AlertPopupViewController.getInstance(title: title, description: description)
        for option in options {
            alert.addOption(option)
        }
        
        present(alert, animated: true, completion: nil)
    }
    
    internal func showPopup(
        title: String = "error_popup_title".localized,
        description: String? = nil,
        buttonText: String,
        buttonAction: (() -> Void)? = nil
    ) {
        let alert = AlertPopupViewController.getInstance(title: title, description: description)
        alert.addOption(AlertPopupOption(title: buttonText, action: buttonAction))
        
        present(alert, animated: true, completion: nil)
    }
    
    internal func showPopup(
        title: String = "error_popup_title".localized,
        description: String? = nil,
        acceptButtonText: String,
        acceptButtonAction: (() -> Void)? = nil,
        cancelButtonText: String,
        cancelButtonAction: (() -> Void)? = nil
    ) {
        let alert = AlertPopupViewController.getInstance(title: title, description: description)
        alert.addOption(AlertPopupOption(title: acceptButtonText, action: acceptButtonAction))
        alert.addOption(AlertPopupOption(title: cancelButtonText, type: .cancel, action: cancelButtonAction))
        
        present(alert, animated: true, completion: nil)
    }
    
    internal func showPopup(
        title: String = "error_popup_title".localized,
        description: String? = nil,
        inputView: AlertPopupHeaderProtocol,
        acceptButtonText: String,
        acceptButtonAction: (() -> Void)? = nil,
        cancelButtonText: String,
        cancelButtonAction: (() -> Void)? = nil
    ) {
        let alert = AlertPopupViewController.getInstance(title: title, description: description)
        alert.addHeader(inputView)
        alert.addOption(AlertPopupOption(title: acceptButtonText, action: acceptButtonAction))
        alert.addOption(AlertPopupOption(title: cancelButtonText, type: .cancel, action: cancelButtonAction))
        
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Navigation
    func popNavigation() {
        _ = navigationController?.popViewController(animated: true)
    }
    
    func popNavigation(_ vc: UIViewController) {
        _ = navigationController?.popToViewController(vc, animated: true)
    }
    
    func connectNewDevice() {
        if FloApiRequest.demoModeEnabled() {
            showPopup(title: "flo_error".localized + " 002", description: "feature_not_supported_in_demo_mode".localized)
        } else {
            let selectDeviceToPairVC = UIStoryboard(name: "Pairing", bundle: nil).instantiateViewController(withIdentifier: SelectDeviceToPairViewController.storyboardId)
            navigationController?.pushViewController(selectDeviceToPairVC, animated: true)
        }
    }

    func createCustomBackButton(_ target: AnyObject?, action: Selector) -> UIBarButtonItem {
        var width: CGFloat = 80
        var fontSize: CGFloat = 20
        if UIScreen.main.bounds.size.width <= 320 {
            width = 52
            fontSize = 16
        }
        
        let leftView = UIButton(frame: CGRect(x: 0, y: 0, width: width, height: 44))
        leftView.setTitle("< Back", for: UIControl.State())
        leftView.titleLabel?.font = UIFont(name: leftView.titleLabel!.font!.fontName, size: fontSize)
        leftView.titleLabel?.adjustsFontSizeToFitWidth = true
        leftView.titleLabel?.minimumScaleFactor = 1
        leftView.titleLabel?.textAlignment = .left
        leftView.setTitleColor(UIColor.white, for: UIControl.State())
        leftView.addTarget(target, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: leftView)
    }
    
    public func addContentController(_ child: UIViewController, toView: UIView, insideFrame: CGRect? = nil) {
        toView.addSubview(child.view)
        child.view.frame = insideFrame ?? CGRect(x: 0, y: 0, width: toView.frame.width, height: toView.frame.height)
        child.view.setNeedsLayout()
        addChild(child)
        child.didMove(toParent: self)
    }
    
}
