//
//  WaterUsageCardViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 30/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import SwiftyJSON
import GaugeKit

internal class WaterUsageCardViewController: CollapsableCardViewController, FloSelectorProtocol, UITableViewDelegate, UITableViewDataSource {
    
    override var height: CGFloat {
        let devicesAmount = location?.devices.count ?? 0
        return isCollapsed ? kCollapsedHeight : (devicesAmount > 1 ? 640 : 600)
    }
    
    fileprivate var location: LocationModel?
    fileprivate var devices: [String] = []
    
    fileprivate var consumptionRange = ConsumptionRange.daily
    fileprivate var dayTotalConsumption: [String: Double] = [:]
    fileprivate var deviceDayConsumptions: [String: [ConsumptionTimestamp]] = [:]
    fileprivate var dayConsumptionRects: [CGRect] = []
    fileprivate var hourByHourConsumptions: [ConsumptionTimestamp] = []
    fileprivate var weekTotalConsumption: [String: Double] = [:]
    fileprivate var deviceWeekConsumptions: [String: [ConsumptionTimestamp]] = [:]
    fileprivate var weekConsumptionRects: [CGRect] = []
    fileprivate var monthTotalConsumption: [String: Double] = [:]
    fileprivate var dayByDayConsumptions: [ConsumptionTimestamp] = []
    
    fileprivate var tooltip: FloTooltip?
    
    fileprivate var dailyAverage: [String: Double] = [:]
    fileprivate var weeklyAverage: [String: Double] = [:]
    fileprivate var monthlyAverage: [String: Double] = [:]
    
    @IBOutlet fileprivate weak var devicesFilterButton: UIButton!
    @IBOutlet fileprivate weak var devicesFilterContainerView: UIView!
    @IBOutlet fileprivate weak var devicesFilterBackgroundView: UIView!
    @IBOutlet fileprivate weak var devicesFilterView: UIView!
    @IBOutlet fileprivate weak var devicesFilterTableView: UITableView!
    @IBOutlet fileprivate weak var devicesFilterTableHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var rangeSelector: FloSelector!
    @IBOutlet fileprivate weak var consumptionView: UIView!
    @IBOutlet fileprivate weak var amountLabel: UILabel!
    @IBOutlet fileprivate weak var amountSpentLabel: UILabel!
    @IBOutlet fileprivate var consumptionGauges: [Gauge]!
    @IBOutlet fileprivate weak var amountAwayFromGoalLabel: UILabel!
    @IBOutlet fileprivate weak var awayFromGoalLabel: UILabel!
    @IBOutlet fileprivate weak var goalView: UIView!
    @IBOutlet fileprivate weak var averageIndicatorImageView: UIImageView!
    @IBOutlet fileprivate weak var averageAmountLabel: UILabel!
    @IBOutlet fileprivate weak var averageUpDownLabel: UILabel!
    @IBOutlet fileprivate weak var monthConsumptionView: UIView!
    @IBOutlet fileprivate weak var amountSpentMonthLabel: UILabel!
    @IBOutlet fileprivate weak var monthAverageImageView: UIImageView!
    @IBOutlet fileprivate weak var monthAverageLabel: UILabel!
    @IBOutlet fileprivate weak var dayGraphView: UIView!
    @IBOutlet fileprivate weak var dayBarsView: UIView!
    @IBOutlet fileprivate weak var weekGraphView: UIView!
    @IBOutlet fileprivate weak var weekBarsView: UIView!
    
    @IBAction fileprivate func filterButtonAction() {
        devicesFilterContainerView.isHidden = !devicesFilterContainerView.isHidden
        devicesFilterButton.setImage(
            devicesFilterContainerView.isHidden ? UIImage(named: "arrow-down-black") : UIImage(named: "arrow-up-black"),
            for: .normal
        )
        
        if devicesFilterContainerView.isHidden {
            if devices.count == (location?.devices.count ?? 0) {
                devicesFilterButton.setTitle("summary".localized + " ", for: .normal)
            } else if devices.count > 1 {
                devicesFilterButton.setTitle("multiple_".localized + " ", for: .normal)
            } else {
                for device in location?.devices ?? [] where device.macAddress == devices[0] {
                    devicesFilterButton.setTitle(device.nickname + " ", for: .normal)
                    break
                }
            }
            
            refreshConsumptionUI()
            createBars()
            
            for macAddress in devices {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(onUpdate(_:)),
                    name: DeviceModel.statusUpdateNotificationName(with: macAddress),
                    object: nil
                )
            }
        } else {
            devicesFilterTableView.reloadData()
        }
    }
    
    @IBAction fileprivate func openGoalsAction() {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        
        if let vc = storyboard.instantiateViewController(
            withIdentifier: GoalsSettingsViewController.storyboardId) as? GoalsSettingsViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    override func resizeAction(_ sender: UIButton) {
        super.resizeAction(sender)
        
        monthConsumptionView.isHidden = isCollapsed
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = "water_usage".localized
        
        rangeSelector.setStyle(.secondary)
        rangeSelector.setOptions(["today".localized, "week".localized])
        rangeSelector.selectOptionWithoutTriggers(0)
        rangeSelector.delegate = self
        
        devicesFilterButton.setTitle("summary".localized + " ", for: .normal)
        devicesFilterBackgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(filterButtonAction)))
        
        devicesFilterView.layer.cornerRadius = 8
        devicesFilterView.layer.shadowColor = StyleHelper.colors.blue.cgColor
        devicesFilterView.layer.shadowRadius = 8
        devicesFilterView.layer.shadowOpacity = 0.2
        devicesFilterView.layer.shadowOffset = CGSize(width: 0, height: 8)
        devicesFilterView.layer.borderColor = UIColor(hex: "EBEFF5").cgColor
        devicesFilterView.layer.borderWidth = 1
        
        consumptionView.layer.cornerRadius = consumptionView.frame.height / 2
        consumptionView.layer.shadowColor = StyleHelper.colors.blue.cgColor
        consumptionView.layer.shadowRadius = 16
        consumptionView.layer.shadowOpacity = 0.2
        consumptionView.layer.shadowOffset = CGSize(width: 0, height: 16)
        
        goalView.layer.cornerRadius = goalView.frame.height / 2
        goalView.layer.shadowColor = StyleHelper.colors.blue.cgColor
        goalView.layer.shadowRadius = 8
        goalView.layer.shadowOpacity = 0.2
        goalView.layer.shadowOffset = CGSize(width: 0, height: 8)
        goalView.layer.borderColor = UIColor(hex: "EBEFF5").cgColor
        goalView.layer.borderWidth = 1
        
        setupGauge()
        
        monthConsumptionView.layer.cornerRadius = 8
        monthConsumptionView.layer.shadowColor = StyleHelper.colors.blue.cgColor
        monthConsumptionView.layer.shadowRadius = 8
        monthConsumptionView.layer.shadowOpacity = 0.2
        monthConsumptionView.layer.shadowOffset = CGSize(width: 0, height: 8)
        monthConsumptionView.layer.borderColor = UIColor(hex: "EBEFF5").cgColor
        monthConsumptionView.layer.borderWidth = 1
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        amountSpentLabel.text = MeasuresHelper.getMeasureSystem() == .imperial ? "gallons_spent".localized : "liters_spent".localized
        
        for location in LocationsManager.shared.locations where location.id == self.location?.id {
            self.location = location
            break
        }
        
        configureDevicesFilter()
        refreshConsumptionUI()
        createBars()
        registerToDevicesUpdates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Overrides
    override func updateWith(locationInfo: LocationModel) {
        location = locationInfo
        
        devicesFilterButton.isHidden = locationInfo.devices.count <= 1
        devicesFilterButton.isEnabled = locationInfo.devices.count > 1
        
        NotificationCenter.default.removeObserver(self)
        
        var coincidences = 0
        for macAddress in devices {
            for device in locationInfo.devices where macAddress == device.macAddress {
                coincidences += 1
                break
            }
        }
        if coincidences != locationInfo.devices.count || devices.count != locationInfo.devices.count {
            devices = []
            for device in locationInfo.devices {
                devices.append(device.macAddress)
            }
            devicesFilterTableHeight.constant = CGFloat(44 * devices.count)
            configureDevicesFilter()
            refreshConsumptionUI()
            delegate?.cardHasResized(self)
        }
        
        refreshData()
    }
    
    // MARK: - Realtime updates
    @objc func onUpdate(_ notification: Notification) {
        if let status = DeviceStatus(notification.userInfo as AnyObject) {
            if devices.contains(status.macAddress), let consumptionToday = status.consumptionToday {
                dayTotalConsumption[status.macAddress] = consumptionToday
                
                refreshConsumptionUI()
            }
        }
    }
    
    fileprivate func registerToDevicesUpdates() {
        NotificationCenter.default.removeObserver(self)
        for macAddress in devices {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(onUpdate(_:)),
                name: DeviceModel.statusUpdateNotificationName(with: macAddress),
                object: nil
            )
        }
    }
    
    fileprivate func configureDevicesFilter() {
        if devices.count <= 1 {
            devicesFilterButton.setImage(nil, for: .normal)
            devicesFilterButton.isEnabled = false
        } else {
            devicesFilterButton.isEnabled = true
            devicesFilterButton.setImage(
                devicesFilterContainerView.isHidden ? UIImage(named: "arrow-down-black") : UIImage(named: "arrow-up-black"),
                for: .normal)
        }
    }
    
    // MARK: - Load API data
    fileprivate func refreshData() {
        deviceDayConsumptions = [:]
        dayTotalConsumption = [:]
        dailyAverage = [:]
        deviceWeekConsumptions = [:]
        weekTotalConsumption = [:]
        weeklyAverage = [:]
        monthTotalConsumption = [:]
        monthlyAverage = [:]
        
        getConsumptions(devices) {
            self.getAverages(self.devices) {
                self.refreshConsumptionUI()
                self.createBars()
                self.registerToDevicesUpdates()
            }
        }
    }
    
    // MARK: - FloSelector methods
    public func valueDidChange(selectedIndex: Int) {
        consumptionRange = ConsumptionRange(rawValue: selectedIndex) ?? .daily
        
        refreshConsumptionUI()
    }
    
    // MARK: - Refresh UI
    fileprivate func refreshConsumptionUI() {
        dayGraphView.isHidden = consumptionRange == .weekly
        weekGraphView.isHidden = consumptionRange == .daily
        
        var total: Double = 0
        var average: Double = 0
        let averageConsumption = consumptionRange == .daily ? dailyAverage : weeklyAverage
        for macAddress in devices {
            total += dayTotalConsumption[macAddress] ?? 0
            average += averageConsumption[macAddress] ?? 0
        }
        var monthConsumption = total // Then we add the other days' calculations
        
        if consumptionRange == .weekly {
            for macAddress in devices {
                total += weekTotalConsumption[macAddress] ?? 0
            }
        }
        
        self.amountLabel.text = String(format: "%.0f", MeasuresHelper.adjust(total, ofType: .volume).rounded(.toNearestOrAwayFromZero))
        self.refreshGauge()
        
        let unitAbbreviation = MeasuresHelper.unitAbbreviation(for: .volume)
        let goal = (location?.gallonsPerDayGoal ?? 0) * (consumptionRange == .daily ? 1 : 7)
        
        let remainingAmount = abs(goal - total)
        amountAwayFromGoalLabel.text = String(format: "%.0f \(unitAbbreviation).", MeasuresHelper.adjust(remainingAmount, ofType: .volume).rounded(.toNearestOrAwayFromZero))
        awayFromGoalLabel.text = goal > total ? "remaining_for_goal".localized : "over_the_goal".localized
        
        // Daily/Week averages
        let difference = abs(average - total)
        averageIndicatorImageView.image = total < average ? UIImage(named: "arrow-down-green") : UIImage(named: "arrow-up-red")
        averageAmountLabel.text = String(format: "%.0f \(unitAbbreviation).", MeasuresHelper.adjust(difference, ofType: .volume).rounded(.toNearestOrAwayFromZero))
        if total < 0.99 * average {
            averageUpDownLabel.text = "below_average".localized
        } else if total > 1.01 * average {
            averageUpDownLabel.text = "above_average".localized
        } else {
            averageUpDownLabel.text = "about_average".localized
        }
        
        // Month values
        var monthAverage: Double = 0
        for macAddress in devices {
            monthConsumption += monthTotalConsumption[macAddress] ?? 0
            monthAverage += monthlyAverage[macAddress] ?? 0
        }
        amountSpentMonthLabel.text = String(format: "%.0f \(unitAbbreviation).", MeasuresHelper.adjust(monthConsumption, ofType: .volume).rounded(.toNearestOrAwayFromZero))
        var averageStatus = ""
        if monthConsumption < 0.99 * monthAverage {
            averageStatus = "below_average".localized
        } else if monthConsumption > 1.01 * monthAverage {
            averageStatus = "above_average".localized
        } else {
            averageStatus = "about_average".localized
        }
        let monthRemainingAmount = abs(monthAverage - monthConsumption)
        monthAverageImageView.image = monthConsumption < monthAverage ? UIImage(named: "arrow-down-green") : UIImage(named: "arrow-up-red")
        monthAverageLabel.text = String(format: "%.0f \(unitAbbreviation). \(averageStatus).", MeasuresHelper.adjust(monthRemainingAmount, ofType: .volume).rounded(.toNearestOrAwayFromZero))
    }
    
    // MARK: - Consumption gauge
    fileprivate func setupGauge() {
        let rotations: [CGFloat] = [-0.75, -0.75, -0.5, -0.25, 0, 0.1875, 0.375, 0.5625]
        for i in 0 ..< consumptionGauges.count where i < rotations.count {
            consumptionGauges[i].transform = CGAffineTransform.identity.rotated(by: .pi * rotations[i])
        }
    }
    
    fileprivate func refreshGauge() {
        let goal = (location?.gallonsPerDayGoal ?? 0) * (consumptionRange == .daily ? 1 : 7)
        let maxScaledAmount: Double = 60
        let portions: [Double] = [1, 1/6, 1/6, 1/6, 1/8, 1/8, 1/8, 1/8]
        
        var total: Double = 0
        for macAddress in devices {
            total += dayTotalConsumption[macAddress] ?? 0
        }
        if consumptionRange == .weekly {
            for macAddress in devices {
                total += weekTotalConsumption[macAddress] ?? 0
            }
        }
        if total > goal { total = goal }
        
        var partialConsumption: Double = 0
        for i in 1 ..< consumptionGauges.count {
            var rate: Double = 0
            if total >= partialConsumption + (goal * portions[i]) {
                rate = maxScaledAmount * portions[i]
            } else if total > partialConsumption {
                rate = ((total - partialConsumption) * maxScaledAmount) / goal
            }
            
            partialConsumption += goal * portions[i]
            consumptionGauges[i].rate = CGFloat(rate)
        }
    }
    
    // MARK: - Consumptions
    fileprivate func getConsumptions(_ devices: [String], _ callback: @escaping () -> Void) {
        var remainingDevices = devices
        if let device = remainingDevices.popLast() {
            getConsumptions(for: device, .daily) { dailyConsumptionTimestamps in
                self.deviceDayConsumptions[device] = dailyConsumptionTimestamps
                self.getConsumptions(for: device, .weekly) { weeklyConsumptionTimestamps in
                    self.deviceWeekConsumptions[device] = weeklyConsumptionTimestamps
                    self.getConsumptions(for: device, .monthly) { _ in
                        self.getConsumptions(remainingDevices, callback)
                    }
                }
            }
        } else {
            callback()
        }
    }
    
    fileprivate func getConsumptions(
        for macAddress: String,
        _ range: ConsumptionRange,
        callback: @escaping ([ConsumptionTimestamp]) -> Void
    ) {
        var query: [String: String] = [
            "macAddress": macAddress
        ]
        
        var startDate = Date().addingTimeInterval(Date().localTimeIntervalFrom00hs() * -1)
        var endDate = Date()
        
        switch range {
        case .daily:
            query["interval"] = "1h"
        case .weekly:
            query["interval"] = "1d"
            startDate = Date().get(a: .saturday, searching: .backward, includingToday: true)
            endDate = Date().addingTimeInterval((Date().localTimeIntervalFrom00hs() * -1) - 1)
        case .monthly:
            query["interval"] = "1d"
            startDate = Date().firstDayOfMonthFromNow()
            endDate = Date().addingTimeInterval((Date().localTimeIntervalFrom00hs() * -1) - 1)
        }
        
        endDate = startDate >= endDate ? startDate.addingTimeInterval(1) : endDate
        query["startDate"] = startDate.toString()
        query["endDate"] = endDate.toString()
        
        FloApiRequest(
            controller: "v2/water/consumption",
            method: .get,
            queryString: query,
            data: nil,
            done: { (error, data) in
                if let e = error {
                    LoggerHelper.log(e.message, level: .error)
                    callback([])
                } else {
                    let dict = data as? NSDictionary ?? [:]
                    let aggregationDict = dict["aggregations"] as? NSDictionary ?? [:]
                    let total = aggregationDict["sumTotalGallonsConsumed"] as? Double ?? 0
                    
                    switch range {
                    case .daily:
                        self.dayTotalConsumption[macAddress] = total
                    case .weekly:
                        self.weekTotalConsumption[macAddress] = total
                    case .monthly:
                        self.monthTotalConsumption[macAddress] = total
                    }
                    
                    callback(ConsumptionTimestamp.array(dict["items"] as? [Any]))
                }
            }
        ).secureFloRequest()
    }
    
    // MARK: - Graphs methods
    fileprivate func createBars() {
        // Day consumption
        hourByHourConsumptions = []
        var maxConsumption: Double = 0
        let todayConsumption = ConsumptionTimestamp(date: Date(), amount: 0)
        for macAddress in devices {
            if let consumptions = deviceDayConsumptions[macAddress] {
                if hourByHourConsumptions.isEmpty {
                    hourByHourConsumptions = consumptions
                } else {
                    for i in 0 ..< hourByHourConsumptions.count where i < consumptions.count {
                        hourByHourConsumptions[i].amount += consumptions[i].amount
                    }
                }
            }
        }
        for consumption in hourByHourConsumptions {
            todayConsumption.amount += consumption.amount
            
            if consumption.amount > maxConsumption {
                maxConsumption = consumption.amount
            }
        }
        
        var separation = dayBarsView.frame.width / 72
        var maxHeight = dayBarsView.frame.height
        var width = (dayBarsView.frame.width - (separation * 23)) / 24
        var xOffset: CGFloat = 0
        
        dayConsumptionRects = []
        for consumption in hourByHourConsumptions {
            if dayConsumptionRects.count == 24 { break }
            
            let height = maxConsumption == 0 ? 0 : (CGFloat(consumption.amount) * maxHeight) / CGFloat(maxConsumption)
            let rect = CGRect(x: xOffset, y: maxHeight - height, width: width, height: height)
            
            dayConsumptionRects.append(rect)
            xOffset += width + separation
        }
        
        // Week consumption
        dayByDayConsumptions = []
        maxConsumption = 0
        for macAddress in devices {
            if let consumptions = deviceWeekConsumptions[macAddress] {
                if dayByDayConsumptions.isEmpty {
                    dayByDayConsumptions = consumptions
                } else {
                    for i in 0 ..< dayByDayConsumptions.count where i < consumptions.count {
                        dayByDayConsumptions[i].amount += consumptions[i].amount
                    }
                }
            }
        }
        dayByDayConsumptions.append(todayConsumption)
        for consumption in dayByDayConsumptions where consumption.amount > maxConsumption {
            maxConsumption = consumption.amount
        }
        
        separation = weekBarsView.frame.width / 14
        maxHeight = weekBarsView.frame.height
        width = (weekBarsView.frame.width - (separation * 7)) / 7
        xOffset = separation / 2
        
        weekConsumptionRects = []
        for consumption in dayByDayConsumptions {
            if weekConsumptionRects.count == 7 { break }
            
            let height = maxConsumption == 0 ? 0 : (CGFloat(consumption.amount) * maxHeight) / CGFloat(maxConsumption)
            let rect = CGRect(x: xOffset, y: maxHeight - height, width: width, height: height)
            
            weekConsumptionRects.append(rect)
            xOffset += width + separation
        }
        
        // Draw everything
        drawBars()
    }
    
    fileprivate func drawBars(color: UIColor = StyleHelper.colors.blue) {
        for bar in dayBarsView.subviews {
            bar.removeFromSuperview()
        }
        for i in 0 ..< dayConsumptionRects.count {
            let bar = UIControl(frame: dayConsumptionRects[i])
            bar.tag = i
            bar.backgroundColor = color
            bar.layer.cornerRadius = 3
            bar.addTarget(self, action: #selector(barTooltip(_:)), for: .touchUpInside)
            dayBarsView.addSubview(bar)
        }
        
        for bar in weekBarsView.subviews {
            bar.removeFromSuperview()
        }
        for i in 0 ..< weekConsumptionRects.count {
            let bar = UIControl(frame: weekConsumptionRects[i])
            bar.tag = i
            bar.backgroundColor = color
            bar.layer.cornerRadius = 3
            bar.addTarget(self, action: #selector(barTooltip(_:)), for: .touchUpInside)
            weekBarsView.addSubview(bar)
        }
    }
    
    @objc fileprivate func barTooltip(_ sender: UIControl) {
        tooltip?.dismiss()
        
        let consumptions = consumptionRange == .daily ? hourByHourConsumptions : dayByDayConsumptions
        if sender.tag < consumptions.count {
            let dateFormatter = DateFormatter()
            let date = consumptions[sender.tag].date
            let amount = MeasuresHelper.adjust(consumptions[sender.tag].amount, ofType: .volume)
            var tooltipText = ""
            
            if consumptionRange == .daily {
                dateFormatter.dateFormat = "h"
                tooltipText = dateFormatter.string(from: date) + "-"
                dateFormatter.dateFormat = "ha "
                tooltipText += dateFormatter.string(from: date.addingTimeInterval(3600))
            } else {
                dateFormatter.dateFormat = "EEEE "
                tooltipText = dateFormatter.string(from: date)
            }
            
            tooltipText += String(format: "%.0f", amount) + " " + MeasuresHelper.unitAbbreviation(for: .volume) + "."
            tooltip = FloTooltip(create: .data, saying: tooltipText)
            tooltip?.show(over: sender)
        }
    }
    
    // MARK: - Averages
    fileprivate func getAverages(_ devices: [String], _ callback: @escaping () -> Void) {
        var remainingDevices = devices
        if let device = remainingDevices.popLast() {
            getAverages(for: device) {
                self.getAverages(remainingDevices, callback)
            }
        } else {
            callback()
        }
    }
    
    fileprivate func getAverages(
        for macAddress: String,
        callback: @escaping () -> Void
    ) {
        FloApiRequest(
            controller: "v2/water/averages",
            method: .get,
            queryString: ["macAddress": macAddress],
            data: nil,
            done: { (error, data) in
                if let e = error {
                    LoggerHelper.log(e.message, level: .error)
                    callback()
                } else {
                    let dict = data as? NSDictionary ?? [:]
                    let aggregationDict = dict["aggregations"] as? NSDictionary ?? [:]
                    let dailyAvgDict = aggregationDict["dayOfWeekAvg"] as? NSDictionary ?? [:]
                    let weeklyAvgDict = aggregationDict["prevCalendarWeekDailyAvg"] as? NSDictionary ?? [:]
                    let monthlyAvgDict = aggregationDict["monthlyAvg"] as? NSDictionary ?? [:]
                    
                    self.dailyAverage[macAddress] = dailyAvgDict["value"] as? Double ?? 0
                    self.weeklyAverage[macAddress] = weeklyAvgDict["value"] as? Double ?? 0
                    self.monthlyAverage[macAddress] = monthlyAvgDict["value"] as? Double ?? 0
                    
                    callback()
                }
            }
        ).secureFloRequest()
    }
    
    // MARK: - Tableview protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return location?.devices.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FilterDeviceCell", for: indexPath)
        
        for subview in cell.contentView.subviews {
            if let label = subview as? UILabel {
                label.text = location?.devices[indexPath.row].nickname
            } else if let imageView = subview as? UIImageView {
                let isOnFilter = devices.contains(location?.devices[indexPath.row].macAddress ?? "")
                imageView.isHidden = !isOnFilter
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath), let macAddress = location?.devices[indexPath.row].macAddress {
            var deviceIndex: Int?
            for i in 0 ..< devices.count where macAddress == devices[i] {
                deviceIndex = i
                break
            }
            
            if let i = deviceIndex {
                if devices.count == 1 { return }
                devices.remove(at: i)
            } else {
                devices.append(macAddress)
            }
            
            registerToDevicesUpdates()
            
            for subview in cell.contentView.subviews {
                if let imageView = subview as? UIImageView {
                    imageView.isHidden = deviceIndex != nil
                }
            }
        }
    }
}

private class ConsumptionTimestamp: JsonParsingProtocol {
    
    public let date: Date
    public var amount: Double
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        guard
            let timestamp = json["time"].string,
            let date = Date.iso8601ToDate(timestamp),
            let amount = json["gallonsConsumed"].double
        else {
            LoggerHelper.log("Error parsing ConsumptionTimestamp", level: .error)
            return nil
        }
        
        self.date = date
        self.amount = amount
    }
    
    init(date: Date, amount: Double) {
        self.date = date
        self.amount = amount
    }
    
    public class func array(_ objects: [Any]?) -> [ConsumptionTimestamp] {
        var consumptionTimestamps: [ConsumptionTimestamp] = []
        
        for object in objects ?? [] {
            if let consumptionTimestamp = ConsumptionTimestamp(object as AnyObject) {
                consumptionTimestamps.append(consumptionTimestamp)
            }
        }
        
        return consumptionTimestamps
    }
}
