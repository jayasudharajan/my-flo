//
//  FloDetectHistoryViewController.swift
//  Flo
//
//  Created by Juan Pablo on 10/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class FloDetectHistoryViewController: CollapsableCardViewController {

    override var height: CGFloat {
        let expandableFixtures = rangeSelector.selectedIndex == 0 ? todayExpandableFixtures : weekExpandableFixtures
        
        var contentHeight: CGFloat = kInfoCellHeight
        if expandableFixtures.count > 0 {
            contentHeight = kTableViewHeaderHeight * CGFloat(expandableFixtures.count)
            for expandableFixture in expandableFixtures {
                contentHeight += kTableViewCellHeight * CGFloat(expandableFixture.expanded ? expandableFixture.fixtureUsages.count : 0)
            }
        }
        
        return 20 + headerHeight.constant + contentHeight
    }
    
    fileprivate let kTableViewHeaderHeight: CGFloat = 48
    fileprivate let kTableViewCellHeight: CGFloat = 36
    fileprivate let kInfoCellHeight: CGFloat = 96
    
    public var computations: [FixturesComputationModel] = []
    fileprivate var todayExpandableFixtures: [FixtureModelExpandable] = []
    fileprivate var todayStatus: ComputationStatus = .noUsage
    fileprivate var weekExpandableFixtures: [FixtureModelExpandable] = []
    fileprivate var weekStatus: ComputationStatus = .noUsage
    fileprivate let knownFixtureTypes = [FixtureType.shower, FixtureType.toilet, FixtureType.appliance, FixtureType.faucet, FixtureType.other, FixtureType.irrigation, FixtureType.pool]
    fileprivate let pageSize = 100
    fileprivate var isLoadingData = true
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var descLabel: UILabel!
    @IBOutlet fileprivate weak var rangeSelector: FloSelector!
    @IBOutlet fileprivate weak var headerHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var hintView: UIView!
    
    @IBAction fileprivate func hintButtonAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        hintView.isHidden = !sender.isSelected
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        descLabel.text = "usage_history".localized
        rangeSelector.setStyle(.secondary)
        rangeSelector.setOptions(["last_24h".localized, "last_7d".localized])
        rangeSelector.selectOptionWithoutTriggers(0)
        rangeSelector.delegate = self
    }
    
    public func setComputations(
        _ computations: [FixturesComputationModel], todayStatus: ComputationStatus, weekStatus: ComputationStatus) {
        self.computations = computations
        self.todayStatus = todayStatus
        self.weekStatus = weekStatus
        
        todayExpandableFixtures = []
        weekExpandableFixtures = []
        
        isLoadingData = true
        tableView.reloadData()
        delegate?.cardHasResized(self)
        
        getEvents(computations, startDate: Date()) { (todayExpandableFixtures, weekExpandableFixtures) in
            self.todayExpandableFixtures = todayExpandableFixtures
            self.weekExpandableFixtures = weekExpandableFixtures
            
            self.isLoadingData = false
            self.tableView.reloadData()
            self.delegate?.cardHasResized(self)
        }
    }
    
    // MARK: - Load data
    fileprivate func getEvents(
        _ computations: [FixturesComputationModel],
        startDate: Date,
        todayFixtureUsages: [FixtureUsageModel] = [],
        weekFixtureUsages: [FixtureUsageModel] = [],
        _ callback: @escaping ([FixtureModelExpandable], [FixtureModelExpandable]) -> Void
    ) {
        var remainingComputations = computations
        var query: [String: String] = ["size": "\(pageSize)", "order": "desc"]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        query["start"] = formatter.string(from: startDate)
        
        if let computation = remainingComputations.popLast() {
            FloApiRequest(
                controller: "v2/flodetect/computations/\(computation.id)/events",
                method: .get,
                queryString: query,
                data: nil,
                done: { (_, data) in
                    var todayNewFixtureUsages = todayFixtureUsages
                    var weekNewFixtureUsages = weekFixtureUsages
                    var date = Date()
                    
                    if let d = data as? NSDictionary, let list = d["items"] as? [Any] {
                        let fixtureUsages = FixtureUsageModel.array(list).sorted { (fixtureUsage1, fixtureUsage2) -> Bool in
                            return fixtureUsage1.startDate > fixtureUsage2.startDate
                        }
                        
                        computation.range == .daily ? todayNewFixtureUsages.append(contentsOf: fixtureUsages) : weekNewFixtureUsages.append(contentsOf: fixtureUsages)
                        
                        if fixtureUsages.count >= self.pageSize {
                            date = fixtureUsages.last?.startDate ?? Date()
                            remainingComputations.append(computation)
                        }
                    }
                    self.getEvents(
                        remainingComputations,
                        startDate: date,
                        todayFixtureUsages: todayNewFixtureUsages,
                        weekFixtureUsages: weekNewFixtureUsages,
                        callback
                    )
                }
            ).secureFloRequest()
        } else {
            callback(
                groupFixtureUsages(todayFixtureUsages),
                groupFixtureUsages(weekFixtureUsages)
            )
        }
    }
    
    fileprivate func groupFixtureUsages(_ fixtureUsages: [FixtureUsageModel]) -> [FixtureModelExpandable] {
        var expandableFixtures: [FixtureModelExpandable] = []
        
        for fixtureUsage in fixtureUsages.sorted(by: { (f1, f2) -> Bool in f1.startDate > f2.startDate }) {
            let count = expandableFixtures.count
            let correctType = fixtureUsage.feedback?.correctFixtureType ?? fixtureUsage.type
            if count > 0 && correctType == expandableFixtures[count - 1].type {
                expandableFixtures[count - 1].fixtureUsages.append(fixtureUsage)
            } else {
                expandableFixtures.append(FixtureModelExpandable(fixtureUsage))
            }
        }
        
        return expandableFixtures
    }
    
    fileprivate func regroupFixtureUsages(_ expandableFixtures: [FixtureModelExpandable]) -> [FixtureModelExpandable] {
        var fixtureUsages: [FixtureUsageModel] = []
        
        for expandableFixture in expandableFixtures {
            for fixtureUsage in expandableFixture.fixtureUsages {
                fixtureUsages.append(fixtureUsage)
            }
        }
        
        return groupFixtureUsages(fixtureUsages)
    }
    
    // MARK: - Feedback flow methods
    fileprivate func feedbackFlow(from indexPath: IndexPath) {
        let expandableFixtures = rangeSelector.selectedIndex == 0 ? todayExpandableFixtures : weekExpandableFixtures
        let fixtureUsage = expandableFixtures[indexPath.section].fixtureUsages[indexPath.row]
        let correctType = fixtureUsage.feedback?.correctFixtureType ?? fixtureUsage.type
        
        let options = [
            AlertPopupOption(title: "looks_good".localized, type: .normal, action: {
                var caseType: FeedbackCase = .correct
                if let feedback = fixtureUsage.feedback, feedback.correctFixtureType != fixtureUsage.type {
                    // We do this to prevent sending .correct when it's was already classified as another fixture type
                    caseType = feedback.caseType
                }
                
                let feedback = FixtureUsageFeedback(caseType: caseType, correctFixtureType: correctType)
                self.sendFeedback(feedback, for: indexPath)
            }),
            AlertPopupOption(title: "wrong_fixture".localized, type: .normal, action: {
                var options: [AlertPopupOption] = []
                for type in self.knownFixtureTypes where type != correctType {
                    options.append(AlertPopupOption(title: type.name, type: .normal, action: {
                        var caseType: FeedbackCase = fixtureUsage.type == .other ? .tagged : .wrong
                        if type == fixtureUsage.type {
                            // We do this to prevent sending .wrong or .tagged when a user resend a feedback
                            caseType = .correct
                        }
                        
                        let feedback = FixtureUsageFeedback(caseType: caseType, correctFixtureType: type)
                        self.sendFeedback(feedback, for: indexPath)
                    }))
                }
                options.append(AlertPopupOption(title: "cancel".localized, type: .cancel))
                
                self.showPopup(
                    title: "classify_fixture".localized,
                    description: "select_which_fixture_created_this_event".localized,
                    options: options
                )
            }),
            AlertPopupOption(title: "cancel".localized, type: .cancel)
        ]
        
        showPopup(
            title: "Confirm \(correctType.name)",
            description: "Flo predicted \(String(format: "%.1f", fixtureUsage.consumption)) \(MeasuresHelper.unitAbbreviation(for: .volume))(s) used from a \(correctType.name) between \(fixtureUsage.startDate.getDayHours()) – \(fixtureUsage.endDate.getDayHours()).",
            options: options
        )
    }
    
    fileprivate func sendFeedback(_ feedback: FixtureUsageFeedback, for indexPath: IndexPath) {
        showLoadingSpinner("loading".localized)
        
        let expandableFixtures = rangeSelector.selectedIndex == 0 ? todayExpandableFixtures : weekExpandableFixtures
        let fixtureUsage = expandableFixtures[indexPath.section].fixtureUsages[indexPath.row]
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        let dateString = formatter.string(from: fixtureUsage.startDate)
        
        FloApiRequest(
            controller: "v2/flodetect/computations/\(fixtureUsage.computationId)/events/\(dateString)",
            method: .post,
            queryString: nil,
            data: feedback.jsonData(),
            done: { (error, _) in
                self.hideLoadingSpinner()
                if let e = error {
                    self.showPopup(error: e)
                } else {
                    fixtureUsage.feedback = feedback
                    if self.rangeSelector.selectedIndex == 0 {
                        self.todayExpandableFixtures = self.regroupFixtureUsages(expandableFixtures)
                    } else {
                        self.weekExpandableFixtures = self.regroupFixtureUsages(expandableFixtures)
                    }
                    
                    self.tableView.reloadData()
                    self.delegate?.cardHasResized(self)
                }
            }
        ).secureFloRequest()
    }
}

extension FloDetectHistoryViewController: FloDetectHistoryHeaderDelegate {
    
    func headerSelected(section: Int) {
        if rangeSelector.selectedIndex == 0 {
            if section < todayExpandableFixtures.count {
                todayExpandableFixtures[section].expanded = !todayExpandableFixtures[section].expanded
            }
        } else {
            if section < weekExpandableFixtures.count {
                weekExpandableFixtures[section].expanded = !weekExpandableFixtures[section].expanded
            }
        }
        
        tableView.reloadData()
        delegate?.cardHasResized(self)
    }
}

extension FloDetectHistoryViewController: FloSelectorProtocol {
    
    func valueDidChange(selectedIndex: Int) {
        tableView.reloadData()
        delegate?.cardHasResized(self)
    }
}

extension FloDetectHistoryViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        let expandableFixtures = rangeSelector.selectedIndex == 0 ? todayExpandableFixtures : weekExpandableFixtures
        return expandableFixtures.count > 0 ? expandableFixtures.count : 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let expandableFixtures = rangeSelector.selectedIndex == 0 ? todayExpandableFixtures : weekExpandableFixtures
        return expandableFixtures.count > 0 ? kTableViewHeaderHeight : 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let expandableFixtures = rangeSelector.selectedIndex == 0 ? todayExpandableFixtures : weekExpandableFixtures
        
        if expandableFixtures.count > 0, let header = tableView.dequeueReusableCell(
            withIdentifier: FloDetectHistoryTableViewHeader.storyboardId
        ) as? FloDetectHistoryTableViewHeader {
            let expandableFixtures = rangeSelector.selectedIndex == 0 ? todayExpandableFixtures : weekExpandableFixtures
            header.configure(expandableFixtures[section], index: section, delegate: self)
            
            return header
        }
        
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let expandableFixtures = rangeSelector.selectedIndex == 0 ? todayExpandableFixtures : weekExpandableFixtures
        if expandableFixtures.count > 0 {
            return expandableFixtures[section].expanded ? expandableFixtures[section].fixtureUsages.count : 0
        }
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let expandableFixtures = rangeSelector.selectedIndex == 0 ? todayExpandableFixtures : weekExpandableFixtures
        return expandableFixtures.count > 0 ? kTableViewCellHeight : kInfoCellHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let expandableFixtures = rangeSelector.selectedIndex == 0 ? todayExpandableFixtures : weekExpandableFixtures
        let status = rangeSelector.selectedIndex == 0 ? todayStatus : weekStatus
        
        if expandableFixtures.count > 0 {
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: FloDetectHistoryTableViewCell.storyboardId,
                for: indexPath
            ) as? FloDetectHistoryTableViewCell {
                cell.configure(expandableFixtures[indexPath.section].fixtureUsages[indexPath.row])
                return cell
            }
        } else {
            if isLoadingData {
                let loadingCell = tableView.dequeueReusableCell(withIdentifier: "LoadingCell", for: indexPath)
                if let loader = loadingCell.viewWithTag(66) as? UIActivityIndicatorView {
                    loader.startAnimating()
                }
                return loadingCell
            }
            
            if let cell = tableView.dequeueReusableCell(
                withIdentifier: FloDetectComparisonInfoTableViewCell.storyboardId,
                for: indexPath
            ) as? FloDetectComparisonInfoTableViewCell {
                cell.configure(status)
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let expandableFixtures = rangeSelector.selectedIndex == 0 ? todayExpandableFixtures : weekExpandableFixtures
        if expandableFixtures.count > 0 {
            feedbackFlow(from: indexPath)
        }
    }
}

// MARK: - View Model
internal class FixtureModelExpandable {
    
    fileprivate(set) var consumption: Double
    public let type: FixtureType
    public var expanded: Bool
    public var fixtureUsages: [FixtureUsageModel]
    
    init(_ fixtureUsage: FixtureUsageModel) {
        consumption = fixtureUsage.consumption
        type = fixtureUsage.feedback?.correctFixtureType ?? fixtureUsage.type
        expanded = true
        fixtureUsages = [fixtureUsage]
    }
    
    init(_ fixtureUsages: [FixtureUsageModel]) {
        consumption = 0
        for fixtureUsage in fixtureUsages {
            consumption += fixtureUsage.consumption
        }
        type = fixtureUsages.first?.feedback?.correctFixtureType ?? fixtureUsages.first?.type ?? .other
        expanded = true
        self.fixtureUsages = fixtureUsages
    }
    
}
