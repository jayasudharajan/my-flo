//
//  Localization+Ext.swift
//  Flo
//
//  Created by Matias Paillet on 5/16/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Localize_Swift

protocol XIBLocalizable {
    var localizationKey: String? { get set }
}

extension String {
    var localized: String {
        return self.localized()
    }
    
    func localized(args: [CVarArg]) -> String {
        return String(format: NSLocalizedString(self, comment: self), arguments: args)
    }
}

extension UILabel: XIBLocalizable {
    @IBInspectable var localizationKey: String? {
        get { return nil }
        set(key) {
            text = key?.localized
        }
    }
}

extension UIButton: XIBLocalizable {
    @IBInspectable var localizationKey: String? {
        get { return nil }
        set(key) {
            setTitle(key?.localized, for: .normal)
        }
    }
}

extension UITextField: XIBLocalizable {
    @IBInspectable var localizationKey: String? {
        get { return nil }
        set(key) {
            placeholder = key?.localized
        }
    }
}
