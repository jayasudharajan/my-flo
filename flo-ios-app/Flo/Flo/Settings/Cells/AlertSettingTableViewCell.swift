//
//  AlertSettingTableViewCell.swift
//  Flo
//
//  Created by Josefina Perez on 31/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal enum AlertSettingsType {
    case email, sms, push, call
    
    var image: UIImage {
        switch self {
        case .email:
            return UIImage(named: "email-enabled-icon") ?? UIImage()
        case .sms:
            return UIImage(named: "sms-enabled-icon") ?? UIImage()
        case .push:
            return UIImage(named: "push-enabled-icon") ?? UIImage()
        case .call:
            return UIImage(named: "call-enabled-icon") ?? UIImage()
        }
    }
    
    var size: (width: Int, height: Int) {
        switch self {
        case .email, .sms:
            return (width: 16, height: 13)
        case .push:
            return (width: 14, height: 16)
        case .call:
            return (width: 14, height: 14)
        }
    }
}
    
internal class AlertSettingTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var lblName: UILabel!
    @IBOutlet fileprivate weak var settingsView: UIView!

    public func configure(alert: AlertModel, settings: AlertSettings?) {
        
        for subview in settingsView.subviews {
            subview.removeFromSuperview()
        }
        
        lblName.text = alert.name
        
        let smsEnabled = settings?.smsEnabled ?? true
        let emailEnabled = settings?.emailEnabled ?? true
        let pushEnabled = settings?.pushEnabled ?? true
        let callEnabled = settings?.callEnabled ?? true
        
        var settingsX = Int(settingsView.frame.width) - 16
        
        if callEnabled && alert.severity == .critical {
            addSettingsImage(settingType: .call, imageX: settingsX)
            settingsX-=(AlertSettingsType.call.size.width + 12)
        }
        
        if pushEnabled {
            addSettingsImage(settingType: .push, imageX: settingsX)
            settingsX-=(AlertSettingsType.push.size.width + 12)
        }
        
        if smsEnabled {
            addSettingsImage(settingType: .sms, imageX: settingsX)
            settingsX-=(AlertSettingsType.sms.size.width + 12)
        }
        
        if emailEnabled {
            addSettingsImage(settingType: .email, imageX: settingsX)
            settingsX-=(AlertSettingsType.email.size.width + 12)
        }
    }
    
    fileprivate func addSettingsImage(settingType: AlertSettingsType, imageX: Int) {
        let settingsImage = UIImageView(frame: CGRect(x: imageX, y: 0, width: settingType.size.width,
                                                      height: settingType.size.height))
        settingsImage.image = settingType.image
        settingsView.addSubview(settingsImage)
    }
}
