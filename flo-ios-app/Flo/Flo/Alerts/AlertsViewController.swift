//
//  AlertsViewController.swift
//  Flo
//
//  Created by Josefina Perez on 09/08/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

private enum EventTypeFilter {
    case critical
    case warning
    case info
}

import UIKit
import SwiftyJSON

internal class AlertsViewController: FloBaseViewController, UITableViewDelegate, UITableViewDataSource, EventDeviceFilterHeaderDelegate, EventTypeFilterHeaderDelegate {
    
    public var deviceIds: [String] = []
    public var isDeviceFilterEnabled = true
    
    fileprivate var page = 1
    fileprivate let kSize = 100
    fileprivate var alertsLoaded = false
    fileprivate var gettingEvents = true
    fileprivate var allEventsFetched = true
    
    fileprivate var topEvents: [EventModel] = []
    fileprivate var filteredTopEvents: [EventModel] = []
    
    fileprivate var logEvents: [EventModel] = []
    fileprivate var filteredLogEvents: [EventModel] = []
    
    fileprivate var eventTypeFilters: [EventTypeFilter] = []
    fileprivate var locationsWithDevices: [LocationModel] = []
    
    fileprivate let kfilterCellHeight: CGFloat = 40
    
    @IBOutlet fileprivate weak var alertsTable: UITableView!
    @IBOutlet fileprivate weak var btnHideFilters: UIButton!
    
    @IBOutlet fileprivate weak var typeFilterView: UIView!
    @IBOutlet fileprivate weak var typeFilterViewYAnchor: NSLayoutConstraint!
    @IBOutlet fileprivate weak var btnCritical: UIButton!
    @IBOutlet fileprivate weak var btnWarning: UIButton!
    @IBOutlet fileprivate weak var btnInfo: UIButton!
    
    @IBOutlet fileprivate weak var deviceFilterTable: UITableView!
    @IBOutlet fileprivate weak var deviceFilterTableYAnchor: NSLayoutConstraint!
    @IBOutlet fileprivate weak var deviceFilterTableHeight: NSLayoutConstraint!
    
    @IBAction func hideFilters() {
        if !typeFilterView.isHidden {
            showEventTypeFilter(actualYOffset: 0)
        } else if !deviceFilterTable.isHidden {
            showEventDeviceFilter(actualYOffset: 0)
        }
    }
    
    @IBAction func filterApplied(_ sender: UIButton) {
        sender.currentImage == nil ? sender.setImage(UIImage(named: "check-blue"), for: .normal) :
            sender.setImage(nil, for: .normal)
        
        switch sender {
        case btnCritical:
            eventTypeFilters.contains(.critical) ? eventTypeFilters.removeAll(where: { $0 == .critical }) :
                eventTypeFilters.append(.critical)
        case btnWarning:
            eventTypeFilters.contains(.warning) ? eventTypeFilters.removeAll(where: { $0 == .warning }) :
                eventTypeFilters.append(.warning)
        case btnInfo:
            eventTypeFilters.contains(.info) ? eventTypeFilters.removeAll(where: { $0 == .info }) :
                eventTypeFilters.append(.info)
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if navigationController?.viewControllers.count ?? 1 == 1 {
            setupNavBar(with: "alerts".localized)
        } else {
            setupNavBarWithBack(
                andTitle: "alerts".localized,
                tint: StyleHelper.colors.white,
                titleColor: StyleHelper.colors.white
            )
        }
        
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        eventTypeFilters = [.critical, .warning, .info]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        locationsWithDevices = LocationsManager.shared.locations.filter({ $0.devices.count > 0 })
        var totalHeight: CGFloat = 0
        for location in locationsWithDevices {
            totalHeight += (kfilterCellHeight * CGFloat(location.devices.count)) + CGFloat(30 * location.devices.count) + 30
        }
        deviceFilterTableHeight.constant = totalHeight
        
        // If it's not filtering out by specific device / location
        if deviceIds.isEmpty {
            for location in locationsWithDevices {
                for device in location.devices {
                    deviceIds.append(device.id)
                }
            }
        }
        
        if alertsLoaded {
            getEvents(fromBeginning: true)
        } else {
            showLoadingSpinner("loading".localized)
            AlertsManager.shared.getAlerts { (error, _) in
                self.hideLoadingSpinner()
                if let e = error {
                    self.showPopup(error: e)
                } else {
                    self.alertsLoaded = true
                    self.getEvents(fromBeginning: true)
                }
            }
        }
    }
    
    fileprivate func getEvents(fromBeginning: Bool = false) {
        showLoadingSpinner("loading".localized)
        
        gettingEvents = true
        if fromBeginning {
            page = 1
            topEvents = []
            logEvents = []
            
            AlertsManager.shared.getTopEventsFor(deviceIds: deviceIds) { (_, events) in
                self.topEvents = events
                self.getLogs()
            }
        } else {
            getLogs()
        }
    }
    
    fileprivate func getLogs() {
        AlertsManager.shared.getEventsFor(deviceIds: deviceIds, page: page, size: kSize) { (error, events) in
            if error == nil {
                self.allEventsFetched = events.count < self.kSize
            }
            self.logEvents.append(contentsOf: events)
            
            self.filterEvents()
            self.gettingEvents = false
            self.hideLoadingSpinner()
        }
    }
    
    fileprivate func filterEvents() {
        filteredTopEvents = topEvents
        filteredLogEvents = logEvents
        
        var severityFilters: [AlertSeverity] = []
        if !eventTypeFilters.contains(.critical) {
            severityFilters.append(.critical)
        }
        if !eventTypeFilters.contains(.warning) {
            severityFilters.append(.warning)
        }
        if !eventTypeFilters.contains(.info) {
            severityFilters.append(.info)
        }
        
        filteredTopEvents.removeAll { (event) -> Bool in
            if let alert = event.alert {
                if severityFilters.contains(alert.severity) {
                    return true
                }
            }
            return false
        }
        filteredLogEvents.removeAll { (event) -> Bool in
            if let alert = event.alert {
                if severityFilters.contains(alert.severity) {
                    return true
                }
            }
            return false
        }
        
        alertsTable.reloadData()
    }
    
    // MARK: - Table view delegate and data source
    public func numberOfSections(in tableView: UITableView) -> Int {
        if tableView == deviceFilterTable {
            return locationsWithDevices.count + 1
        }
        
        return 2
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == deviceFilterTable {
            if section == 0 {
                return 1
            } else if section - 1 < locationsWithDevices.count {
                return locationsWithDevices[section - 1].devices.count
            }
            
            return 0
        }
        
        switch section {
        case 0:
            return filteredTopEvents.count > 0 ? filteredTopEvents.count : 1
        case 1:
            return filteredLogEvents.count > 0 ? filteredLogEvents.count : 1
        default:
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == deviceFilterTable {
            if indexPath.section == 0 {
                guard let titleCell = tableView.dequeueReusableCell(withIdentifier: "titleCell") else {
                    return UITableViewCell()
                }
                
                return titleCell
            }
            
            guard let deviceCell = tableView.dequeueReusableCell(withIdentifier: "deviceCell") as? AmenitiesCell else {
                return UITableViewCell()
            }
            
            let device = locationsWithDevices[indexPath.section - 1].devices[indexPath.row]
            deviceCell.configure(
                option: device.nickname.isEmpty ? device.model : device.nickname,
                isSelected: deviceIds.contains(device.id)
            )
            
            return deviceCell
        }
        
        switch indexPath.section {
        case 0:
            if filteredTopEvents.count > 0 {
                if let alertCell = tableView.dequeueReusableCell(withIdentifier: "alertCell") as? AlertTableViewCell {
                    alertCell.configure(with: filteredTopEvents[indexPath.row])
                    return alertCell
                }
            } else if gettingEvents {
                return tableView.dequeueReusableCell(withIdentifier: "loadingAlertsCell", for: indexPath)
            } else {
                return tableView.dequeueReusableCell(withIdentifier: "noAlertsCell", for: indexPath)
            }
        case 1:
            if filteredLogEvents.count > 0 {
                if let alertLogCell = tableView.dequeueReusableCell(withIdentifier: "alertCell") as? AlertTableViewCell {
                    alertLogCell.configure(with: filteredLogEvents[indexPath.row], asLog: true)
                    return alertLogCell
                }
            } else if gettingEvents {
                return tableView.dequeueReusableCell(withIdentifier: "loadingAlertsCell", for: indexPath)
            } else {
                return tableView.dequeueReusableCell(withIdentifier: "noAlertsLogCell", for: indexPath)
            }
        default:
            return UITableViewCell()
        }
        
        return UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == deviceFilterTable {
            return indexPath.section == 0 ? 48 : kfilterCellHeight
        }
        
        switch indexPath.section {
        case 0:
            return filteredTopEvents.count > 0 ? 68 : 358
        case 1:
            return 68
        default:
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if tableView == deviceFilterTable {
            guard
                section != 0,
                let locationHeader = tableView.dequeueReusableCell(withIdentifier: "locationHeader"),
                let locationLabel = locationHeader.viewWithTag(1001) as? UILabel
            else { return nil }
            
            locationLabel.text = locationsWithDevices[section - 1].nickname.isEmpty ? locationsWithDevices[section - 1].address : locationsWithDevices[section - 1].nickname
            
            return locationHeader
        }
        
        switch section {
        case 0:
            guard let alertsHeader = tableView.dequeueReusableCell(withIdentifier: EventDeviceFilterHeaderCell.storyboardId) as?
                EventDeviceFilterHeaderCell else {
                return nil
            }
            
            alertsHeader.delegate = self
            
            var numberOfLocationsSelected = 0
            var selectedLocation: LocationModel?
            for location in locationsWithDevices {
                for deviceId in deviceIds {
                    if location.devices.contains(where: { $0.id == deviceId }) {
                        numberOfLocationsSelected += 1
                        selectedLocation = location
                        break
                    }
                }
                if numberOfLocationsSelected > 1 { break }
            }
            
            var title = "multiple_locations".localized
            var subtitle = "multiple_devices".localized
            
            if let location = selectedLocation, numberOfLocationsSelected == 1 {
                title = location.nickname.isEmpty ? location.address : location.nickname
                
                if deviceIds.count == 1 {
                    for device in location.devices where device.id == deviceIds[0] {
                        subtitle = device.nickname.isEmpty ? device.model : device.nickname
                        break
                    }
                }
            }
            
            alertsHeader.configure(title: title, subtitle: subtitle, enabled: isDeviceFilterEnabled)
            
            return alertsHeader
        case 1:
            guard let activityLogHeader = tableView.dequeueReusableCell(withIdentifier: EventTypeFilterHeaderCell.storyboardId) as?
                EventTypeFilterHeaderCell else {
                return nil
            }
            
            activityLogHeader.delegate = self
            activityLogHeader.configure(logCount: filteredLogEvents.count)
            
            return activityLogHeader
        default:
            return nil
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == deviceFilterTable {
            return (section == 0 ? 0 : kfilterCellHeight)
        }
        
        switch section {
        case 0:
            return 60
        case 1:
            return 60
        default:
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == deviceFilterTable {
            if indexPath.section != 0 {
                let locations = LocationsManager.shared.locations
                let locationIndex = indexPath.section - 1
                
                if locationIndex < locations.count && indexPath.row < locations[locationIndex].devices.count {
                    let device = locations[locationIndex].devices[indexPath.row]
                    
                    if deviceIds.contains(device.id) {
                        if deviceIds.count > 1 {
                            deviceIds.removeAll(where: { $0 == device.id })
                        } else {
                            return
                        }
                    } else {
                        deviceIds.append(device.id)
                    }
                }
                
                tableView.reloadData()
            }
        } else if tableView == alertsTable {
            if indexPath.section == 0 && indexPath.row >= filteredTopEvents.count {
                return
            }
            
            if indexPath.section != 0 && indexPath.row >= filteredLogEvents.count {
                return
            }   
            
            if let eventDetailVC = UIStoryboard(name: "Alerts", bundle: nil).instantiateViewController(withIdentifier: EventDetailViewController.storyboardId) as? EventDetailViewController {
                let event = indexPath.section == 0 ? filteredTopEvents[indexPath.row] : filteredLogEvents[indexPath.row]
                eventDetailVC.event = event
                eventDetailVC.allowsUserInteraction = indexPath.section == 0
                navigationController?.pushViewController(eventDetailVC, animated: true)
            }
        }
    }
    
    // MARK: - Scrollview delegate methods
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == alertsTable {
            if !gettingEvents && !allEventsFetched && scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.height {
                page += 1
                getEvents()
            }
        }
    }
    
    // MARK: - EventTypeFilterHeader delegate methods
    public func showEventTypeFilter(actualYOffset: CGFloat) {
        btnHideFilters.isHidden = !btnHideFilters.isHidden
        
        if typeFilterView.isHidden {
            var yOffset = alertsTable.frame.origin.y - alertsTable.contentOffset.y + actualYOffset
            if yOffset + typeFilterView.frame.height > alertsTable.frame.origin.y + alertsTable.frame.height - 5 {
                yOffset -= typeFilterView.frame.height + 60
            }
            
            typeFilterViewYAnchor.constant = yOffset
            typeFilterView.frame.origin.y = yOffset
            typeFilterView.isHidden = false
        } else {
            filterEvents()
        }
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.typeFilterView.alpha = self.typeFilterView.alpha == 0 ? 1 : 0
            },
            completion: { _ in
                if self.typeFilterView.alpha == 0 {
                    self.typeFilterView.isHidden = true
                }
            }
        )
    }
    
    // MARK: - EventDeviceFilterHeader delegate methods
    public func showEventDeviceFilter(actualYOffset: CGFloat) {
        btnHideFilters.isHidden = !btnHideFilters.isHidden
        
        if deviceFilterTable.isHidden {
            var height: CGFloat = 48 + 12 // Header height plus bottom margin
            for location in locationsWithDevices {
                height += kfilterCellHeight + (CGFloat(location.devices.count) * kfilterCellHeight)
            }
            
            deviceFilterTableHeight.constant = height
            let yOffset = alertsTable.frame.origin.y - alertsTable.contentOffset.y + actualYOffset
            deviceFilterTableYAnchor.constant = yOffset
            deviceFilterTable.frame.origin.y = yOffset
            
            deviceFilterTable.layoutIfNeeded()
            deviceFilterTable.reloadData()
            deviceFilterTable.isHidden = false
        } else {
            getEvents(fromBeginning: true)
        }
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                self.deviceFilterTable.alpha = self.deviceFilterTable.alpha == 0 ? 1 : 0
            },
            completion: { _ in
                if self.deviceFilterTable.alpha == 0 {
                    self.deviceFilterTable.isHidden = true
                }
            }
        )
    }
    
    // MARK: - Overrides
    override var hidesBottomBarWhenPushed: Bool {
        get { return self.navigationController?.viewControllers.count ?? 1 > 1 }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
}
