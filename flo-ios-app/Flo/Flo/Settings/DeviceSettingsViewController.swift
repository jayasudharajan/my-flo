//
//  DeviceSettingsViewController.swift
//  Flo
//
//  Created by Josefina Perez on 28/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

private enum PlayerAction: String {
    case disabled
    case constant
    case cat1
    case cat2
    case cat3
    case cat4
}

import UIKit
import SwiftRangeSlider

internal class DeviceSettingsViewController: FloBaseViewController {
    
    public var device: DeviceModel?
    fileprivate var dripCatValidator: SingleChoiceValidator?
    fileprivate var playerAction: PlayerAction = .disabled
    fileprivate static let kMinDevMenuFwVersion = "3.9.0"
    fileprivate var irrigationOptions: [IrrigationType] = []
    fileprivate var prvInstallationOptions: [PRVInstallationType] = []
    
    @IBOutlet fileprivate weak var txtNickname: UITextField!
    @IBOutlet fileprivate weak var lblSsid: UILabel!
    @IBOutlet fileprivate weak var installationView: UIView!
    @IBOutlet fileprivate weak var installationViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var prvLabel: UILabel!
    @IBOutlet fileprivate weak var lblSerialNumber: UILabel!
    @IBOutlet fileprivate weak var lblFirmware: UILabel!
    @IBOutlet fileprivate weak var lblDeviceId: UILabel!
    @IBOutlet fileprivate weak var btnUnlinkDevice: UIButton!
    @IBOutlet fileprivate weak var btnRestartDevice: UIButton!
    
    // Developer menu
    @IBOutlet fileprivate weak var developerMenuHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var restartDeviceBtnTop: NSLayoutConstraint!
    
    @IBOutlet fileprivate weak var unlockDeviceSwitch: UISwitch!
    @IBOutlet fileprivate weak var lblDeviceLocked: UILabel!
    
    @IBOutlet fileprivate weak var btnCat1Drip: FloOptionButton!
    @IBOutlet fileprivate weak var btnCat2Drip: FloOptionButton!
    @IBOutlet fileprivate weak var btnCat3Drip: FloOptionButton!
    @IBOutlet fileprivate weak var btnCat4Drip: FloOptionButton!
    
    @IBOutlet fileprivate weak var flowRateSlider: UISlider!
    @IBOutlet fileprivate weak var lblFlowRate: UILabel!
    
    @IBOutlet fileprivate weak var temperatureSlider: UISlider!
    @IBOutlet fileprivate weak var lblTemperature: UILabel!
    
    @IBOutlet fileprivate weak var pressureSlider: UISlider!
    @IBOutlet fileprivate weak var pressureRangeSlider: RangeSlider!
    @IBOutlet fileprivate weak var lblPressureMin: UILabel!
    @IBOutlet fileprivate weak var lblPressureMax: UILabel!
    
    @IBOutlet fileprivate weak var customTelemetryViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var customTelemetrySwitch: UISwitch!
    
    @IBAction fileprivate func showDeveloperMenu() {
        if !FloApiRequest.demoModeEnabled() {
            DeveloperToolsHelper.enable()
            refreshDeveloperMenuUI()
        }
    }
    
    @IBAction fileprivate func unlockDevice() {
        guard let deviceId = device?.id else {
            return
        }
        
        let data: [String: AnyObject] = [
            "target": "sleep" as AnyObject,
            "isLocked": (unlockDeviceSwitch.isOn ? false : true) as AnyObject
        ]
        
        showLoadingSpinner("loading".localized)
        FloApiRequest(
            controller: "v2/devices/\(deviceId)/systemMode",
            method: .post,
            queryString: nil,
            data: data,
            done: { (error, _) in
                self.hideLoadingSpinner()
                if let e = error, e.status != 409 {
                    self.showPopup(error: e)
                    self.unlockDeviceSwitch.isOn = !self.unlockDeviceSwitch.isOn
                } else {
                    self.device?.setIsLocked(!self.unlockDeviceSwitch.isOn)
                    self.lblDeviceLocked.text = self.unlockDeviceSwitch.isOn ? "device_unlocked".localized : "device_locked".localized
                    self.lblDeviceLocked.alpha = self.unlockDeviceSwitch.isOn ? 1 : 0.5
                }
            }
        ).secureFloRequest()
    }
    
    @IBAction fileprivate func customTelemetryAction() {
        playerAction = customTelemetrySwitch.isOn ? .constant : .disabled
        refreshDeveloperMenuUI()
        
        changeTelemetryValues()
    }
    
    @IBAction fileprivate func customTelemetrySliderMoved(_ sender: UIView) {
        if let slider = sender as? UISlider {
            let value = Double(slider.value)
            switch slider {
            case flowRateSlider:
                lblFlowRate.text = "\(String(format: "%.1f", MeasuresHelper.adjust(value, ofType: .flow))) \(MeasuresHelper.unitAbbreviation(for: .flow))"
            case temperatureSlider:
                lblTemperature.text = "\(String(format: "%.1f", MeasuresHelper.adjust(value, ofType: .temperature))) \(MeasuresHelper.unitAbbreviation(for: .temperature))"
            case pressureSlider:
                lblPressureMax.text = "\(String(format: "%.1f", MeasuresHelper.adjust(value, ofType: .pressure))) \(MeasuresHelper.unitAbbreviation(for: .pressure))"
            default:
                break
            }
        } else if let slider = sender as? RangeSlider {
            lblPressureMin.text = "\(String(format: "%.1f", MeasuresHelper.adjust(slider.lowerValue, ofType: .pressure))) \(MeasuresHelper.unitAbbreviation(for: .pressure))"
            lblPressureMax.text = "\(String(format: "%.1f", MeasuresHelper.adjust(slider.upperValue, ofType: .pressure))) \(MeasuresHelper.unitAbbreviation(for: .pressure))"
        }
    }
    
    @IBAction fileprivate func customTelemetrySliderReleased(_ sender: UIView) {
        changeTelemetryValues()
    }
    
    @IBAction fileprivate func dripCategoryAction(_ sender: FloOptionButton) {
        if let selectedOption = dripCatValidator?.getSelectedOption() {
            if selectedOption == sender {
                dripCatValidator?.unselectOption(sender)
                pressureSlider.value = Float(pressureRangeSlider.upperValue)
            } else {
                dripCatValidator?.selectOption(sender)
            }
        } else {
            dripCatValidator?.selectOption(sender)
            pressureRangeSlider.upperValue = Double(pressureSlider.value)
        }
        
        lblPressureMin.isHidden = false
        pressureRangeSlider.isHidden = false
        pressureSlider.isHidden = true
        switch dripCatValidator?.getSelectedOption() {
        case btnCat1Drip:
            playerAction = .cat1
        case btnCat2Drip:
            playerAction = .cat2
        case btnCat3Drip:
            playerAction = .cat3
        case btnCat4Drip:
            playerAction = .cat4
        default:
            playerAction = .constant
            
            lblPressureMin.isHidden = true
            pressureRangeSlider.isHidden = true
            pressureSlider.isHidden = false
        }
        
        changeTelemetryValues()
    }
    
    @IBAction fileprivate func restartDevice() {
        showPopup(
            title: "restart_device_q".localized,
            description: "restart_device_description".localized,
            options: [
                .init(title: "restart_device".localized, type: .normal, action: {
                    if !FloApiRequest.demoModeEnabled() {
                        if let deviceId = self.device?.id {
                            self.showLoadingSpinner("please_wait".localized())
                            DevicesHelper.restart(id: deviceId, { (error, success) in
                                self.hideLoadingSpinner()
                                if success {
                                    //Do nothing so far, but might change in the short term
                                } else {
                                    if let e = error {
                                        self.showPopup(error: e)
                                    }
                                }
                            })
                        }
                    } else {
                        self.showFeatureNotSupportedInDemoModeAlert()
                    }
                }),
                .init(title: "cancel".localized, type: .cancel, action: nil)
            ]
        )
    }
    
    @IBAction fileprivate func unlinkDevice() {
        showPopup(
            title: "unlink_device_q".localized,
            description: "unlink_device_description".localized,
            options: [
                .init(title: "unlink_device".localized, type: .normal, action: {
                    if !FloApiRequest.demoModeEnabled() {
                        if let deviceId = self.device?.id {
                            DevicesHelper.delete(id: deviceId, {(err, success) in
                                if success {
                                    self.device?.isInstalledAndConfigured = false
                                    self.navigationController?.popToRootViewController(animated: true)
                                } else {
                                    if let e = err {
                                        self.showPopup(error: e)
                                    }
                                }
                            })
                        }
                    } else {
                        self.showFeatureNotSupportedInDemoModeAlert()
                    }
                }),
                .init(title: "cancel".localized, type: .cancel, action: nil)
            ]
        )
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithBack(andTitle: "device_settings".localized, tint: StyleHelper.colors.white, titleColor: StyleHelper.colors.white)
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        btnUnlinkDevice.backgroundColor = StyleHelper.colors.whiteWithTransparency01
        btnUnlinkDevice.layer.borderColor = StyleHelper.colors.whiteWithTransparency015.cgColor
        
        btnRestartDevice.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.1)
        btnRestartDevice.layer.borderColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.15).cgColor
        
        btnCat1Drip.backgroundColor = StyleHelper.colors.lightBlue
        btnCat1Drip.setTitleColor(StyleHelper.colors.darkBlue, for: .normal)
        btnCat2Drip.backgroundColor = StyleHelper.colors.lightBlue
        btnCat2Drip.setTitleColor(StyleHelper.colors.darkBlue, for: .normal)
        btnCat3Drip.backgroundColor = StyleHelper.colors.lightBlue
        btnCat3Drip.setTitleColor(StyleHelper.colors.darkBlue, for: .normal)
        btnCat4Drip.backgroundColor = StyleHelper.colors.lightBlue
        btnCat4Drip.setTitleColor(StyleHelper.colors.darkBlue, for: .normal)
        
        dripCatValidator = SingleChoiceValidator(objectsToValidate: [btnCat1Drip, btnCat2Drip, btnCat3Drip, btnCat4Drip])
        
        fillWithDeviceInformation()
    }
    
    // MARK: - View setup/refresh
    fileprivate func fillWithDeviceInformation() {
        guard let device = device else {
            return
        }
        
        txtNickname.text = !device.nickname.isEmpty ? device.nickname :
        (!device.type.isEmpty ? device.type : "not_available".localized)
        lblSsid.text = device.wiFiSsid.isEmpty ? "wifi".localized : device.wiFiSsid
        
        if device.systemModeLocked {
            lblDeviceLocked.text = "device_locked".localized
            lblDeviceLocked.alpha = 0.5
            unlockDeviceSwitch.isOn = false
        } else {
            lblDeviceLocked.text = "device_unlocked".localized
            lblDeviceLocked.alpha = 1
            unlockDeviceSwitch.isOn = true
        }
        
        if device.isInstalled {
            installationViewHeight.constant = 151
            installationView.isHidden = false
        } else {
            installationViewHeight.constant = 0
        }
        installationView.layoutIfNeeded()
        view.layoutIfNeeded()
        
        lblSerialNumber.text = device.serialNumber.isEmpty ? "not_available".localized : device.serialNumber
        lblDeviceId.text = device.macAddress.isEmpty ? "not_available".localized : device.macAddress
        lblFirmware.text = device.fwVersion.isEmpty ? "not_available".localized : device.fwVersion
        
        guard
            let playerActionKey = device.fwProperties["player_action"] as? String,
            let flow = device.fwProperties["player_flow"] as? Double,
            let temperature = device.fwProperties["player_temperature"] as? Double,
            var minPressure = device.fwProperties["player_min_pressure"] as? Double,
            var maxPressure = device.fwProperties["player_pressure"] as? Double
        else { return }
        
        playerAction = PlayerAction(rawValue: playerActionKey) ?? .disabled
        
        lblPressureMin.isHidden = false
        pressureRangeSlider.isHidden = false
        pressureSlider.isHidden = true
        switch playerAction {
        case .cat1:
            dripCatValidator?.selectOption(btnCat1Drip)
        case .cat2:
            dripCatValidator?.selectOption(btnCat2Drip)
        case .cat3:
            dripCatValidator?.selectOption(btnCat3Drip)
        case .cat4:
            dripCatValidator?.selectOption(btnCat4Drip)
        default:
            lblPressureMin.isHidden = true
            pressureRangeSlider.isHidden = true
            pressureSlider.isHidden = false
        }
        
        flowRateSlider.minimumValue = Float(MeasuresHelper.adjust(0, ofType: .flow))
        flowRateSlider.maximumValue = Float(MeasuresHelper.adjust(25, ofType: .flow))
        flowRateSlider.value = Float(MeasuresHelper.adjust(flow, ofType: .flow))
        lblFlowRate.text = "\(String(format: "%.1f", MeasuresHelper.adjust(flow, ofType: .flow))) \(MeasuresHelper.unitAbbreviation(for: .flow))"
        
        temperatureSlider.minimumValue = Float(MeasuresHelper.adjust(0, ofType: .temperature))
        temperatureSlider.maximumValue = Float(MeasuresHelper.adjust(100, ofType: .temperature))
        temperatureSlider.value = Float(MeasuresHelper.adjust(temperature, ofType: .temperature))
        lblTemperature.text = "\(String(format: "%.1f", MeasuresHelper.adjust(temperature, ofType: .temperature))) \(MeasuresHelper.unitAbbreviation(for: .temperature))"
        
        let minRangePressure = MeasuresHelper.adjust(0, ofType: .pressure)
        let maxRangePressure = MeasuresHelper.adjust(160, ofType: .pressure)
        minPressure = MeasuresHelper.adjust(minPressure, ofType: .pressure)
        maxPressure = MeasuresHelper.adjust(maxPressure, ofType: .pressure)
        
        pressureSlider.minimumValue = Float(minRangePressure)
        pressureSlider.maximumValue = Float(maxRangePressure)
        pressureSlider.value = Float(maxPressure)
        
        pressureRangeSlider.minimumValue = minRangePressure
        pressureRangeSlider.maximumValue = maxRangePressure
        pressureRangeSlider.lowerValue = minPressure
        pressureRangeSlider.upperValue = maxPressure
        
        lblPressureMin.text = "\(String(format: "%.1f", minPressure)) \(MeasuresHelper.unitAbbreviation(for: .pressure))"
        lblPressureMax.text = "\(String(format: "%.1f", maxPressure)) \(MeasuresHelper.unitAbbreviation(for: .pressure))"
        
        refreshDeveloperMenuUI()
    }
    
    // MARK: - Nickname texfield methods
    fileprivate func updateNickname(_ sender: UITextField) {
        if !FloApiRequest.demoModeEnabled() {
            let nickname = txtNickname.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let deviceId = device?.id ?? ""
            
            if nickname.isEmpty {
                txtNickname.displayError("nickname_not_empty".localized)
            } else if !nickname.isShorterThan(257) {
                txtNickname.displayError("nickname_too_long".localized)
            } else if let location = LocationsManager.shared.getOneByDeviceLocally(deviceId),
                !location.devices.filter({ (device) -> Bool in
                    return device.nickname.lowercased() == nickname.lowercased() && device.id != deviceId
                }).isEmpty {
                txtNickname.displayError("nickname_already_in_use".localized)
            } else {
                showLoadingSpinner("please_wait".localized)
                
                FloApiRequest(
                    controller: "v2/devices/\(deviceId)",
                    method: .post,
                    queryString: nil,
                    data: ["nickname": nickname as AnyObject],
                    done: { (error, _) in
                        self.hideLoadingSpinner()
                        if let e = error {
                            self.showPopup(error: e)
                        } else {
                            self.device?.setNickname(nickname)
                            sender.resignFirstResponder()
                        }
                    }
                ).secureFloRequest()
            }
        } else {
            showFeatureNotSupportedInDemoModeAlert()
        }
    }
    
    fileprivate func performValidationsOn(_ textField: UITextField) {
        textField.cleanError()
        
        switch textField {
        case txtNickname:
            guard
                !(self.txtNickname.text?.isEmpty() ?? true),
                (txtNickname.text?.isShorterThan(257) ?? true)
            else {
                txtNickname.displayError("nickname_not_empty".localized)
                break
            }
            updateNickname(txtNickname)
        default:
            break
        }
    }
    
    // MARK: - Developer menu methods
    fileprivate func refreshDeveloperMenuUI() {
        //Only show menu if fwVersion >= "3.9.0" and if it's enabled
        if DeveloperToolsHelper.isEnabled
            && device != nil
            && !(DeviceSettingsViewController.kMinDevMenuFwVersion.compare(device!.fwVersion, options: .numeric) == .orderedDescending) {
            restartDeviceBtnTop.constant = 23
            developerMenuHeight.constant = playerAction != .disabled ? 485 : 143
            customTelemetryViewHeight.constant = playerAction != .disabled ? 390 : 48
            customTelemetrySwitch.isOn = playerAction != .disabled
        } else {
            restartDeviceBtnTop.constant = 3
            developerMenuHeight.constant = 0
        }
    }
    
    fileprivate func changeTelemetryValues() {
        if let deviceId = device?.id {
            var data = ["player_action": playerAction.rawValue as AnyObject]
            if playerAction != .disabled {
                data["player_flow"] = MeasuresHelper.adjust(Double(flowRateSlider.value), ofType: .flow, from: MeasuresHelper.getMeasureSystem(), to: .imperial) as AnyObject
                data["player_temperature"] = MeasuresHelper.adjust(Double(temperatureSlider.value), ofType: .temperature, from: MeasuresHelper.getMeasureSystem(), to: .imperial) as AnyObject
                if playerAction == .constant {
                    data["player_pressure"] = MeasuresHelper.adjust(Double(pressureSlider.value), ofType: .pressure, from: MeasuresHelper.getMeasureSystem(), to: .imperial) as AnyObject
                } else {
                    data["player_min_pressure"] = MeasuresHelper.adjust(pressureRangeSlider.lowerValue, ofType: .pressure, from: MeasuresHelper.getMeasureSystem(), to: .imperial) as AnyObject
                    data["player_pressure"] = MeasuresHelper.adjust(pressureRangeSlider.upperValue, ofType: .pressure, from: MeasuresHelper.getMeasureSystem(), to: .imperial) as AnyObject
                }
            }
            
            showLoadingSpinner("loading".localized)
            FloApiRequest(
                controller: "v2/devices/\(deviceId)/fwproperties",
                method: .post,
                queryString: nil,
                data: data,
                done: { (error, _) in
                    self.hideLoadingSpinner()
                    if let e = error {
                        self.showPopup(error: e)
                    }
                }
            ).secureFloRequest()
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
    
    // MARK: - Text field delegate
    override internal func textFieldDidEndEditing(_ textField: UITextField) {
        performValidationsOn(textField)
    }
    
    override internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == "changeWifi" {
            if FloApiRequest.demoModeEnabled() { showFeatureNotSupportedInDemoModeAlert() }
            return !FloApiRequest.demoModeEnabled()
        }
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeWifi" {
            guard
                let device = device,
                let selectedLocationId = UserSessionManager.shared.selectedLocationId,
                let pushToConnectController = segue.destination as? PushToConnectViewController
            else { return }
            
            pushToConnectController.device = DeviceToPair(device: device, locationId: selectedLocationId)
            pushToConnectController.alreadyPairedDeviceId = device.id
        } else if segue.identifier == "alertSettings" {
            guard
                let device = device,
                let alertSettingsController = segue.destination as? AlertsSettingsViewController
            else { return }
            
            alertSettingsController.device = device
        } else if segue.identifier == "showIrrigationSettings" {
            guard
                let device = device,
                let controller = segue.destination as? IrrigationSettingsViewController
            else { return }
            
            controller.device = device
        } else if segue.identifier == "showPRVSettings" {
            guard
                let device = device,
                let controller = segue.destination as? PRVSettingsViewController
            else { return }
            
            controller.device = device
        }
    }
}
