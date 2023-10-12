//
//  HealthTestResultsViewController.swift
//  Flo
//
//  Created by Josefina Perez on 19/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

class HealthTestResultsViewController: FloBaseViewController {
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var iconImageView: UIImageView!
    @IBOutlet fileprivate weak var locationDeviceLabel: UILabel!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
    
    @IBOutlet fileprivate weak var stackView: UIView!
    @IBOutlet fileprivate weak var column1ValueLabel: UILabel!
    @IBOutlet fileprivate weak var column2ValueLabel: UILabel!
    @IBOutlet fileprivate weak var column3ValueLabel: UILabel!
    
    @IBOutlet fileprivate weak var actionButton: UIButton!
    
    public var device: DeviceModel!
    public var testCancelledInDemoMode: Bool = false
    fileprivate var location: LocationModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithBack(
            andTitle: "health_test".localized(),
            tint: StyleHelper.colors.white,
            titleColor: StyleHelper.colors.white
        )
        
        var locationDeviceText = device.nickname.isEmpty ? device.model : device.nickname
        if let location = LocationsManager.shared.getOneByDeviceLocally(device.id) {
            let locationText = location.nickname.isEmpty ? location.address : location.nickname
            locationDeviceText = locationText + ", " + locationDeviceText
        }
        locationDeviceLabel.text = locationDeviceText
        
        getTestResults()
    }
    
    fileprivate func getTestResults() {
        showLoadingSpinner("loading".localized)
        
        HealthTestHelper.getHealthTestStatus(device: device, whenFinished: { (error, result) in
            self.hideLoadingSpinner()
            if let e = error {
                self.showPopup(title: e.title, description: e.message, buttonText: "ok".localized) {
                    self.goBack()
                }
            } else if var r = result {
                if FloApiRequest.demoModeEnabled() && self.testCancelledInDemoMode {
                    r.leakType = .interrupted
                    self.configureAsTestInterrupted(result: r)
                } else {
                    if r.status == .completed {
                        if r.testPassed {
                            self.configureAsNoLeakDetected()
                        } else {
                            self.configureAsDripDetected(result: r)
                        }
                    } else {
                        self.configureAsTestInterrupted(result: r)
                    }
                }
            }
        })
    }
    
    fileprivate func configureAsNoLeakDetected() {
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        iconImageView.image = UIImage(named: "green-check-icon")
        titleLabel.text = "no_leak_detected".localized
        descriptionLabel.text = "no_leak_detected_description_1".localized + "\n\n" +
            "no_leak_detected_description_2".localized
        
        actionButton.setTitle("done".localized, for: .normal)
        actionButton.layer.cornerRadius = actionButton.frame.height / 2
        actionButton.layer.borderWidth = 1
        actionButton.layer.borderColor = StyleHelper.colors.transparency20.cgColor
        actionButton.backgroundColor = StyleHelper.colors.transparency
        actionButton.addTarget(self, action: #selector(doneAction), for: .touchUpInside)
    }
    
    fileprivate func configureAsDripDetected(result: HealthTestResult) {
        view.layer.addGradient(from: StyleHelper.colors.darkOrange, to: StyleHelper.colors.orange, angle: 90)
        
        iconImageView.image = UIImage(named: "warning")
        titleLabel.text = "small_drip_detected".localized
        descriptionLabel.text = "drip_detected_description".localized
        stackView.isHidden = false
        
        var duration = ""
        let hours = result.testDuration / 3600
        let minutes = (result.testDuration % 3600) / 60
        let seconds = result.testDuration % 60
        
        if hours > 0 {
            duration = "\(hours) h"
        }
        if minutes > 0 {
            duration += duration.isEmpty ? "" : " "
            duration += "\(minutes) " + "min_s_".localized
        }
        if seconds > 0 && hours == 0 {
            duration += duration.isEmpty ? "" : " "
            duration += "\(seconds) " + "seconds".localized
        }
        if duration.isEmpty {
            duration = "0 " + "seconds".localized
        }
        
        column1ValueLabel.text = duration
        column2ValueLabel.text = "\(String(format: "%.0f", MeasuresHelper.adjust(result.leakLossMaxGal, ofType: .volume).rounded())) \(MeasuresHelper.unitAbbreviation(for: .volume))"
        column3ValueLabel.text = "\(String(format: "%.0f", result.deltaPressure.rounded()))%"
        
        actionButton.setTitle("troubleshoot".localized, for: .normal)
        actionButton.layer.cornerRadius = actionButton.frame.height / 2
        actionButton.layer.addGradient(from: StyleHelper.colors.cyan, to: StyleHelper.colors.darkCyan, angle: 90)
        actionButton.addTarget(self, action: #selector(troubleshootAction), for: .touchUpInside)
    }
    
    fileprivate func configureAsTestInterrupted(result: HealthTestResult) {
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        iconImageView.image = UIImage(named: "cancel")
        titleLabel.text = "health_test_interrupted".localized
        switch result.leakType {
        case .interrupted:
            descriptionLabel.text = "leak_type_0_description".localized + "\n\n" +
                "leak_type_0_description_2".localized
        case .cancelled:
            descriptionLabel.text = "leak_type_2_description".localized + "\n\n" +
                "leak_type_2_description_2".localized
        case .appValveopen:
            descriptionLabel.text = "leak_type_3_description".localized + "\n\n" +
                "leak_type_3_description_2".localized
        case .manualOpen:
            descriptionLabel.text = "leak_type_4_description".localized + "\n\n" +
                "leak_type_4_description_2".localized
        case .flowDetected:
            descriptionLabel.text = "leak_type_5_description".localized + "\n\n" +
                "leak_type_5_description_2".localized
        case .thermalExpansion:
            descriptionLabel.text = "leak_type_6_description".localized
        }
        
        actionButton.setTitle("done".localized, for: .normal)
        actionButton.layer.cornerRadius = actionButton.frame.height / 2
        actionButton.layer.borderWidth = 1
        actionButton.layer.borderColor = StyleHelper.colors.transparency20.cgColor
        actionButton.backgroundColor = StyleHelper.colors.transparency
        actionButton.addTarget(self, action: #selector(doneAction), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc fileprivate func doneAction() {
        goBack()
    }
    
    @objc fileprivate func troubleshootAction() {
        showWebView(
            url: "https://support.meetflo.com/hc/en-us/articles/115000700073-Small-Drip-Detected",
            title: "Troubleshoot"
        )
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    override func goBack() {
        guard let controllers = navigationController?.viewControllers else {
            navigationController?.popToRootViewController(animated: true)
            return
        }
        
        for controller in controllers {
            if controller.isKind(of: DeviceDetailViewController.self) {
                navigationController?.popToViewController(controller, animated: true)
                break
            }
        }
    }
}
