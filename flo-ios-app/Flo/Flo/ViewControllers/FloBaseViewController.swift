//
//  FloBaseController.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/15/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import UIKit
import SystemConfiguration.CaptiveNetwork
import QuartzCore

internal class FloBaseViewController: UIViewController, UITextFieldDelegate {
    // ScreenTracking variables
    public var controller = ""
    
    public var animatingFlow = false
    private var navBarDarkModeEnabled = false
    private var spinnerButton: UIButton?
    
    //Loader with rotating messages variables
    fileprivate var loaderMsgsSwapTimer: Timer?
    fileprivate var loaderMsgs: [String] = []
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    // MARK: Lifecyle
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        setNavBarTransparent()
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(shouldHideNavBar(), animated: true)
        
        checkIfDemoLabelNeeded()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !controller.isEmpty {
            TrackingManager.shared.startTimer(TrackingManager.kEventUserOnPrefix + controller)
        }
    }
    
    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        loaderMsgsSwapTimer?.invalidate()
        loaderMsgsSwapTimer = nil
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if !controller.isEmpty {
            TrackingManager.shared.track(TrackingManager.kEventUserOnPrefix + controller)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: New NavBar configuration methods
    public func shouldHideNavBar() -> Bool {
        return true //Override to change behavior
    }
    
    public func setupNavBarWithCancel(returningToRoot: Bool = false) {
        let rightButton = UIBarButtonItem(title: "cancel".localized,
                                          style: .plain,
                                          target: self,
                                          action: nil)
        rightButton.action = returningToRoot ? #selector(cancelFlow) : #selector(goBack)
        
        rightButton.setTitleTextAttributes(
            [.foregroundColor: StyleHelper.colors.secondaryText,
             .font: StyleHelper.font(sized: .medium)],
            for: .normal)
        self.navigationItem.rightBarButtonItem = rightButton
        let backButton = UIBarButtonItem(title: "", style: .plain, target: navigationController, action: nil)
        self.navigationItem.leftBarButtonItem = backButton
    }
    
    public func setupNavBarWithBack(andTitle title: String = "", tint: UIColor,
                                    titleColor: UIColor? = StyleHelper.colors.screenTitle) {
        self.navigationController?.navigationBar.tintColor = tint
        let backImage = UIImage(named: "back-arrow-icon-black")?.withRenderingMode(.alwaysTemplate)
        
        let leftButton = UIBarButtonItem(image: backImage!,
                                          style: .plain,
                                          target: self,
                                          action: #selector(goBack))
        leftButton.imageInsets.top = -2
        self.navigationItem.leftBarButtonItem = leftButton
        
        self.navigationItem.title = title
        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: titleColor as Any,
            .font: StyleHelper.font(sized: .giant)
        ]
    }
    
    public func addRightNavBarItem(title: String, tint: UIColor, onTap: Selector) {
        let goToButton = UIButton()
        goToButton.tintColor = tint
        goToButton.setTitleColor(tint, for: .normal)
        goToButton.titleLabel?.font = StyleHelper.font(sized: .medium)
        goToButton.setTitle(title, for: .normal)
        goToButton.addTarget(self, action: onTap, for: .touchUpInside)
        goToButton.sizeToFit()
        
        let goToImage = UIImageView(image: UIImage(named: "forward-arrow-icon-white")?.withRenderingMode(.alwaysTemplate))
        goToImage.contentMode = .scaleAspectFit
        goToImage.tintColor = tint
        goToImage.frame = CGRect(
            x: goToButton.frame.width,
            y: 8,
            width: goToButton.frame.height,
            height: goToButton.frame.height - 16
        )
        
        let goToView = UIView(frame: CGRect(origin: .zero, size: CGSize(
            width: goToButton.frame.width + goToImage.frame.width,
            height: goToButton.frame.height
        )))
        goToView.backgroundColor = .clear
        goToView.addSubview(goToButton)
        goToView.addSubview(goToImage)
        
        let rightButton = UIBarButtonItem(customView: goToView)
        navigationItem.rightBarButtonItem = rightButton
    }

    func addLeftNavBarItem(title: String, tint: UIColor) {
        let titleLabel = UILabel()
        titleLabel.textColor = tint
        titleLabel.font = StyleHelper.font(sized: .giant)
        titleLabel.text = title
        titleLabel.sizeToFit()
        
        let leftButton = UIBarButtonItem(customView: titleLabel)
        navigationItem.leftBarButtonItem = leftButton
    }
    
    public func setupNavBar(with title: String) {
        if let navController = self.navigationController {
            navController.navigationBar.tintColor = UIColor.white
            navController.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: StyleHelper.font(sized: .giant)]
        }
        
        self.navigationItem.title = title
    }
    
    // MARK: NavBar Configuration
    fileprivate func setNavBarTransparent() {
        if let navController = navigationController {
            navController.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
            navController.navigationBar.backgroundColor = .clear
            navController.navigationBar.shadowImage = UIImage()
            navController.navigationBar.isTranslucent = true
        }
    }
    
    // MARK: Loading spinner
    
    public func showLoadingSpinner(_ message: String, actionButton: UIButton? = nil) {
        loaderMsgsSwapTimer?.invalidate()
        loaderMsgsSwapTimer = nil
        
        guard actionButton != nil else {
            _ = SwiftSpinner.show(message)
            return
        }
        
        _ = SwiftSpinner.show(message)
        spinnerButton = actionButton
        UIApplication.shared.keyWindow?.addSubview(actionButton!)
    }
    
    public func hideLoadingSpinner() {
        loaderMsgsSwapTimer?.invalidate()
        loaderMsgsSwapTimer = nil
        
        SwiftSpinner.hide()
        guard spinnerButton == nil else {
            spinnerButton!.removeFromSuperview()
            return
        }
    }
    
    // MARK: - Actions
    
    @IBAction public func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction public func goToRoot() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction public func cancelFlow() {
        showPopup(
            title: "cancel".localized,
            description: "are_you_sure_you_want_to_cancel_q".localized,
            acceptButtonText: "yes".localized,
            acceptButtonAction: {
                self.navigationController?.popToRootViewController(animated: true)
            },
            cancelButtonText: "no".localized
        )
    }
    
    // MARK: - Demo indicator
    fileprivate func checkIfDemoLabelNeeded() {
        if FloApiRequest.demoModeEnabled() {
            if UIApplication.shared.keyWindow?.viewWithTag(3366) == nil {
                let demoLabel = UILabel(frame: CGRect(origin: CGPoint(x: 4, y: 0), size: .zero))
                demoLabel.font = StyleHelper.font(sized: .tiny)
                demoLabel.textColor = .white
                demoLabel.text = "DEMO"
                demoLabel.sizeToFit()
                let rect = UIApplication.shared.keyWindow?.frame ?? .zero
                let demoView = UIView(frame: CGRect(
                    x: (rect.width / 2) - (demoLabel.frame.width / 2),
                    y: (UIApplication.shared.keyWindow?.layoutMargins.top ?? 8) - 8,
                    width: demoLabel.frame.width + 8,
                    height: demoLabel.frame.height
                ))
                demoView.addSubview(demoLabel)
                demoView.backgroundColor = StyleHelper.colors.red
                demoView.layer.cornerRadius = demoView.frame.height / 2
                demoView.clipsToBounds = true
                demoView.tag = 3366
                UIApplication.shared.keyWindow?.addSubview(demoView)
                demoView.layer.zPosition = 3366
            }
        } else if let demoView = UIApplication.shared.keyWindow?.viewWithTag(3366) {
            demoView.removeFromSuperview()
        }
    }
    
    // MARK: - Web view
    
    public func showWebView(url: String, title: String?) {
        guard let webViewController = UIStoryboard(name: "Common", bundle: nil).instantiateViewController(withIdentifier: WebViewViewController.storyboardId) as? WebViewViewController else {
            return
        }
        
        webViewController.urlString = url
        webViewController.headerTitle = title
        
        navigationController?.pushViewController(webViewController, animated: true)
    }
    
    @objc public func showFeatureNotImplementedAlert() {
        showPopup(title: "flo_error".localized, description: "feature_not_implemented_yet".localized, options:
            [AlertPopupOption(title: "ok".localized)])
    }
    
    public func showFeatureNotSupportedInDemoModeAlert() {
        showPopup(title: "flo_error".localized + " 002", description: "feature_not_supported_in_demo_mode".localized)
    }
    
    // MARK: UITextFieldDelegate implementation to foce overrides due to iOS Core issue.
    
    public func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.cleanError()
        return
    }
    
    public func textFieldDidEndEditing(_ textField: UITextField) {
        return
    }
    
    public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
    
    //Trim whitespaces on every textfield on the flow
    public func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        return true
    }
    
    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    public func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return true
    }
}
