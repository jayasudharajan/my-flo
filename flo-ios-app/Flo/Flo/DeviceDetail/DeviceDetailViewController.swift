//
//  DeviceDetailViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 26/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class DeviceDetailViewController: FloBaseViewController, UITableViewDelegate, UITableViewDataSource,
    HealthTestDelegate {
    
    public var device: DeviceModel!
    fileprivate var detailCards: [CardInfoHolder] = []
    fileprivate var valveController = ValveCardViewController.getInstance() as? ValveCardViewController
    
    @IBOutlet fileprivate weak var detailsTableView: UITableView!
    @IBOutlet fileprivate weak var valveView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithBack(tint: StyleHelper.colors.white)
        addRightNavBarItem(title: "device_settings".localized, tint: StyleHelper.colors.transparency50, onTap: #selector(goToDeviceSettings))
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        setUpCardsControllers()
        
        guard let valveController = self.valveController else {
            return
        }
        valveController.delegate = self
        
        addContentController(valveController, toView: valveView)
        refreshUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DevicesHelper.getOne(device.id) { (_, device) in
            if let d = device {
                self.device = d
                self.refreshUI()
                LocationsManager.shared.startTrackingDevice(d)
            }
        }
    }
    
    // MARK: - Setup/refresh cards
    fileprivate func setUpCardsControllers() {
        let deviceDataCell = detailsTableView.dequeueReusableCell(withIdentifier: CardTableViewCell.storyboardId)!
        let deviceDataController = DeviceDataCardViewController.getInstance()
        addContentController(deviceDataController, toView: deviceDataCell.contentView)
        
        let deviceAlertsCell = detailsTableView.dequeueReusableCell(withIdentifier: CardTableViewCell.storyboardId)!
        let deviceAlertsController = AlertsSummaryCardViewController.getInstance()
        addContentController(deviceAlertsController, toView: deviceAlertsCell.contentView)
        
        let deviceGaugesCell = detailsTableView.dequeueReusableCell(withIdentifier: CardTableViewCell.storyboardId)!
        let deviceGaugesController = DeviceGaugesCardViewController.getInstance()
        addContentController(deviceGaugesController, toView: deviceGaugesCell.contentView)
        
        let runHealthTestCell = detailsTableView.dequeueReusableCell(withIdentifier: CardTableViewCell.storyboardId)!
        let runHealthTestController = RunHealthTestCardViewController.getInstance(device: self.device)
        addContentController(runHealthTestController, toView: runHealthTestCell.contentView)
        
        detailCards = [
            CardInfoHolder(id: .kCardDeviceData, cell: deviceDataCell, controller: deviceDataController),
            CardInfoHolder(id: .kCardAlertsSummary, cell: deviceAlertsCell, controller: deviceAlertsController),
            CardInfoHolder(id: .kCardDeviceGauges, cell: deviceGaugesCell, controller: deviceGaugesController),
            CardInfoHolder(id: .kCardRunHealthTest, cell: runHealthTestCell, controller: runHealthTestController)
        ]
        
        detailsTableView.reloadData()
    }
    
    public func refreshUI() {
        for detailCard in detailCards {
            detailCard.controller.updateWith(deviceInfo: device)
        }
        valveController?.updateWith(deviceInfo: device)
    }
    
    // MARK: - Overrides
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - TableView protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detailCards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return detailCards[indexPath.row].cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return detailCards[indexPath.row].controller.height
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 122
    }
    
    // MARK: - Navigation
    @objc fileprivate func goToDeviceSettings() {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        
        if let deviceSettingsViewController = storyboard.instantiateViewController(withIdentifier: DeviceSettingsViewController.storyboardId) as? DeviceSettingsViewController {
            deviceSettingsViewController.device = device
            navigationController?.pushViewController(deviceSettingsViewController, animated: true)
        }
    }
    
    // MARK: - HealthTestDelegate
    public func cancelHealthTest() {
        showPopup(
            title: "cancel_health_test".localized,
            description: "are_you_sure_you_want_to_cancel_health_test_q".localized,
            options: [
                AlertPopupOption(title: "yes".localized, type: .normal, action: {
                    guard !FloApiRequest.demoModeEnabled() else {
                        self.device.healthTestStatus = .canceled
                        return
                    }
                    
                    self.showLoadingSpinner("loading".localized)
                    HealthTestHelper.cancelHealthTest(device: self.device, whenFinished: { error in
                        self.hideLoadingSpinner()
                        if let e = error {
                            self.showPopup(error: e)
                        }
                    })
                }),
                AlertPopupOption(title: "no".localized, type: .cancel, action: nil)
            ]
        )
    }
}
