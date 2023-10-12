//
//  AssignWiFiToDeviceViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 19/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class AssignWiFiToDeviceViewController: FloBaseViewController, FloWebSocketSsidDelegate, UITableViewDelegate, UITableViewDataSource {
    
    public var device: DeviceToPair!
    fileprivate var scannedWiFis: [WiFiModel] = []
    fileprivate let refreshControl = UIRefreshControl()
    fileprivate var scanTimer: Timer?
    fileprivate var connectionRetries = 0
    
    @IBOutlet fileprivate weak var titleLabel: UILabel!
    @IBOutlet fileprivate weak var wiFisTable: UITableView!
    
    @IBAction fileprivate func rescanAction() {
        // Haptic feedback
        if #available(iOS 10.0, *) {
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.prepare()
            impact.impactOccurred()
        }
        
        scanWiFis()
    }
    
    @IBAction fileprivate func enterManuallyAction() {
        let wiFiCredsInputView = AlertPopupWiFiCredsHeader.getInstance()
        
        self.showPopup(
            title: "enter_wifi_credentials".localized,
            description: "connect_to".localized,
            inputView: wiFiCredsInputView,
            acceptButtonText: "connect".localized,
            acceptButtonAction: {
                let wiFi = WiFiModel(ssid: wiFiCredsInputView.getSsid(), password: wiFiCredsInputView.getPassword())
                self.device.newWiFi = wiFi
                self.performSegue(withIdentifier: FinalPairingViewController.storyboardId, sender: nil)
            },
            cancelButtonText: "cancel".localized
        )
    }
    
    @IBAction fileprivate func networkNotListedAction() {
        showPopup(title: "wifi_not_listed".localized, description: "if_wifi_not_visible_contact_support".localized)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBarWithCancel(returningToRoot: true)
        
        refreshControl.addTarget(self, action: #selector(scanWiFis), for: .valueChanged)
        refreshControl.tintColor = StyleHelper.colors.blue
        wiFisTable.addSubview(refreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        titleLabel.text = "connect_device_to_your_homes_wifi".localized(args: [device.nickname])
        scanWiFis()
        
        NotificationCenter.default.addObserver(self, selector: #selector(scanWiFis), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopScanning), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        stopScanning()
    }
    
    // MARK: - WiFi related methods
    @objc fileprivate func scanWiFis() {
        if !refreshControl.isRefreshing {
            refreshControl.beginRefreshing()
        }
        wiFisTable.setContentOffset(CGPoint(x: 0, y: -refreshControl.frame.height), animated: true)
        
        connectionRetries = 0
        if let loginToken = device.qrCode?.loginToken {
            let socket = ICDPairingWebSocketModel.sharedInstance
            socket.disconnect()
            socket.setGoal(.getICDAvailbleWifiList, icdLoginToken: loginToken)
            socket.delegate = self
            socket.connectICDWebSocket()
            
            scanTimer?.invalidate()
            scanTimer = nil
            scanTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(shouldScan), userInfo: nil, repeats: true)
        }
    }
    
    @objc fileprivate func shouldScan() {
        if ICDPairingWebSocketModel.sharedInstance.isICDConnected() {
            stopScanning()
        } else {
            connectionRetries += 1
            if connectionRetries > 15 {
                receievedIcdSsids([])
            }
        }
    }
    
    @objc fileprivate func stopScanning() {
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        scanTimer?.invalidate()
        scanTimer = nil
    }
    
    func receievedIcdSsids(_ ssids: [WiFiModel]?) {
        stopScanning()
        scannedWiFis = []
        
        if let list = ssids {
            scannedWiFis = list.sorted { (wifi1, wifi2) -> Bool in
                if wifi1.ssid > wifi2.ssid {
                    return true
                }
                return false
            }
            
            var count = scannedWiFis.count
            for index in 0 ..< count {
                let nextIndex = index + 1
                if nextIndex < count && scannedWiFis[index].ssid == scannedWiFis[nextIndex].ssid {
                    if scannedWiFis[index].signal > scannedWiFis[nextIndex].signal {
                        scannedWiFis.remove(at: nextIndex)
                    } else {
                        scannedWiFis.remove(at: index)
                    }
                    count -= 1
                }
            }
            
            scannedWiFis = scannedWiFis.sorted { (wifi1, wifi2) -> Bool in
                if wifi1.signal > wifi2.signal {
                    return true
                }
                return false
            }
        }
        
        wiFisTable.reloadData()
    }
    
    // MARK: - TableView protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return scannedWiFis.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: WiFiTableViewCell.storyboardId, for: indexPath) as? WiFiTableViewCell {
            cell.configure(scannedWiFis[indexPath.row])
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if scannedWiFis[indexPath.row].encryption != "none" {
            DispatchQueue.main.async {
                let wiFiPasswordInputView = AlertPopupWiFiPasswordHeader.getInstance()
                let wiFi = self.scannedWiFis[indexPath.row]
                
                self.showPopup(
                    title: "enter_password".localized,
                    description: "connect_to".localized + " " + wiFi.ssid,
                    inputView: wiFiPasswordInputView,
                    acceptButtonText: "connect".localized,
                    acceptButtonAction: {
                        wiFi.password = wiFiPasswordInputView.getPassword()
                        self.device.newWiFi = wiFi
                        self.performSegue(withIdentifier: FinalPairingViewController.storyboardId, sender: nil)
                    },
                    cancelButtonText: "cancel".localized
                )
            }
        }
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? FinalPairingViewController {
            viewController.device = device
        }
    }

}
