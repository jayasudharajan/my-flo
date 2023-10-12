//
//  FloDetectFixtureViewController.swift
//  Flo
//
//  Created by Juan Pablo on 09/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class FloDetectFixtureViewController: FloBaseViewController, FloDetectComparisonViewControllerDelegate {
    
    fileprivate var currentlyDisplayedCards: [FloDetectCardInfoHolder] = []
    public var location: LocationModel?
    
    @IBOutlet fileprivate weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBarWithBack(
            andTitle: "fixtures".localized,
            tint: StyleHelper.colors.white,
            titleColor: StyleHelper.colors.white
        )
        
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        
        let comparisonCell = tableView.dequeueReusableCell(withIdentifier: CardTableViewCell.storyboardId)!
        if let comparisonController = FloDetectComparisonViewController.getInstance(storyboard: "FloDetect") as? FloDetectComparisonViewController {
            comparisonController.setDelegate(self)
            comparisonController.loadingDelegate = self
            comparisonController.isCollapsable = false
            addContentController(comparisonController, toView: comparisonCell.contentView)
            if location != nil {
                comparisonController.updateWith(locationInfo: location!)
            }
            currentlyDisplayedCards.append(FloDetectCardInfoHolder(cell: comparisonCell, controller: comparisonController))
        }
        
        if LocationsManager.shared.selectedLocation?.floProtect == true {
            let historyCell = tableView.dequeueReusableCell(withIdentifier: CardTableViewCell.storyboardId)!
            let historyController = FloDetectHistoryViewController.getInstance(storyboard: "FloDetect")
            (historyController as? CollapsableCardViewController)?.setDelegate(self)
            addContentController(historyController, toView: historyCell.contentView)
            currentlyDisplayedCards.append(FloDetectCardInfoHolder(cell: historyCell, controller: historyController))
        }

        tableView.reloadData()
    }
    
    // MARK: - FloDetect comparison delegate
    func finishedLoading(
        computations: [FixturesComputationModel],
        todayTotalComputationStatus: ComputationStatus,
        weekTotalComputationStatus: ComputationStatus
    ) {
        for card in currentlyDisplayedCards {
            if let historyController = card.controller as? FloDetectHistoryViewController {
                let filteredComputations = computations.filter { (computation) -> Bool in
                    return computation.status == .executed
                }
                historyController.setComputations(
                    filteredComputations,
                    todayStatus: todayTotalComputationStatus,
                    weekStatus: weekTotalComputationStatus
                )
            }
        }
    }
    
    // MARK: - Overrides
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
}

extension FloDetectFixtureViewController: UITableViewDataSource, UITableViewDelegate {
    
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

extension FloDetectFixtureViewController: CollapsableCardDelegate {
    
    func cardHasResized(_ cardViewController: CardViewController) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

internal class FloDetectCardInfoHolder {
    
    public var cell: UITableViewCell
    public var controller: CardViewController
    
    init(cell: UITableViewCell, controller: CardViewController) {
        self.cell = cell
        self.controller = controller
    }
}
