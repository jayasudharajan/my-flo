//
//  BaseAddLocationStepViewController.swift
//  Flo
//
//  Created by Matias Paillet on 6/12/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class BaseAddLocationStepViewController: FloBaseViewController {
    
    @IBOutlet public weak var btnNext: UIButton!
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    override func goBack() {
        self.showPopup(
            title: "cancel".localized,
            description: "are_you_sure_you_want_to_cancel_q".localized,
            options: [
                AlertPopupOption(title: "yes".localized, type: .cancel, action: {
                    self.navigationController?.popToRootViewController(animated: true)
                }),
                AlertPopupOption(title: "no".localized)
            ]
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBarWithCancel()
    }
    
    // MARK: Utils
    
    public func configureNextButton(isEnabled: Bool) {
        btnNext.isEnabled = isEnabled
        btnNext.backgroundColor = isEnabled ? StyleHelper.colors.mainButtonActive : StyleHelper.colors.mainButtonInactive
    }
    
    public func enableNextStep() {
        configureNextButton(isEnabled: true)
    }
    
    public func disableNextStep() {
        configureNextButton(isEnabled: false)
    }
    
    // MARK: Actions
    
    @IBAction public func goPrevious() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: UITextFieldDelegate
    
    override public func textFieldDidEndEditing(_ textField: UITextField) {
        _  = performValidationsOn(textField)
        return
    }
    
    // MARK: To override
    
    public func performValidationsOn( _ textField: UITextField) -> Bool {
        return false //Override in subclasses
    }
    
    public func prefillWithBuilderInfo() {
        //Override in subclasses
    }
}
