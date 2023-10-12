//
//  NotificationSettingsViewController.swift
//  Flo
//
//  Created by Josefina Perez on 30/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import EasyTipView

internal class AlertsSettingsViewController: FloBaseViewController, UITableViewDelegate, UITableViewDataSource, FloSelectorProtocol {
    
    @IBOutlet fileprivate weak var healthTestDripSensitivityView: UIView!
    @IBOutlet fileprivate weak var anyDripView: UIView!
    @IBOutlet fileprivate weak var smallDripsView: UIView!
    @IBOutlet fileprivate weak var biggerDripsView: UIView!
    @IBOutlet fileprivate weak var biggestDripsView: UIView!
    @IBOutlet fileprivate weak var selectorView: FloSelector!
    @IBOutlet fileprivate weak var criticalAlertsTable: UITableView!
    @IBOutlet fileprivate weak var criticalAlertsTableHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var warningAlertsTable: UITableView!
    @IBOutlet fileprivate weak var warningAlertsTableHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var infoAlertsTable: UITableView!
    @IBOutlet fileprivate weak var infoAlertsTableHeight: NSLayoutConstraint!
    
    public var device: DeviceModel!
    
    fileprivate var sensitivityTooltip: EasyTipView?
    fileprivate var sensitivityTooltipPreferences: EasyTipView.Preferences?
    
    fileprivate var criticalAlerts: [AlertModel] = []
    fileprivate var warningAlerts: [AlertModel] = []
    fileprivate var infoAlerts: [AlertModel] = []
    fileprivate var settings: [AlertSettings] = []
    
    fileprivate var selectedSystemMode: SystemMode = .home
    
    fileprivate let kAlertSettingCellHeight: CGFloat = 40
    fileprivate let kHeaderViewHeight: CGFloat = 50

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithBack(andTitle: "alerts_settings".localized, tint: StyleHelper.colors.white,
                            titleColor: StyleHelper.colors.white)
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        selectorView.setOptions(["away".localized, "home".localized])
        selectorView.delegate = self
        selectorView.isEnabled = true
        
        selectedSystemMode = LocationsManager.shared.selectedLocation?.systemMode == .away ? .away : .home
        selectorView.selectOptionWithoutTriggers(selectedSystemMode == .away ? 0 : 1)
        
        sensitivityTooltipPreferences = EasyTipView.Preferences()
        sensitivityTooltipPreferences?.drawing.foregroundColor = StyleHelper.colors.white
        sensitivityTooltipPreferences?.drawing.backgroundColor = StyleHelper.colors.cyan
        sensitivityTooltipPreferences?.animating.dismissDuration = 0.001
        sensitivityTooltipPreferences?.animating.dismissOnTap = false
        sensitivityTooltipPreferences?.drawing.arrowPosition = .top
        sensitivityTooltipPreferences?.drawing.textAlignment = .center
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getAlerts()
        getAlertsSettings()
    }
    
    fileprivate func getAlerts() {
        criticalAlerts = []
        warningAlerts = []
        infoAlerts = []
        
        showLoadingSpinner("loading".localized)
        AlertsManager.shared.getAlerts(whenFinished: { (error, alerts) in
            if let e = error {
                self.hideLoadingSpinner()
                LoggerHelper.log(e.message, level: .error)
                self.showPopup(error: e)
            } else {
                for alert in alerts where !alert.isInternal && !alert.isShutoff && alert.isActive && alert.isConfigurable && !alert.hasParent && !(alert.isFloSenseAlarm && !self.device.isFloSenseActive) {
                    switch alert.severity {
                    case .critical:
                        self.criticalAlerts.append(alert)
                    case .warning:
                        self.warningAlerts.append(alert)
                    case .info:
                        self.infoAlerts.append(alert)
                    }
                }
                self.updateAlertsTables()
            }
        })
    }
    
    fileprivate func getAlertsSettings() {
        showLoadingSpinner("loading".localized)
        AlertsManager.shared.getAlertsSettings(deviceId: device.id, whenFinished: {(error, settings, dripSensitivity) in
            self.hideLoadingSpinner()
            if let e = error {
                LoggerHelper.log(e.message, level: .error)
                self.showPopup(error: e)
            } else {
                if let settings = settings {
                    self.settings = settings
                    self.updateAlertsTables()
                    self.configureSensitivitySelector(sensitivity: dripSensitivity)
                }
            }
        })
    }
    
    fileprivate func updateAlertsTables() {
        criticalAlertsTable.reloadData()
        criticalAlertsTableHeight.constant = kHeaderViewHeight +
            CGFloat(criticalAlerts.count) * kAlertSettingCellHeight + 10
        
        warningAlertsTable.reloadData()
        warningAlertsTableHeight.constant = kHeaderViewHeight +
            CGFloat(warningAlerts.count) * kAlertSettingCellHeight + 10

        infoAlertsTable.reloadData()
        infoAlertsTableHeight.constant = kHeaderViewHeight +
            CGFloat(infoAlerts.count) * kAlertSettingCellHeight + 10
    }
    
    fileprivate func configureSensitivitySelector(sensitivity: HealthTestDripSensitivity) {
        anyDripView.removeRoundCorners()
        smallDripsView.removeRoundCorners()
        biggerDripsView.removeRoundCorners()
        biggestDripsView.removeRoundCorners()
        biggestDripsView.roundCorners([.topLeft, .bottomLeft], radius: 5)
        
        switch sensitivity {
        case .any:
            anyDripView.backgroundColor = StyleHelper.colors.dripBlue
            smallDripsView.backgroundColor = StyleHelper.colors.dripBlue
            biggerDripsView.backgroundColor = StyleHelper.colors.dripBlue
            biggestDripsView.backgroundColor = StyleHelper.colors.dripBlue
            anyDripView.roundCorners([.topRight, .bottomRight], radius: 5)
            showTooltip(in: anyDripView, text: "any_drip".localized, dropsPerMin: "1")
        case .small:
            anyDripView.backgroundColor = StyleHelper.colors.white
            smallDripsView.backgroundColor = StyleHelper.colors.dripBlue
            biggerDripsView.backgroundColor = StyleHelper.colors.dripBlue
            biggestDripsView.backgroundColor = StyleHelper.colors.dripBlue
            smallDripsView.roundCorners([.topRight, .bottomRight], radius: 5)
            showTooltip(in: smallDripsView, text: "small_drips".localized, dropsPerMin: "2")
        case .bigger:
            anyDripView.backgroundColor = StyleHelper.colors.white
            smallDripsView.backgroundColor = StyleHelper.colors.white
            biggerDripsView.backgroundColor = StyleHelper.colors.dripBlue
            biggestDripsView.backgroundColor = StyleHelper.colors.dripBlue
            biggerDripsView.roundCorners([.topRight, .bottomRight], radius: 5)
            showTooltip(in: biggerDripsView, text: "bigger_drips".localized, dropsPerMin: "3")
        case .biggest:
            anyDripView.backgroundColor = StyleHelper.colors.white
            smallDripsView.backgroundColor = StyleHelper.colors.white
            biggerDripsView.backgroundColor = StyleHelper.colors.white  
            biggestDripsView.backgroundColor = StyleHelper.colors.dripBlue
            biggestDripsView.roundCorners([.topLeft, .topRight, .bottomRight, .bottomLeft], radius: 5)
            showTooltip(in: biggestDripsView, text: "biggest_drips".localized, dropsPerMin: "4")
        }
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Table view delegate and data source
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case criticalAlertsTable:
            return criticalAlerts.count
        case warningAlertsTable:
            return warningAlerts.count
        case infoAlertsTable:
            return infoAlerts.count
        default:
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case criticalAlertsTable:
            guard let alertCell = tableView.dequeueReusableCell(withIdentifier: "alertCell") as?
                AlertSettingTableViewCell else {
                return UITableViewCell()
            }
            
            let alert = criticalAlerts[indexPath.row]
            let settings = AlertsManager.shared.getSettingsForAlert(id: alert.id, systemMode: selectedSystemMode)
            alertCell.configure(alert: alert, settings: settings)
            return alertCell
        case warningAlertsTable:
            guard let alertCell = tableView.dequeueReusableCell(withIdentifier: "alertCell") as?
                AlertSettingTableViewCell else {
                    return UITableViewCell()
            }
            
            let alert = warningAlerts[indexPath.row]
            let settings = AlertsManager.shared.getSettingsForAlert(id: alert.id, systemMode: selectedSystemMode)
            alertCell.configure(alert: alert, settings: settings)
            return alertCell
        case infoAlertsTable:
            guard let alertCell = tableView.dequeueReusableCell(withIdentifier: "alertCell") as?
                AlertSettingTableViewCell else {
                    return UITableViewCell()
            }
            
            let alert = infoAlerts[indexPath.row]
            let settings = AlertsManager.shared.getSettingsForAlert(id: alert.id, systemMode: selectedSystemMode)
            alertCell.configure(alert: alert, settings: settings)
            return alertCell
            
        default:
            return UITableViewCell()
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch tableView {
        case criticalAlertsTable:
            guard let headerView = tableView.dequeueReusableCell(withIdentifier: "headerView")
                as? AlertsSettingHeaderTableViewCell else {
                return UITableViewCell()
            }
            
            headerView.configure(severity: .critical)
            return headerView
        case warningAlertsTable:
            guard let headerView = tableView.dequeueReusableCell(withIdentifier: "headerView")
                as? AlertsSettingHeaderTableViewCell else {
                    return UITableViewCell()
            }
            
            headerView.configure(severity: .warning)
            return headerView
        case infoAlertsTable:
            guard let headerView = tableView.dequeueReusableCell(withIdentifier: "headerView")
                as? AlertsSettingHeaderTableViewCell else {
                    return UITableViewCell()
            }
            
            headerView.configure(severity: .info)
            return headerView
        default:
            return UIView()
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kAlertSettingCellHeight
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return kHeaderViewHeight
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var alert: AlertModel?
        var settings: AlertSettings?
        
        switch tableView {
        case criticalAlertsTable:
            alert = criticalAlerts[indexPath.row]
        case warningAlertsTable:
            alert = warningAlerts[indexPath.row]
        case infoAlertsTable:
            alert = infoAlerts[indexPath.row]
        default:
            break
        }
        
        if let alert = alert { settings = AlertsManager.shared.getSettingsForAlert(id: alert.id,
                                                                                           systemMode: selectedSystemMode)}
        guard alert != nil,
            let editController = storyboard?.instantiateViewController(withIdentifier: "EditAlertSettingsViewController")
            as? EditAlertSettingsViewController else {
                return
        }
        
        editController.alerts = [alert!]
        editController.deviceId = device.id
        if let alertSettings = settings {
            editController.settings = [alertSettings]
        }
        
        navigationController?.pushViewController(editController, animated: true)
    }
    
    // MARK: - FloSelectorProtocol
    public func valueDidChange(selectedIndex: Int) {
        selectedSystemMode = selectedIndex == 0 ? .away : .home
        updateAlertsTables()
    }
    
    // MARK: - Actions
    @IBAction fileprivate func healthTestDripSensitivity(_ sender: UIButton) {
    
        var sensitivity: HealthTestDripSensitivity = .any
        switch sender.tag {
        case 1000:
            sensitivity = .biggest
            configureSensitivitySelector(sensitivity: .biggest)
        case 1001:
            sensitivity = .bigger
            configureSensitivitySelector(sensitivity: .bigger)
        case 1002:
            sensitivity = .small
            configureSensitivitySelector(sensitivity: .small)
        case 1003:
            sensitivity = .any
            configureSensitivitySelector(sensitivity: .any)
        default:
            break
        }
        
        guard let userId = UserSessionManager.shared.user?.id,
            let intSensitivity = Int(sensitivity.rawValue) else {
            return
        }
        
        let itemsData: [String: AnyObject] = [
            "deviceId": device.id as AnyObject,
            "smallDripSensitivity": intSensitivity as AnyObject,
            "settings": [] as AnyObject
        ]
        let data: [String: AnyObject] = ["items": [itemsData] as AnyObject]
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
                }
        }).secureFloRequest()
    }
    
    @IBAction fileprivate func editAllSettings(_ sender: UIButton) {
        var alerts: [AlertModel]?
        
        switch sender.tag {
        case 1001:
            alerts = criticalAlerts
        case 1002:
            alerts = warningAlerts
        case 1003:
            alerts = infoAlerts
        default:
            break
        }
        
        guard alerts != nil,
            let editController = storyboard?.instantiateViewController(withIdentifier: "EditAlertSettingsViewController")
                as? EditAlertSettingsViewController else {
                    return
        }
        
        var settings: [AlertSettings] = []
        
        for alert in alerts! {
            let alertSettings = AlertsManager.shared.getSettingsForAlert(id: alert.id,
                                                                                  systemMode: selectedSystemMode)
            settings.append(alertSettings)
        }
        
        editController.alerts = alerts
        editController.settings = settings
        editController.deviceId = device.id
        
        navigationController?.pushViewController(editController, animated: true)
    }
    
    // MARK: - Tooltip
    fileprivate func showTooltip(in view: UIView, text: String, dropsPerMin: String) {
        
        self.sensitivityTooltip?.dismiss()
        self.sensitivityTooltipPreferences?.drawing.arrowPosition = .top
    
        self.sensitivityTooltip = EasyTipView(text: text, preferences: sensitivityTooltipPreferences!)
        sensitivityTooltip?.show(animated: false, forView: view, withinSuperview: healthTestDripSensitivityView)
    }
}
