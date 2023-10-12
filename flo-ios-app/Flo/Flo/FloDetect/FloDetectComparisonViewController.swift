//
//  FloDetectComparisonViewController.swift
//  Flo
//
//  Created by Juan Pablo on 10/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal protocol FloDetectComparisonViewControllerDelegate: class {
    func finishedLoading(
        computations: [FixturesComputationModel],
        todayTotalComputationStatus: ComputationStatus,
        weekTotalComputationStatus: ComputationStatus
    )
}

internal class FloDetectComparisonViewController: CollapsableCardViewController, FloDetectChartCellDelegate {
    
    override var height: CGFloat {
        let computation = rangeSelector.selectedIndex == 0 ? todayTotalComputation : weekTotalComputation
        var cellsTotalHeight = computation.status == .executed ? 0 : kInfoCellHeight
        cellsTotalHeight += CGFloat(computation.fixtures.count >= 3 && isCollapsable ? 3 : computation.fixtures.count) * kFixtureCellHeight
        let contentHeight = comparisonTypeButton.isSelected ? kChartCellHeight : cellsTotalHeight
        
        return isCollapsed ? collapsedHeightValue :
            collapsedHeightValue +
            headerHeight.constant +
            footerHeight.constant +
            contentHeight
    }
    
    fileprivate var collapsedHeightValue: CGFloat {
        return collapsedHeight.constant + 20
    }
    
    public weak var loadingDelegate: FloDetectComparisonViewControllerDelegate?
    fileprivate var location: LocationModel?
    fileprivate var todayComputations: [FixturesComputationModel] = []
    fileprivate var weekComputations: [FixturesComputationModel] = []
    
    fileprivate let kFixtureCellHeight: CGFloat = 80
    fileprivate let kChartCellHeight: CGFloat = 474
    fileprivate let kInfoCellHeight: CGFloat = 96
    fileprivate var isLoadingData = false
    fileprivate let loadingSemaphore = DispatchSemaphore(value: 1)
    fileprivate var todayTotalComputation = FixturesComputationModel(range: .daily, status: .noUsage)
    fileprivate var weekTotalComputation = FixturesComputationModel(range: .weekly, status: .noUsage)
    public var isCollapsable = true
    
    @IBOutlet fileprivate weak var comparisonTypeButton: UIButton!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var rightLabel: UILabel!
    @IBOutlet fileprivate weak var rightImage: UIImageView!
    @IBOutlet fileprivate weak var rangeSelector: FloSelector!
    
    @IBOutlet fileprivate weak var headerHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var collapsedHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var footerHeight: NSLayoutConstraint!
    
    @IBOutlet fileprivate weak var computationDateLabel: UILabel!
    @IBOutlet fileprivate weak var footerButton: UIButton!
    
    @IBAction fileprivate func comparisonTypeAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            rightLabel.text = "List"
            rightImage.image = UIImage(named: "flo-detect-list")
        } else {
            rightLabel.text = "Chart"
            rightImage.image = UIImage(named: "flo-detect-chart")
        }
        
        tableView.reloadData()
        delegate?.cardHasResized(self)
    }
    
    @IBAction fileprivate func footerAction(_ sender: UIButton) {
        if let floDetect = UIStoryboard(name: "FloDetect", bundle: nil).instantiateInitialViewController() as? FloDetectFixtureViewController {
            floDetect.location = location
            navigationController?.pushViewController(floDetect, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rangeSelector.setStyle(.secondary)
        rangeSelector.setOptions(["last_24h".localized, "last_7d".localized])
        rangeSelector.selectOptionWithoutTriggers(0)
        rangeSelector.delegate = self
        
        if isCollapsable {
            computationDateLabel.isHidden = true
        } else {
            collapsedHeight.constant = 0
            footerHeight.constant = 12
            footerButton.isHidden = true
        }
        
        footerButton.backgroundColor = UIColor(hex: "F5F8FA")
        footerButton.layer.borderWidth = 1
        footerButton.layer.borderColor = UIColor(hex: "EBEFF5").cgColor
        footerButton.layer.cornerRadius = 20
        footerButton.layer.shadowRadius = 6
        footerButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        footerButton.layer.shadowOpacity = 0.1
        footerButton.layer.shadowColor = StyleHelper.colors.darkBlue.cgColor
        
        tableView.reloadData()
    }
    
    // MARK: - Overrides
    override func updateWith(locationInfo: LocationModel) {
        location = locationInfo
        loadData()
    }
    
    // MARK: - Load data
    fileprivate func loadData() {
        loadingSemaphore.wait()
        if !isLoadingData {
            if location?.floProtect ?? false {
                todayTotalComputation = FixturesComputationModel(range: .daily, status: .noUsage)
                weekTotalComputation = FixturesComputationModel(range: .weekly, status: .noUsage)
                computationDateLabel.isHidden = isCollapsable
                tableView.reloadData()
                delegate?.cardHasResized(self)
                
                if let devices = location?.devices, !devices.isEmpty {
                    isLoadingData = true
                    loadingSemaphore.signal()
                    
                    getComputations(for: devices, range: .daily) {
                        if self.todayTotalComputation.status == .learning {
                            self.setPlaceholderData(range: .daily)
                        } else {
                            for i in 0 ..< self.todayTotalComputation.fixtures.count {
                                self.todayTotalComputation.fixtures[i].ratio /= Double(devices.count)
                            }
                        }
                        
                        self.getComputations(for: devices, range: .weekly, {
                            self.loadingSemaphore.wait()
                            self.isLoadingData = false
                            self.loadingSemaphore.signal()
                            
                            if self.weekTotalComputation.status == .learning {
                                self.setPlaceholderData(range: .weekly)
                            } else {
                                for i in 0 ..< self.weekTotalComputation.fixtures.count {
                                    self.weekTotalComputation.fixtures[i].ratio /= Double(devices.count)
                                }
                            }
                            
                            self.computationDateLabel.text = self.getComputationDate()
                            self.tableView.reloadData()
                            self.delegate?.cardHasResized(self)
                            self.loadingDelegate?.finishedLoading(
                                computations: self.todayComputations + self.weekComputations,
                                todayTotalComputationStatus: self.todayTotalComputation.status,
                                weekTotalComputationStatus: self.weekTotalComputation.status
                            )
                        })
                    }
                } else {
                    loadingSemaphore.signal()
                    tableView.reloadData()
                    delegate?.cardHasResized(self)
                    loadingDelegate?.finishedLoading(
                        computations: [],
                        todayTotalComputationStatus: .noUsage,
                        weekTotalComputationStatus: .noUsage
                    )
                }
            } else {
                loadingSemaphore.signal()
                todayTotalComputation = FixturesComputationModel(range: .daily, status: .notSubscribed)
                setPlaceholderData(range: .daily)
                weekTotalComputation = FixturesComputationModel(range: .weekly, status: .notSubscribed)
                setPlaceholderData(range: .weekly)
                computationDateLabel.isHidden = true
                tableView.reloadData()
                delegate?.cardHasResized(self)
                loadingDelegate?.finishedLoading(
                    computations: [],
                    todayTotalComputationStatus: .notSubscribed,
                    weekTotalComputationStatus: .notSubscribed
                )
            }
        } else {
            loadingSemaphore.signal()
        }
    }
    
    fileprivate func getComputations(
        for devices: [DeviceModel],
        range: ConsumptionRange,
        _ callback: @escaping () -> Void
    ) {
        var remainingDevices = devices
        if let device = remainingDevices.popLast() {
            let query: [String: String] = [
                "macAddress": device.macAddress,
                "duration": (range == .daily ? "24h" : "7d")
            ]
            
            FloApiRequest(
                controller: "v2/flodetect/computations",
                method: .get,
                queryString: query,
                data: nil,
                done: { (_, data) in
                    if let d = data, let computation = FixturesComputationModel(d) {
                        range == .daily ? (self.todayComputations.append(computation)) : (self.weekComputations.append(computation))
                        
                        if computation.status == .executed {
                            var localFixtures = range == .daily ? self.todayTotalComputation.fixtures : self.weekTotalComputation.fixtures
                            
                            for fixture in computation.fixtures {
                                var isANewFixture = true
                                for i in 0 ..< localFixtures.count where fixture.type == localFixtures[i].type {
                                    isANewFixture = false
                                    localFixtures[i].consumption += fixture.consumption
                                    localFixtures[i].ratio += fixture.ratio
                                    break
                                }
                                if isANewFixture && fixture.consumption > 0 { localFixtures.append(fixture) }
                            }
                            
                            if range == .daily {
                                self.todayTotalComputation.fixtures = localFixtures
                                self.todayTotalComputation.status = .executed
                                self.todayTotalComputation.date = computation.date
                            } else {
                                self.weekTotalComputation.fixtures = localFixtures
                                self.weekTotalComputation.status = .executed
                                self.weekTotalComputation.date = computation.date
                            }
                        } else {
                            if range == .daily {
                                if self.todayTotalComputation.status != .executed && computation.status == .learning {
                                    self.todayTotalComputation.status = computation.status
                                }
                                self.todayTotalComputation.date = computation.date
                            } else {
                                if self.weekTotalComputation.status != .executed && computation.status == .learning {
                                    self.weekTotalComputation.status = computation.status
                                }
                                self.weekTotalComputation.date = computation.date
                            }
                        }
                    }
                    
                    self.getComputations(for: remainingDevices, range: range, callback)
                }
            ).secureFloRequest()
        } else {
            if range == .daily {
                self.todayTotalComputation.fixtures.sort { (f1, f2) -> Bool in
                    return f1.consumption > f2.consumption
                }
            } else {
                self.weekTotalComputation.fixtures.sort { (f1, f2) -> Bool in
                    return f1.consumption > f2.consumption
                }
            }
            callback()
        }
    }
    
    fileprivate func setPlaceholderData(range: ConsumptionRange) {
        var fixtures: [FixtureModel] = []
        
        let minConsumption: Double = range == .daily ? 1 : 90
        let maxConsumption: Double = range == .daily ? 80 : 270
        var totalConsumption: Double = 0
        
        var randomConsumption = Double.random(in: minConsumption ..< maxConsumption)
        totalConsumption += randomConsumption
        fixtures.append(FixtureModel(gallons: randomConsumption, type: .toilet))
        
        randomConsumption = Double.random(in: minConsumption ..< maxConsumption)
        totalConsumption += randomConsumption
        fixtures.append(FixtureModel(gallons: randomConsumption, type: .shower))
        
        randomConsumption = Double.random(in: minConsumption ..< maxConsumption)
        totalConsumption += randomConsumption
        fixtures.append(FixtureModel(gallons: randomConsumption, type: .faucet))
        
        randomConsumption = Double.random(in: minConsumption ..< maxConsumption)
        totalConsumption += randomConsumption
        fixtures.append(FixtureModel(gallons: randomConsumption, type: .appliance))
        
        randomConsumption = Double.random(in: minConsumption ..< maxConsumption)
        totalConsumption += randomConsumption
        fixtures.append(FixtureModel(gallons: randomConsumption, type: .pool))
        
        randomConsumption = Double.random(in: minConsumption ..< maxConsumption)
        totalConsumption += randomConsumption
        fixtures.append(FixtureModel(gallons: randomConsumption, type: .irrigation))
        
        for i in 0 ..< fixtures.count {
            fixtures[i].ratio = fixtures[i].consumption / totalConsumption
        }
        fixtures.sort { (f1, f2) -> Bool in
            return f1.consumption > f2.consumption
        }
        
        if range == .daily {
            todayTotalComputation.fixtures = fixtures
        } else {
            weekTotalComputation.fixtures = fixtures
        }
        computationDateLabel.text = getComputationDate()
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    func addFloDetect() {
        if let location = location {
            let storyboard = UIStoryboard(name: "FloProtect", bundle: nil)
            if let floProtectVC = storyboard.instantiateViewController(withIdentifier: FloProtectViewController.storyboardId) as? FloProtectViewController {
                floProtectVC.location = location
                navigationController?.pushViewController(floProtectVC, animated: true)
            }
        }
    }
    
    // MARK: - Computation date
    fileprivate func getComputationDate() -> String {
        let computation = rangeSelector.selectedIndex == 0 ? todayTotalComputation : weekTotalComputation
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        dateFormatter.dateFormat = "MMMM d "
        var dateString = dateFormatter.string(from: computation.date) + "at".localized
        dateFormatter.dateFormat = " h:mm a"
        dateString += dateFormatter.string(from: computation.date).lowercased()
        
        return "last_calculation_on".localized + " " + dateString
    }
}

extension FloDetectComparisonViewController: FloSelectorProtocol {
    
    func valueDidChange(selectedIndex: Int) {
        if comparisonTypeButton.isSelected {
            let computation = selectedIndex == 0 ? todayTotalComputation : weekTotalComputation
            var total: Double = 0
            
            if computation.status == .executed || computation.status == .notSubscribed {
                for fixture in computation.fixtures {
                    total += fixture.consumption
                }
            }
        }
        computationDateLabel.text = getComputationDate()
        
        tableView.reloadData()
        delegate?.cardHasResized(self)
    }
}

extension FloDetectComparisonViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let computation = rangeSelector.selectedIndex == 0 ? todayTotalComputation : weekTotalComputation
        var cellCount = computation.status == .executed ? 0 : 1
        cellCount += computation.fixtures.count >= 3 && isCollapsable ? 3 : computation.fixtures.count
        
        return comparisonTypeButton.isSelected ? 1 : cellCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let computation = rangeSelector.selectedIndex == 0 ? todayTotalComputation : weekTotalComputation
        let cellHeight = computation.status != .executed && indexPath.row == 0 ? kInfoCellHeight : kFixtureCellHeight
        
        return comparisonTypeButton.isSelected ? kChartCellHeight : cellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let computation = rangeSelector.selectedIndex == 0 ? todayTotalComputation : weekTotalComputation
        
        if comparisonTypeButton.isSelected {
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: FloDetectComparisonChartTableViewCell.storyboardId,
                for: indexPath
            ) as? FloDetectComparisonChartTableViewCell {
                cell.configure(computation: computation, delegate: self)
                
                return cell
            }
        } else {
            if computation.status != .executed && indexPath.row == 0 {
                if let cell = tableView.dequeueReusableCell(
                    withIdentifier: FloDetectComparisonInfoTableViewCell.storyboardId,
                    for: indexPath
                ) as? FloDetectComparisonInfoTableViewCell {
                    cell.configure(computation.status)
                    
                    return cell
                }
            } else {
                if let cell = tableView.dequeueReusableCell(
                    withIdentifier: FloDetectComparisonListTableViewCell.storyboardId,
                    for: indexPath
                ) as? FloDetectComparisonListTableViewCell {
                    let realIndex = computation.status == .executed ? indexPath.row : indexPath.row - 1
                    if realIndex < computation.fixtures.count {
                        cell.configure(computation.fixtures[realIndex], status: computation.status)
                    }   
                    
                    return cell
                }
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !(location?.floProtect ?? false) && !comparisonTypeButton.isSelected && indexPath.row == 0 {
            addFloDetect()
        }
    }
}
