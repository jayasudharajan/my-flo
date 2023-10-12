//
//  DeviceGaugesCardViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 27/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class DeviceGaugesCardViewController: CardViewController {
    
    fileprivate let kGaugeAnimation = "gaugeAnimation"
    fileprivate let kIndicatorMaxAngle: CGFloat = 234
    
    @IBOutlet fileprivate weak var pressureIndicatorImageView: UIImageView!
    @IBOutlet fileprivate weak var pressureMinLimitLabel: UILabel!
    @IBOutlet fileprivate weak var pressureMaxLimitLabel: UILabel!
    @IBOutlet fileprivate weak var pressureValueLabel: UILabel!
    @IBOutlet fileprivate weak var pressureUnitLabel: UILabel!
    @IBOutlet fileprivate weak var pressureCenterView: UIView!
    @IBOutlet fileprivate weak var flowrateIndicatorImageView: UIImageView!
    @IBOutlet fileprivate weak var flowrateMinLimitLabel: UILabel!
    @IBOutlet fileprivate weak var flowrateMaxLimitLabel: UILabel!
    @IBOutlet fileprivate weak var flowrateValueLabel: UILabel!
    @IBOutlet fileprivate weak var flowrateUnitLabel: UILabel!
    @IBOutlet fileprivate weak var flowrateCenterView: UIView!
    @IBOutlet fileprivate weak var temperatureIndicatorImageView: UIImageView!
    @IBOutlet fileprivate weak var temperatureMinLimitLabel: UILabel!
    @IBOutlet fileprivate weak var temperatureMaxLimitLabel: UILabel!
    @IBOutlet fileprivate weak var temperatureValueLabel: UILabel!
    @IBOutlet fileprivate weak var temperatureUnitLabel: UILabel!
    @IBOutlet fileprivate weak var temperatureCenterView: UIView!
    @IBOutlet fileprivate weak var temperatureLabel: UILabel!

    override var height: CGFloat {
        return 166
    }
    fileprivate var device: DeviceModel!
    fileprivate var previousAngles: [UIImageView: CGFloat] = [:]
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pressureCenterView.layer.shadowOffset = CGSize(width: 0, height: 4)
        pressureCenterView.layer.shadowColor = UIColor.white.cgColor
        pressureCenterView.layer.shadowRadius = 4
        pressureCenterView.layer.shadowOpacity = 0.3
        
        flowrateCenterView.layer.shadowOffset = CGSize(width: 0, height: 4)
        flowrateCenterView.layer.shadowColor = UIColor.white.cgColor
        flowrateCenterView.layer.shadowRadius = 4
        flowrateCenterView.layer.shadowOpacity = 0.3
        
        temperatureCenterView.layer.shadowOffset = CGSize(width: 0, height: 4)
        temperatureCenterView.layer.shadowColor = UIColor.white.cgColor
        temperatureCenterView.layer.shadowRadius = 4
        temperatureCenterView.layer.shadowOpacity = 0.3
        temperatureLabel.text = "water_temp".localized + "."
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        view.layoutIfNeeded()
        
        pressureCenterView.layer.cornerRadius = pressureCenterView.frame.height / 2
        pressureIndicatorImageView.image = pressureIndicatorImageView.image?.withRenderingMode(.alwaysTemplate)
        
        flowrateCenterView.layer.cornerRadius = flowrateCenterView.frame.height / 2
        flowrateIndicatorImageView.image = flowrateIndicatorImageView.image?.withRenderingMode(.alwaysTemplate)
        
        temperatureCenterView.layer.cornerRadius = temperatureCenterView.frame.height / 2
        temperatureIndicatorImageView.image = temperatureIndicatorImageView.image?.withRenderingMode(.alwaysTemplate)
    }
    
    // MARK: - Overrides
    override func updateWith(deviceInfo: DeviceModel) {
        device = deviceInfo
        
        pressureValueLabel.text = "0.0"
        pressureUnitLabel.text = MeasuresHelper.unitAbbreviation(for: .pressure)
        pressureMinLimitLabel.text = "\(deviceInfo.pressureThreshold.min)"
        pressureMaxLimitLabel.text = "\(deviceInfo.pressureThreshold.max)"
        
        flowrateValueLabel.text = "0.0"
        flowrateUnitLabel.text = MeasuresHelper.unitAbbreviation(for: .flow)
        flowrateMinLimitLabel.text = "\(deviceInfo.flowThreshold.min)"
        flowrateMaxLimitLabel.text = "\(deviceInfo.flowThreshold.max)"
        
        temperatureValueLabel.text = "0"
        temperatureUnitLabel.text = MeasuresHelper.unitAbbreviation(for: .temperature)
        temperatureMinLimitLabel.text = "\(deviceInfo.temperatureThreshold.min)"
        temperatureMaxLimitLabel.text = "\(deviceInfo.temperatureThreshold.max)"
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self, selector: #selector(onUpdate(_:)), name: device.statusUpdateNotificationName, object: nil)
    }
    
    // MARK: - Realtime updates
    @objc func onUpdate(_ notification: Notification) {
        if let status = DeviceStatus(notification.userInfo as AnyObject), status.macAddress == device.macAddress {
            device.setStatus(status)
            
            if status.isConnected {
                let pressure = MeasuresHelper.adjust(status.psi, ofType: .pressure)
                pressureValueLabel.text = String(format: "%.1f", pressure)
                animateGaugeIndicator(pressureIndicatorImageView, to: pressure, threshold: device.pressureThreshold)
                
                let flowrate = MeasuresHelper.adjust(status.gpm, ofType: .flow)
                flowrateValueLabel.text = String(format: "%.1f", flowrate)
                animateGaugeIndicator(flowrateIndicatorImageView, to: flowrate, threshold: device.flowThreshold)
                
                let temperature = MeasuresHelper.adjust(status.tempF, ofType: .temperature)
                temperatureValueLabel.text = String(format: "%.0f", temperature)
                animateGaugeIndicator(temperatureIndicatorImageView, to: temperature, threshold: device.temperatureThreshold)
            } else {
                pressureValueLabel.text = "0.0"
                flowrateValueLabel.text = "0.0"
                temperatureValueLabel.text = "0"
            }
        }
    }
    
    // MARK: - Animations
    fileprivate func animateGaugeIndicator(_ gaugeIndicator: UIImageView, to value: Double, threshold: Threshold) {
        let previousAngle = previousAngles[gaugeIndicator] ?? 0
        var newValue = value > Double(threshold.max) ? Double(threshold.max) : value
        newValue = newValue < Double(threshold.min) ? Double(threshold.min) : newValue
        let newRotation = (kIndicatorMaxAngle * CGFloat(newValue)) / CGFloat(threshold.max)
        let angle = (newRotation * .pi) / 180
        let angleDiff = angle - previousAngle
        let halfTransform = CGAffineTransform.identity.rotated(by: previousAngle + angleDiff / 2)
        let fullTransform = CGAffineTransform.identity.rotated(by: previousAngle + angleDiff)
        var newColor = UIColor(hex: "78F0FB")
        
        previousAngles[gaugeIndicator] = angle
        
        let minRedLimitRange = (Double(threshold.max) / 16) * 3 // 3 parts of 16
        let maxRedLimitRange = Double(threshold.max) - minRedLimitRange
        if newValue > maxRedLimitRange || (threshold.measureType != .flow && newValue < minRedLimitRange) {
            newColor = UIColor(hex: "F07073")
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            gaugeIndicator.transform = halfTransform
        }, completion: { _ in
            UIView.animate(withDuration: 0.25) {
                gaugeIndicator.tintColor = newColor
                gaugeIndicator.transform = fullTransform
            }
        })
    }

}
