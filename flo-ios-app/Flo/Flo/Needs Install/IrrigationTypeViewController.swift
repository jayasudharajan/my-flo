//
//  IrrigationTypeViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 17/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class IrrigationTypeViewController: FloBaseViewController {
    
    public var device: DeviceModel!
    public var prvSelectedOptionKey: String?

    fileprivate let kCellHeight: CGFloat = 64
    fileprivate var irrigationOptions: [IrrigationType] = []
    fileprivate var irrigationTypeSelected: IrrigationType?
    
    @IBOutlet fileprivate weak var hintLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var nextBtn: UIButton!

    @IBAction fileprivate func doneAction() {
        showLoadingSpinner("loading".localized())
        
        let data: [String: AnyObject] = [
            "prvInstallation": prvSelectedOptionKey as AnyObject,
            "irrigationType": irrigationTypeSelected?.id as AnyObject
        ]

        FloApiRequest(
            controller: "v2/devices/\(device.id)",
            method: .post,
            queryString: nil,
            data: data,
            done: { (error, _) in
                self.hideLoadingSpinner()
                if let err = error {
                    self.showPopup(error: err)
                } else {
                    self.device.isInstalledAndConfigured = true
                    self.goToRoot()
                }
            }
        ).secureFloRequest()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        hintLabel.text = "installation_on_irrigation_line_q".localized(args: [device.nickname])
        
        self.irrigationOptions = ListsManager.shared.getIrrigationTypes({(error, types) in
            if let err = error {
                self.showPopup(error: err)
            } else {
                self.irrigationOptions = types
                self.tableViewHeight.constant = CGFloat(self.irrigationOptions.count) * self.kCellHeight
                self.tableView.reloadData()
            }
        })
        
        self.tableViewHeight.constant = CGFloat(self.irrigationOptions.count) * self.kCellHeight
        self.tableView.reloadData()
    }
}

extension IrrigationTypeViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return irrigationOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let irrigationTypeCell = tableView.dequeueReusableCell(withIdentifier: FloOptionButtonCell.storyboardId) as? FloOptionButtonCell {
            irrigationTypeCell.configure(name: irrigationOptions[indexPath.row].name,
                                         selected: irrigationTypeSelected?.id == irrigationOptions[indexPath.row].id) {
                                            self.nextBtn.alpha = 1
                                            self.nextBtn.isEnabled = true
                                            self.irrigationTypeSelected = self.irrigationOptions[indexPath.row]
                                            self.tableView.reloadData()
            }
            return irrigationTypeCell
        }

        return UITableViewCell()
    }
}
