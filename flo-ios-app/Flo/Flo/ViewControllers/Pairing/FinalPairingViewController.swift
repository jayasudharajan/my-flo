//
//  FinalPairingViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 19/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

/*
 RULES FOR FINALIZING ICD PAIRING (Note Steps 1-4 needs to be on ICD WiFi)
 1. Connect to Web Socket and Upload Cert Files
 2. Delegate FinishedUploadingCerts is called When complete or ErrorUploadingCertFiles
 3. After cert complete Update Network settings with Goal:GetICDNetworkSettings
 4. We may get disconnected (99.9% chance) after updateing network settings (Start from Step 6 if so)
 5. After updating Settings Socket we will wait 20 seconds to connect to Cell or WiFi (Kicked off after updating Network settings)
 6. Check to see if device has internet. Check internet connection 10 times before warning and sending ICD warning
 7. If Online we connect to MQTT and run a ReceivedMQTTMessage delegate to get latest status.
 8. If never connects to MQTT after 1 minute we tell user to enter WiFi information again
 9. If Status is online. We take them Pairing Complete View Controller
 10.If MQTT Prematurely disconnects. We will reconnect up to 3 times. This process runs steps 6-9
 */

import Foundation
import UIKit
import CFNetwork

private enum PairingStatus {
    case starting, certificatesUploaded, wiFiCredentialsUploaded, deviceConnected, deviceAdded, failed
}

internal class FinalPairingViewController: FloBaseViewController, FloWebSocketSsidDelegate {
    
    public var device: DeviceToPair!
    
    fileprivate var pairingStatus = PairingStatus.starting
    
    fileprivate var checkNetworkTimer: Timer? // Controls if the phone leaved the device's AP
    fileprivate let kCheckNetworkWaitingTime: Double = 1
    
    fileprivate var checkConnectionTimer: Timer? // Controls the max amount of time to wait for device connection
    fileprivate let kCheckConnectionWaitingTime: Double = 70
    
    fileprivate var uploadCertsTimer: Timer? // Controls the waiting time between attempts to upload certificates
    fileprivate let kUploadCertsWaitingTime: Double = 5
    fileprivate var uploadCertsAttempts = 0
    fileprivate let kUploadCertsMaxAttempts = 5
    
    fileprivate var animationTimer: Timer?
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var subTitleLabel: UILabel!
    @IBOutlet fileprivate weak var connectedContainerView: UIView!
    @IBOutlet fileprivate weak var connectedSignalImageView: UIImageView!
    @IBOutlet fileprivate weak var connectedSsidLabel: UILabel!
    @IBOutlet fileprivate weak var deviceImageView: UIImageView!
    @IBOutlet fileprivate weak var resultImageView: UIImageView!
    @IBOutlet fileprivate weak var connectionView: UIView!
    @IBOutlet fileprivate weak var wiFiImageView: UIImageView!
    @IBOutlet fileprivate weak var buttonsContainerView: UIView!
    @IBOutlet fileprivate weak var primaryButton: UIButton!
    
    @IBAction func primaryAction() {
        StatusManager.shared.logout()
        ICDPairingWebSocketModel.sharedInstance.disconnect()
        
        if pairingStatus == .deviceAdded {
            goBackToDashboard()
        } else {
            gotBackToPushToConnectScreen()
        }
    }
    
    fileprivate func gotBackToPushToConnectScreen() {
        let index = navigationController?.viewControllers.firstIndex(where: { controller -> Bool in
            return (controller as? PushToConnectViewController) != nil
        })
        
        if index != nil {
            if let pushToConnectVC = navigationController?.viewControllers[index!] as? PushToConnectViewController {
                pushToConnectVC.device = device
                popNavigation(pushToConnectVC)
            }
        } else {
            goToRoot()
        }
    }
    
    fileprivate func goBackToDashboard() {
        self.navigationController?.popToRootViewController(animated: false)
        if let tabBar = UIApplication.shared.keyWindow?.rootViewController as? TabBarController {
            tabBar.selectedIndex = 0
            tabBar.selectedViewController?.navigationController?.popToRootViewController(animated: false)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureNavBar(cancelButton: true)
        
        // Tracking
        controller = TrackingManager.kControllerPairingFinalizing
        
        connectedContainerView.layer.cornerRadius = 10
        connectedContainerView.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 0)
        connectedContainerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        connectedContainerView.layer.shadowColor = StyleHelper.colors.blue.cgColor
        connectedContainerView.layer.shadowRadius = 4
        connectedContainerView.layer.shadowOpacity = 0.3
        
        uploadICDCerts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.goingToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.comingFromBackground), name: UIApplication.willEnterForegroundNotification, object: nil)
        
        // UI setup
        if let image = device.image {
            deviceImageView.image = image
        }
        
        connectedSsidLabel.text = device.newWiFi?.ssid
        let signalLevel = device.newWiFi?.signalLevel ?? 4
        let wiFiImage = UIImage(named: "wifi-level\(signalLevel)-icon")?.withRenderingMode(.alwaysTemplate)
        connectedSignalImageView.image = wiFiImage
        wiFiImageView.image = wiFiImage
        
        animationTimer = Timer.scheduledTimer(timeInterval: 1.5, target: self, selector: #selector(animateConnection), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        StatusManager.shared.logout()
        ICDPairingWebSocketModel.sharedInstance.disconnect()
        
        checkNetworkTimer?.invalidate()
        checkNetworkTimer = nil
        checkConnectionTimer?.invalidate()
        checkConnectionTimer = nil
        uploadCertsTimer?.invalidate()
        uploadCertsTimer = nil
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    // MARK: - Observers' callbacks methods
    @objc func goingToBackground() {
        StatusManager.shared.logout()
        ICDPairingWebSocketModel.sharedInstance.disconnect()
        
        checkNetworkTimer?.invalidate()
        checkNetworkTimer = nil
        checkConnectionTimer?.invalidate()
        checkConnectionTimer = nil
        uploadCertsTimer?.invalidate()
        uploadCertsTimer = nil
    }
    
    @objc func comingFromBackground() {
        switch pairingStatus {
        case .starting:
            uploadICDCerts()
        case .certificatesUploaded:
            updateICDNetworkSettings()
        case .wiFiCredentialsUploaded:
            startCheckingDeviceStatus()
        default:
            break
        }
    }
    
    // MARK: - Certificate related methods
    func finishedUploadingCerts() {
        uploadCertsTimer?.invalidate()
        uploadCertsTimer = nil
        pairingStatus = .certificatesUploaded
        titleLabel.text = "updating_network_settings".localized
        
        updateICDNetworkSettings()
    }
    
    func errorUploadingCertFiles() {
        uploadCertsTimer?.invalidate()
        uploadCertsTimer = nil
        
        pairingStatus = .failed
        showPairingResult(message: "pairing_invalid_device_code".localized)
    }
    
    @objc fileprivate func updateCertCounter() {
        uploadCertsAttempts += 1
        
        if uploadCertsAttempts == kUploadCertsMaxAttempts {
            uploadCertsTimer?.invalidate()
            uploadCertsTimer = nil
            
            pairingStatus = .failed
            showPairingResult(message: "pairing_error_uploading_data".localized)
        }
    }
    
    fileprivate func uploadICDCerts() {
        guard
            let loginToken = device.qrCode?.loginToken,
            let severCert = device.qrCode?.serverCert,
            let clientCert = device.qrCode?.clientCert,
            let clientKey = device.qrCode?.clientKey
        else { return }
        
        let socket = ICDPairingWebSocketModel.sharedInstance
        socket.disconnect()
        socket.setGoalWithCert(
            .uploadCertFiles,
            icdLoginToken: loginToken,
            certDataRequest: ICDCertUploadRequestModel(
                params: ICDSetCertModel(serverCert: severCert, clientCert: clientCert, clientKey: clientKey)
            )
        )
        socket.delegate = self
        
        uploadCertsTimer = Timer.scheduledTimer(
            timeInterval: kUploadCertsWaitingTime,
            target: self,
            selector: #selector(updateCertCounter),
            userInfo: nil,
            repeats: true
        )
        
        socket.connectICDWebSocket()
    }
    
    // MARK: - WiFi credentials pushing methods
    func finishedIcdNetworkSettingUpdateCheckIfOnline() {
        pairingStatus = .wiFiCredentialsUploaded
        ICDPairingWebSocketModel.sharedInstance.disconnect()
        
        titleLabel.text = "disconnecting_from_device".localized
        startCheckingDeviceStatus()
    }
    
    func errorUpdatingIcdNetworkSettings(_ message: String) {
        pairingStatus = .failed
        showPairingResult(message: "pairing_error_updating_network_settings".localized)
    }
    
    fileprivate func updateICDNetworkSettings() {
        if let loginToken = device.qrCode?.loginToken, let newWiFi = device.newWiFi {
            let socket = ICDPairingWebSocketModel.sharedInstance
            socket.setGoal(.updateICDNetworkSettings, icdLoginToken: loginToken)
            socket.homeWiFiData = newWiFi
            socket.delegate = self
            socket.connectICDWebSocket()
        }
    }
    
    // MARK: - Connect to device methods
    fileprivate func startCheckingDeviceStatus() {
        checkNetworkTimer = Timer.scheduledTimer(timeInterval: kCheckNetworkWaitingTime, target: self, selector: #selector(checkConnectedNetwork), userInfo: nil, repeats: true)
    }
    
    @objc fileprivate func checkConnectedNetwork() {
        let ssid = WifiHelper.getCurrentSsid()
        if ssid == nil || ssid != device.qrCode?.apName {
            checkNetworkTimer?.invalidate()
            checkNetworkTimer = nil
            titleLabel.text = "checking_device_status".localized
            
            checkConnectionTimer = Timer.scheduledTimer(timeInterval: kCheckConnectionWaitingTime, target: self, selector: #selector(deviceOffline), userInfo: nil, repeats: false)
            perform(#selector(checkDeviceBecomesOnline), with: nil, afterDelay: 5.0)
        }
    }
    
    @objc fileprivate func checkDeviceBecomesOnline() {
        if let firebaseToken = self.device.qrCode?.firestoreToken {
            StatusManager.shared.logout()
            
            StatusManager.shared.authenticate(withToken: firebaseToken) { (success) in
                if success {
                    if let deviceId = self.device.qrCode?.deviceId {
                        StatusManager.shared.trackMacAddress(deviceId, onUpdate: { (status) in
                            self.processDeviceUpdate(status: status)
                        })
                    } else {
                        LoggerHelper.log("Pairing - Connect To Device: Missing DeviceId", level: .error)
                    }
                } else {
                    LoggerHelper.log("Pairing - Connect To Device: Firestore Auth failed, token: " + firebaseToken, level: .error)
                }
            }
        } else {
            LoggerHelper.log("Pairing - Connect To Device: Firestore token missing", level: .error)
        }
    }
    
    // MARK: - Firestore methods
    fileprivate func processDeviceUpdate(status: DeviceStatus) {
        guard let deviceId = self.device.qrCode?.deviceId, deviceId == status.macAddress else {
            return
        }
        
        if status.isConnected {
            pairingStatus = .deviceConnected
            
            checkNetworkTimer?.invalidate()
            checkNetworkTimer = nil
            checkConnectionTimer?.invalidate()
            checkConnectionTimer = nil
            
            StatusManager.shared.logout()
            
            TrackingManager.shared.track(TrackingManager.kEventPairingComplete)
            LoggerHelper.log("Pairing complete", level: .debug)
            
            storeUserICD()
        }
    }
    
    // MARK: - Final steps
    fileprivate func storeUserICD() {
        FloApiRequest(controller: "v2/devices/pair/complete", method: .post, queryString: nil, data: device.pairingCompleteModel, done: { (error, _) in
            if error != nil {
                self.pairingStatus = .failed
                self.showPairingResult(message: "pairing_error_adding_device_to_account".localized)
            } else {
                self.pairingStatus = .deviceAdded
                self.showPairingResult()
            }
        }).secureFloRequest()
    }
    
    @objc fileprivate func deviceOffline() {
        StatusManager.shared.logout()
        ICDPairingWebSocketModel.sharedInstance.disconnect()
        
        pairingStatus = .failed
        showPairingResult(message: "pairing_error_check_network_passwork_and_internet_access".localized)
    }
    
    // MARK: - Navigation bar setup
    fileprivate func configureNavBar(cancelButton: Bool = false) {
        if cancelButton {
            setupNavBarWithCancel(returningToRoot: true)
        } else {
            let leftButton = UIBarButtonItem(title: "", style: .plain, target: navigationController, action: nil)
            navigationItem.leftBarButtonItem = leftButton
            let rightButton = UIBarButtonItem(title: "", style: .plain, target: navigationController, action: nil)
            navigationItem.rightBarButtonItem = rightButton
        }
    }
    
    // MARK: - Pairing results
    fileprivate func showPairingResult(message: String = "") {
        // To prevent an alertViewController from interfering with navigation
        dismiss(animated: false, completion: nil)
        
        if pairingStatus == .deviceAdded {
            device.qrCode = nil
            titleLabel.text = "pairing_complete".localized
            subTitleLabel.text = ""
            StatusManager.shared.authenticate({ _ in })
        } else {
            titleLabel.text = "pairing_failed".localized
            subTitleLabel.text = message
        }
        
        pairingResultAnimation()
    }
    
    // MARK: - Animations
    @objc fileprivate func animateConnection() {
        for subview in connectionView.subviews where subview.alpha > 0.5 {
            let nextTag = subview.tag == connectionView.subviews.count ? 1 : (subview.tag + 1)
            if let nextSubview = connectionView.viewWithTag(nextTag) {
                UIView.animate(withDuration: 0.2) {
                    subview.alpha = 0.15
                    nextSubview.alpha = 1
                }
            }
            break
        }
    }
    
    fileprivate func pairingResultAnimation() {
        let primaryButtonTitle = (pairingStatus == .deviceAdded) ? "go_to_dashboard".localized : "try_again".localized
        primaryButton.setTitle(primaryButtonTitle, for: .normal)
        
        for subview in connectionView.subviews where subview.alpha > 0.5 {
            UIView.animate(withDuration: 0.2) {
                subview.alpha = 0.15
                self.connectionView.alpha = 0.15
                self.connectionView.backgroundColor = StyleHelper.colors.blue
            }
            break
        }
        
        self.configureNavBar(cancelButton: (self.pairingStatus != .deviceAdded))
        resultImageView.image = (pairingStatus == .deviceAdded) ? UIImage(named: "green-check-icon") : UIImage(named: "red-triangle-alert-icon")
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.subTitleLabel.isHidden = (self.pairingStatus == .deviceAdded)
                self.connectedContainerView.isHidden = (self.pairingStatus != .deviceAdded)
                self.buttonsContainerView.isHidden = false
                self.resultImageView.isHidden = false
                self.resultImageView.frame = CGRect(
                    x: self.resultImageView.frame.origin.x - 42,
                    y: self.resultImageView.frame.origin.y,
                    width: 84,
                    height: self.resultImageView.frame.height
                )
            },
            completion: { completed in
                if completed {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.resultImageView.frame = CGRect(
                            x: self.resultImageView.frame.origin.x + 10,
                            y: self.resultImageView.frame.origin.y,
                            width: 64,
                            height: self.resultImageView.frame.height
                        )
                    })
                }
            }
        )
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
}
