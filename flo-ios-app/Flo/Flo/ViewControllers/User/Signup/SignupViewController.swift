//
//  SignupViewController.swift
//  Flo
//
//  Created by Matías Paillet on 5/30/19.
//  Copyright © 2017 Flo Technologies. All rights reserved.
//

import UIKit

public protocol SignUpStep {
    func performIsValidCheck(_ andThen:@escaping (_ success: Bool) -> Void)
    func checkValidationsAndUpdateUI()
}

internal class SignupViewController: FloBaseViewController, UIScrollViewDelegate {

    @IBOutlet fileprivate weak var pageControl: UIPageControl!
    @IBOutlet fileprivate weak var scrollView: UIScrollView!
    @IBOutlet fileprivate weak var btnNext: UIButton!
    
    fileprivate var pages: [SignUpStep] = []
    fileprivate static var margins = UIScreen.main.bounds.width * 0.2
    
    public var prefilledEmail: String?
    
    // MARK: Lifecycle
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithCancel()
        
        setupChildControllers()
        
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        scrollView.isScrollEnabled = false
        scrollView.contentSize = CGSize(width: self.view.frame.width * 2, height: scrollView.frame.height)
        
        configureNextButton(isEnabled: false)
        
        SignUpBuilder.shared.start()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        // Workaround for animations on push / pop transitions
        self.scrollView.clipsToBounds = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        // Workaround for animations on push / pop transitions
        self.scrollView.clipsToBounds = true
    }
    
    override func goBack() {
        self.showPopup(
            title: "cancel".localized,
            description: "are_you_sure_you_want_to_cancel_q".localized,
            options: [
                AlertPopupOption(title: "yes".localized, type: .cancel, action: {
                    self.navigationController?.popViewController(animated: true)
                }),
                AlertPopupOption(title: "no".localized)
            ]
        )
    }
    
    fileprivate func configureNextButton(isEnabled: Bool) {
        btnNext.isEnabled = isEnabled
        btnNext.backgroundColor = isEnabled ? StyleHelper.colors.mainButtonActive : StyleHelper.colors.mainButtonInactive
    }
    
    fileprivate func setupChildControllers() {
        
        let storyboard =  UIStoryboard(name: "Registration", bundle: nil)
        if let step1 = storyboard.instantiateViewController(
            withIdentifier: SignupEmailViewController.storyboardId) as? SignupEmailViewController {
            step1.delegate = self
            step1.prefilledEmail = prefilledEmail
            self.addContentController(step1, toView: scrollView)
            self.pages.append(step1)
        }
        
        if let step2 = storyboard.instantiateViewController(
            withIdentifier: SignupPersonalInfoViewController.storyboardId) as? SignupPersonalInfoViewController {
            step2.delegate = self
            self.addContentController(step2, toView: scrollView, insideFrame:
                CGRect(x: view.frame.width,
                       y: 0,
                       width: scrollView.frame.width,
                       height: scrollView.frame.height))
            self.pages.append(step2)
        }
    }
    
    // MARK: Public interface
    
    public func openTermsAndConditions() {
        let storyboard =  UIStoryboard(name: "Registration", bundle: nil)
        if let controller = storyboard.instantiateViewController(
            withIdentifier: SignupTermsViewController.storyboardId) as? SignupTermsViewController {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    public func openVerifyEmailAddress(_ email: String) {
        let storyboard =  UIStoryboard(name: "Registration", bundle: nil)
        if let controller = storyboard.instantiateViewController(
            withIdentifier: SignupVerifyEmailViewController.storyboardId) as? SignupVerifyEmailViewController {
            controller.emailToVerify = email
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    public func enableNextStep() {
        configureNextButton(isEnabled: true)
    }
    
    public func disableNextStep() {
        configureNextButton(isEnabled: false)
    }
    
    // MARK: Actions
    
    @IBAction fileprivate func goToNextPage() {
        self.pages[pageControl.currentPage].performIsValidCheck({ (success) in
            if success {
                if self.pageControl.currentPage < self.pages.count - 1 {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.scrollView.scrollRectToVisible(
                            CGRect(x: self.view.frame.width * CGFloat(self.pageControl.currentPage + 1),
                                   y: 0,
                                   width: self.scrollView.frame.width,
                                   height: self.scrollView.frame.height), animated: true)
                    }, completion: { _ in
                        self.pageControl.currentPage += 1
                        self.pages[self.pageControl.currentPage].checkValidationsAndUpdateUI()
                    })
                } else { //If it was last step, proceed
                    self.registerUser()
                }
                
            } else {
                
            }
        })
        
    }
    
    @IBAction fileprivate func goToPreviousPage() {
        if self.pageControl.currentPage > 0 {
            UIView.animate(withDuration: 0.3, animations: {
                self.scrollView.scrollRectToVisible(
                    CGRect(x: self.view.frame.width * CGFloat(self.pageControl.currentPage - 1),
                           y: 0,
                           width: self.scrollView.frame.width,
                           height: self.scrollView.frame.height), animated: true)
            }, completion: { _ in
                self.pageControl.currentPage -= 1
                self.pages[self.pageControl.currentPage].checkValidationsAndUpdateUI()
            })
        } else {
            self.goBack()
        }
    }
    
    // MARK: Private methods
    
    fileprivate func registerUser() {
        
        self.showLoadingSpinner("Loading")
        
        let result = SignUpBuilder.shared.build()
        if let error = result.error {
            self.showPopup(description: error.localizedDescription)
        } else {
            //            self.selectedLocale = self.countryView.selectedLocale
            
            FloApiRequest(controller: "v2/users/register",
                          method: .post,
                          queryString: nil,
                          data: result.result,
                          done: { (error, _) in
                            self.hideLoadingSpinner()
                            
                            if error != nil {
                                self.showPopup(title: "error_popup_title".localized() + " 011",
                                               description: "unexpected_error_creating_account".localized())
                            } else {
                                let stringEmail = result.result["email"] as? String
                                let email = ( stringEmail ?? "") as CFString
                                let password = ((result.result["password"] as? String) ?? "") as CFString
                                SecAddSharedWebCredential("meetflo.com" as CFString, email, password) { (error) in
                                    if let e = error {
                                        LoggerHelper.log(e.localizedDescription, level: .error)
                                    }
                                }
                                
                                if let anEmail = stringEmail {
                                    self.openVerifyEmailAddress(anEmail)
                                }
                            }
            }).unsecureFloRequest()
        }
    }
    
}
