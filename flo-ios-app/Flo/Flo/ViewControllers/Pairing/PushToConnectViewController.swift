//
//  PushToConnectViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 13/10/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import UIKit

internal class PushToConnectViewController: FloBaseViewController {
    
    public var device: DeviceToPair!
    public var alreadyPairedDeviceId: String?
    fileprivate var blinkTimer: Timer?
    
    @IBOutlet fileprivate weak var ledOffImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Stop all firestore tracking
        LocationsManager.shared.stopTrackingDevices()
        
        setupNavBarWithCancel(returningToRoot: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        blinkTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.blink), userInfo: nil, repeats: true)
        
        if let id = alreadyPairedDeviceId {
            showLoadingSpinner("loading".localized())
            
            FloApiRequest(
                controller: "v2/devices/\(id)",
                method: .get,
                queryString: ["expand": "pairingData"],
                data: nil,
                done: { (error, data) in
                    self.hideLoadingSpinner()
                    if error != nil {
                        self.showPopup(error: error!)
                        self.goBack()
                    } else if let d = data {
                        self.device.qrCode = DeviceQRCode(d["pairingData"] as AnyObject)
                    }
                }
            ).secureFloRequest()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        blinkTimer?.invalidate()
        blinkTimer = nil
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Animation
    @objc func blink() {
        ledOffImageView.isHidden = !ledOffImageView.isHidden
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? ScanQRCodeViewController {
            viewController.device = device
        }
    }
    
}
