//
//  PressureReducingValveViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 17/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class PressureReducingValveViewController: FloBaseViewController {

    fileprivate let kCellHeight: CGFloat = 64
    fileprivate var prvInstallationOptions: [PRVInstallationType] = []
    fileprivate var prvInstallationTypeSelected: PRVInstallationType?
    
    @IBOutlet fileprivate weak var hintLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var nextBtn: UIButton!
    
    public var device: DeviceModel!
    
    @IBAction public func didPressOptionButton(_ button: FloOptionButton) {
        nextBtn.alpha = 1
        nextBtn.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hintLabel.text = "pressure_reducing_valve_q".localized(args: [device.nickname])
        
        self.prvInstallationOptions = ListsManager.shared.getPRVInstallationTypes({(error, types) in
            if let err = error {
                self.showPopup(error: err)
            } else {
                self.prvInstallationOptions = types
                self.tableViewHeight.constant = CGFloat(self.prvInstallationOptions.count) * self.kCellHeight
                self.tableView.reloadData()
            }
        })
        
        self.tableViewHeight.constant = CGFloat(self.prvInstallationOptions.count) * self.kCellHeight
        self.tableView.reloadData()
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let irrigationTypeVC = segue.destination as? IrrigationTypeViewController {
            irrigationTypeVC.device = device
            irrigationTypeVC.prvSelectedOptionKey = self.prvInstallationTypeSelected?.id
        }
    }

}

extension PressureReducingValveViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prvInstallationOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let irrigationTypeCell = tableView.dequeueReusableCell(withIdentifier: FloOptionButtonCell.storyboardId) as? FloOptionButtonCell {
            irrigationTypeCell.configure(
                name: prvInstallationOptions[indexPath.row].name,
                selected: prvInstallationTypeSelected?.id == prvInstallationOptions[indexPath.row].id) {
                    self.nextBtn.alpha = 1
                    self.nextBtn.isEnabled = true
                    self.prvInstallationTypeSelected = self.prvInstallationOptions[indexPath.row]
                    self.tableView.reloadData()
            }
            return irrigationTypeCell
        }

        return UITableViewCell()
    }
}
