//
//  DeviceWiFiViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 19/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import NetworkExtension

internal class DeviceWiFiViewController: FloBaseViewController {
    
    fileprivate let kConnectionWaitingTime: Double = 5
    fileprivate var waitingForAutoConnection = false
    public var device: DeviceToPair!
    
    @IBOutlet fileprivate weak var loadingView: UIView!
    @IBOutlet fileprivate weak var explanationView: UIView!
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var wifiSsidLabel: UILabel!
    @IBOutlet fileprivate weak var stepTwoLabel: UILabel!
    
    @IBAction fileprivate func openSettingsAction() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.openURL(url)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBarWithCancel(returningToRoot: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        var ssid = device.qrCode?.apName ?? "Flo-XXXx"
        
        wifiSsidLabel.text = ssid
        stepTwoLabel.text = (stepTwoLabel.text ?? "") + " " + ssid + "."
        ssid = "\"" + ssid + "\""
        titleLabel.text = (titleLabel.text ?? "") + " " + ssid
        
        connectToDeviceWiFi()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - WiFi related methods
    @objc fileprivate func didBecomeActive() {
        if !waitingForAutoConnection {
            explanationView.isHidden = true
            loadingView.isHidden = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + kConnectionWaitingTime) {
                self.compareSSIDs()
            }
        }
    }
    
    fileprivate func compareSSIDs() {
        if WifiHelper.getCurrentSsid() == device.qrCode?.apName {
            performSegue(withIdentifier: AssignWiFiToDeviceViewController.storyboardId, sender: nil)
        } else {
            explanationView.isHidden = false
            loadingView.isHidden = true
        }
    }
    
    fileprivate func connectToDeviceWiFi() {
        explanationView.isHidden = true
        loadingView.isHidden = false
        
        if let apName = device.qrCode?.apName {
            if #available(iOS 13.0, *) {
                let config = NEHotspotConfiguration(ssidPrefix: apName)
                config.joinOnce = true
                config.hidden = true
                waitingForAutoConnection = true
                
                NEHotspotConfigurationManager.shared.apply(config) { error in
                    if let e = error {
                        LoggerHelper.log(e)
                        self.explanationView.isHidden = false
                        self.loadingView.isHidden = true
                        self.waitingForAutoConnection = false
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.kConnectionWaitingTime, execute: {
                            self.waitingForAutoConnection = false
                            self.compareSSIDs()
                        })
                    }
                }
            } else if #available(iOS 11.0, *) {
                let config = NEHotspotConfiguration(ssid: apName)
                config.joinOnce = true
                waitingForAutoConnection = true
                
                NEHotspotConfigurationManager.shared.apply(config) { error in
                    if let e = error {
                        LoggerHelper.log(e)
                        self.explanationView.isHidden = false
                        self.loadingView.isHidden = true
                        self.waitingForAutoConnection = false
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + self.kConnectionWaitingTime, execute: {
                            self.waitingForAutoConnection = false
                            self.compareSSIDs()
                        })
                    }
                }
            } else {
                explanationView.isHidden = false
                loadingView.isHidden = true
            }
        } else {
            goBack()
        }
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? AssignWiFiToDeviceViewController {
            viewController.device = device
        }
    }

}
