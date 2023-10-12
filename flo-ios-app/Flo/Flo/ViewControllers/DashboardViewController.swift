//
//  DashboardViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 31/05/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import Foundation
import SideMenu

internal enum ControllerType: Int {
    case kCardEmptyState = 0
    case kCardLocationName
    case kCardAlertsSummary
    case kCardLocationDevices
    case kCardDeviceData
    case kCardDeviceGauges
    case kCardRunHealthTest
    case kCardWaterUsage
    case kComparison
}

internal class DashboardViewController: FloBaseViewController, UISideMenuNavigationControllerDelegate {
    
    fileprivate var currentlyDisplayedCards: [CardInfoHolder] = []
    fileprivate var locationCards: [CardInfoHolder] = []
    fileprivate var emptyStateCards: [CardInfoHolder] = []
    fileprivate var needsToLoadData = false
    
    @IBOutlet fileprivate weak var cardsTableView: UITableView!
    
    @IBAction fileprivate func sideMenuAction() {
        if let sideMenu = SideMenuManager.default.menuLeftNavigationController {
            present(sideMenu, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.shared.registerForAllPushNotifications()
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        // Hide until some data comes from UI
        cardsTableView.alpha = 0
        
        setUpCardsControllers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshLocation),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        SideMenuManager.default.menuLeftNavigationController?.sideMenuDelegate = self
        
        if needsToLoadData {
            refreshLocation()
        } else {
            needsToLoadData = true
            checkIfDeviceRecentlyInstalled()
            trackDevices()
            refreshUI()
        }
        
        if AppV2PopupViewController.needsToBeShown {
            present(AppV2PopupViewController.getInstance(), animated: true, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    fileprivate func setUpCardsControllers() {
        // Prepare empty state
        let emptyStateCell = cardsTableView.dequeueReusableCell(withIdentifier: CardTableViewCell.storyboardId)!
        let emptyStateController = AddLocationCardViewController.getInstance(
            withHeight: cardsTableView.frame.height
        )
        addContentController(emptyStateController, toView: emptyStateCell.contentView)
        emptyStateCards = [
            CardInfoHolder(id: .kCardEmptyState, cell: emptyStateCell, controller: emptyStateController)
        ]
        
        // Create all the cards for the view
        let locationNameCell = cardsTableView.dequeueReusableCell(withIdentifier: CardTableViewCell.storyboardId)!
        let locationNameController = LocationDataCardViewController.getInstance()
        addContentController(locationNameController, toView: locationNameCell.contentView)
        
        let locationAlertsCell = cardsTableView.dequeueReusableCell(withIdentifier: CardTableViewCell.storyboardId)!
        let locationAlertsController = AlertsSummaryCardViewController.getInstance()
        addContentController(locationAlertsController, toView: locationAlertsCell.contentView)
        
        let locationDevicesCell = cardsTableView.dequeueReusableCell(withIdentifier: CardTableViewCell.storyboardId)!
        let locationDevicesController = LocationDevicesCardViewController.getInstance()
        (locationDevicesController as? CollapsableCardViewController)?.setDelegate(self)
        addContentController(locationDevicesController, toView: locationDevicesCell.contentView)
        
        let waterUsageCell = cardsTableView.dequeueReusableCell(withIdentifier: CardTableViewCell.storyboardId)!
        let waterUsageController = WaterUsageCardViewController.getInstance()
        (waterUsageController as? CollapsableCardViewController)?.setDelegate(self)
        addContentController(waterUsageController, toView: waterUsageCell.contentView)
        
        let comparisonCell = cardsTableView.dequeueReusableCell(withIdentifier: CardTableViewCell.storyboardId)!
        let comparisonController = FloDetectComparisonViewController.getInstance(storyboard: "FloDetect")
        (comparisonController as? CollapsableCardViewController)?.setDelegate(self)
        addContentController(comparisonController, toView: comparisonCell.contentView)
        
        locationCards = [
            CardInfoHolder(id: .kCardLocationName, cell: locationNameCell, controller: locationNameController),
            CardInfoHolder(id: .kCardAlertsSummary, cell: locationAlertsCell, controller: locationAlertsController),
            CardInfoHolder(id: .kCardLocationDevices, cell: locationDevicesCell, controller: locationDevicesController),
            CardInfoHolder(id: .kCardWaterUsage, cell: waterUsageCell, controller: waterUsageController),
            CardInfoHolder(id: .kComparison, cell: comparisonCell, controller: comparisonController)
        ]
    }
    
    // MARK: - Refresh screen
    @objc public func refreshLocation() {
        if let selectedLocationId = UserSessionManager.shared.selectedLocationId {
            cardsTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            refreshUI()
            LocationsManager.shared.getOne(selectedLocationId, { (_, _) in
                self.checkIfDeviceRecentlyInstalled()
                self.trackDevices()
                self.refreshUI()
            })
        }
    }
    
    public func refreshUI() {
        if !LocationsManager.shared.locations.isEmpty {
            currentlyDisplayedCards = []
            
            if let location = LocationsManager.shared.selectedLocation {
                var hideSummaryCard = true
                for device in location.devices where !device.systemModeLocked && device.isConnected {
                    hideSummaryCard = false
                    break
                }
                
                for card in locationCards {
                    if card.id == .kCardAlertsSummary && (location.devices.isEmpty || hideSummaryCard) { continue }
                    card.controller.updateWith(locationInfo: location)
                    currentlyDisplayedCards.append(card)
                }
            }
        } else {
            for card in emptyStateCards {
                if let addLocationCard = card.controller as? AddLocationCardViewController {
                    addLocationCard.updateHeight(cardsTableView.frame.height)
                }
            }
            
            currentlyDisplayedCards = emptyStateCards
        }
        
        cardsTableView.reloadData()
        
        // Enable cards visibility again if it was hidden
        cardsTableView.layer.removeAllAnimations()
        if cardsTableView.alpha < 1 {
            UIView.animate(withDuration: 0.3, animations: {
                self.cardsTableView.alpha = 1
            })
        }
    }
    
    // MARK: - Popups
    fileprivate func checkIfDeviceRecentlyInstalled() {
        for device in LocationsManager.shared.selectedLocation?.devices ?? [] {
            if device.isInstalled, let installDate = device.installDate, installDate.timeIntervalSinceNow > -172800, !device.isInstalledAndConfigured {
                DeviceInstalledViewController.instantiate(for: device)
                break
            }
        }
    }
    
    // MARK: - Devices real time updates
    fileprivate func trackDevices() {
        if let location = LocationsManager.shared.selectedLocation {
            for device in location.devices {
                NotificationCenter.default.removeObserver(self, name: device.statusUpdateNotificationName, object: nil)
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(onUpdate(_:)),
                    name: device.statusUpdateNotificationName,
                    object: nil
                )
            }
            
            if StatusManager.shared.authenticated {
                LocationsManager.shared.startTrackingDevices(location.id)
            } else {
                StatusManager.shared.authenticate({ authenticated in
                    if authenticated {
                        LocationsManager.shared.startTrackingDevices(location.id)
                    }
                })
            }
        }
    }
    
    @objc fileprivate func onUpdate(_ notification: Notification) {
        if let location = LocationsManager.shared.selectedLocation {
            var hideSummaryCard = true
            for device in location.devices where !device.systemModeLocked && device.isConnected {
                hideSummaryCard = false
                break
            }
            
            var summaryCardHidden = true
            for i in 0 ..< currentlyDisplayedCards.count where currentlyDisplayedCards[i].id == .kCardAlertsSummary {
                summaryCardHidden = false
                if hideSummaryCard {
                    currentlyDisplayedCards.remove(at: i)
                    cardsTableView.deleteRows(at: [IndexPath(row: i, section: 0)], with: .fade)
                }
                break
            }
            if !hideSummaryCard && summaryCardHidden {
                for card in locationCards where card.id == .kCardAlertsSummary {
                    currentlyDisplayedCards.insert(card, at: 1)
                    cardsTableView.insertRows(at: [IndexPath(row: 1, section: 0)], with: .fade)
                    break
                }
            }
        }
    }
}

extension DashboardViewController: CollapsableCardDelegate {
    
    func cardHasResized(_ cardViewController: CardViewController) {
        for i in 0 ..< currentlyDisplayedCards.count where currentlyDisplayedCards[i].controller == cardViewController {
            DispatchQueue.main.async {
                self.cardsTableView.reloadData()
            }
            break
        }
    }
}

extension DashboardViewController: UITableViewDelegate, UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentlyDisplayedCards.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return currentlyDisplayedCards[indexPath.row].cell
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return currentlyDisplayedCards[indexPath.row].controller.height
    }
}

internal class CardInfoHolder {
    
    public var id: ControllerType
    public var cell: UITableViewCell
    public var controller: CardViewController
    
    init(id: ControllerType, cell: UITableViewCell, controller: CardViewController) {
        self.id = id
        self.cell = cell
        self.controller = controller
    }
}
