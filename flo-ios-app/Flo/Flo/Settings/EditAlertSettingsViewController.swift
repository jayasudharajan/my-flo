//
//  EditAlertSettingsViewController.swift
//  Flo
//
//  Created by Josefina Perez on 05/08/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import SwiftyJSON

internal class EditAlertSettingsViewController: FloBaseViewController {
    
    @IBOutlet fileprivate weak var emailSwitch: UISwitch!
    @IBOutlet fileprivate weak var smsSwitch: UISwitch!
    @IBOutlet fileprivate weak var pushSwitch: UISwitch!
    @IBOutlet fileprivate weak var callSwitch: UISwitch!
    @IBOutlet fileprivate weak var lblPhoneCallHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var lblPhoneCallBottom: NSLayoutConstraint!
    @IBOutlet fileprivate weak var shutoffAlertsViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var emailShutoffSwitch: UISwitch!
    @IBOutlet fileprivate weak var smsShutoffSwitch: UISwitch!
    @IBOutlet fileprivate weak var pushShutoffSwitch: UISwitch!
    
    public var alerts: [AlertModel]!
    public var settings: [AlertSettings]!
    public var deviceId: String!
    
    fileprivate var changesMade: Bool = false
    
    fileprivate var triggerSettings: [AlertSettings]?
    
    fileprivate var selectedSystemMode: SystemMode {
        return settings?.first?.systemMode ?? .home
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureWithAlert()
        configureWithSettings()
    }
    
    fileprivate func configureWithAlert() {
        let title =  alerts.count > 1 ? "\("editing_all".localized) \(alerts.first?.severity.name ?? "")" :
        "\("editing".localized) \(alerts.first?.name ?? "")"
        setupNavBarWithBack(andTitle: title, tint: StyleHelper.colors.white, titleColor: StyleHelper.colors.white)
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        if alerts.first?.severity != .critical {
            lblPhoneCallHeight.constant = 0
            lblPhoneCallBottom.constant = 0
            callSwitch.isHidden = true
        } else {
            var triggers: [AlertModel] = []
            for alert in alerts {
                
                guard alert.triggersAlert != 0, let trigger = AlertsManager.shared.getAlertLocally(alert.triggersAlert), trigger.isShutoff else {
                    return
                }
                
                triggers.append(trigger)
            }
            
            if triggers.count != 0 { configureShutoffView(trigger: triggers) }
        }
    }
    
    fileprivate func configureWithSettings() {
        if settings.count == 1 {
            emailSwitch.isOn = settings.first?.emailEnabled ?? true
            smsSwitch.isOn = settings.first?.smsEnabled ?? true
            pushSwitch.isOn = settings.first?.pushEnabled ?? true
            callSwitch.isOn = settings.first?.callEnabled ?? true
        } else if settings.count > 1 {
            emailSwitch.isOn = false
            smsSwitch.isOn = false
            pushSwitch.isOn = false
            callSwitch.isOn = false
            
            for s in settings {
                if s.emailEnabled { emailSwitch.isOn = true }
                if s.smsEnabled { smsSwitch.isOn = true }
                if s.pushEnabled { pushSwitch.isOn = true }
                if s.callEnabled { callSwitch.isOn = true }
            }
        }
    }
    
    fileprivate func configureShutoffView(trigger: [AlertModel]) {
        shutoffAlertsViewHeight.constant = 200
        for alert in trigger {
            triggerSettings = triggerSettings == nil ? [] : triggerSettings
            triggerSettings?.append(AlertsManager.shared.getSettingsForAlert(id: alert.id, systemMode: selectedSystemMode))
        }
        
        emailShutoffSwitch.isOn = false
        smsShutoffSwitch.isOn = false
        pushShutoffSwitch.isOn = false
        
        for s in triggerSettings ?? [] {
            if s.emailEnabled { emailShutoffSwitch.isOn = true }
            if s.smsEnabled { smsShutoffSwitch.isOn = true }
            if s.pushEnabled { pushShutoffSwitch.isOn = true }
        }
    }
    
    fileprivate func updateSettings() {
        guard let userId = UserSessionManager.shared.user?.id, var settings = self.settings else {
            return
        }
        
        if triggerSettings != nil {
            settings.append(contentsOf: triggerSettings!)
        }
        
        var settingsData: [[String: Any]] = []
        for set in settings {
            var data: [String: Any] = [:]
            data["alarmId"] = Int(set.alertId) as AnyObject
            data["systemMode"] = set.systemMode.rawValue as AnyObject
            data["smsEnabled"] = set.smsEnabled as AnyObject
            data["emailEnabled"] = set.emailEnabled as AnyObject
            data["pushEnabled"] = set.pushEnabled as AnyObject
            data["callEnabled"] = set.callEnabled as AnyObject
            
            settingsData.append(data)
        }
        
        let data: [String: AnyObject] = [
            "items": [
                ["deviceId": self.deviceId as AnyObject, "settings": settingsData as AnyObject] as AnyObject
            ] as AnyObject
        ]
        
        showLoadingSpinner("loading".localized)
        FloApiRequest(
            controller: "v2/users/\(userId)/alarmSettings",
            method: .post,
            queryString: nil,
            data: data,
            done: { (error, _) in
                self.hideLoadingSpinner()
                if let e = error {
                    LoggerHelper.log("Error on: POST v2/users/id:/alarmSettings " + e.message, level: .error)
                    self.showPopup(error: e)
                    super.goBack()
                } else {
                    super.goBack()
                }
            }
        ).secureFloRequest()
    }
    
    // MARK: - Actions
    @IBAction fileprivate func valueChanged() {
        changesMade = true
        for set in settings {
            set.smsEnabled = smsSwitch.isOn
            set.emailEnabled = emailSwitch.isOn
            set.pushEnabled = pushSwitch.isOn
            set.callEnabled = callSwitch.isOn
        }
        
        if let triggerSettings = triggerSettings {
            for s in triggerSettings {
                s.smsEnabled = smsShutoffSwitch.isOn
                s.emailEnabled = emailShutoffSwitch.isOn
                s.pushEnabled = pushShutoffSwitch.isOn
            }
        }
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    override func goBack() {
        changesMade ? updateSettings() : super.goBack()
    }
}
