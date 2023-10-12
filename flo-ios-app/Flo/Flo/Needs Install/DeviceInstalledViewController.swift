//
//  DeviceInstalledViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 17/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class DeviceInstalledViewController: FloBaseViewController {
    
    fileprivate static let semaphore = DispatchSemaphore(value: 1)
    fileprivate static var onTop = false
    
    public var device: DeviceModel!
    fileprivate var validator: SingleChoiceValidator!
    
    @IBOutlet fileprivate weak var hintLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hintLabel.text = "ensure_device_is_installed_properly_and_complete_steps".localized(args: [device.nickname])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        //Preload data for the next two screens
        _ = ListsManager.shared.getPRVInstallationTypes({(_, _) in })
        _ = ListsManager.shared.getIrrigationTypes({(_, _) in })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DeviceInstalledViewController.onTop = false
    }
    
    // MARK: - Overrides
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    override func shouldHideNavBar() -> Bool {
        return true
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let pressureReducingValveVC = segue.destination as? PressureReducingValveViewController {
            pressureReducingValveVC.device = device
        }
    }
    
    // MARK: - Instantiation
    public class func instantiate(for device: DeviceModel) {
        semaphore.wait()
        if !onTop {
            onTop = true
            semaphore.signal()
            
            let storyboard = UIStoryboard(name: "Device", bundle: nil)
            
            guard
                let rootViewController = UIApplication.shared.keyWindow?.rootViewController,
                let tabBarController = rootViewController as? TabBarController,
                let tabController = tabBarController.selectedViewController,
                let navController = tabController as? UINavigationController,
                let installedVC = storyboard.instantiateViewController(withIdentifier: DeviceInstalledViewController.storyboardId) as? DeviceInstalledViewController
            else { return }
            
            installedVC.device = device
            navController.pushViewController(installedVC, animated: true)
        } else {
            semaphore.signal()
        }
    }
    
}
