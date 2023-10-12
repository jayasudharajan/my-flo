//
//  IrrigationSettingsViewController.swift
//  Flo
//
//  Created by Matias Paillet on 10/18/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class IrrigationSettingsViewController: FloBaseViewController {
    
    public var device: DeviceModel!
    public var prvSelectedOptionKey: String?

    fileprivate let kTablesVerticalMargins: CGFloat = 8 + 8
    fileprivate let kCellHeight: CGFloat = 45
    fileprivate var irrigationOptions: [IrrigationType] = []
    fileprivate var irrigationTypeSelected: IrrigationType?
    
    @IBOutlet fileprivate weak var nicknameLabel: UILabel!
    @IBOutlet fileprivate weak var hintLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var tableViewHeight: NSLayoutConstraint!
    
    override public func shouldHideNavBar() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithBack(andTitle: "irrigation".localized, tint: StyleHelper.colors.white, titleColor: StyleHelper.colors.white)
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nicknameLabel.text = device.nickname
        hintLabel.text = "installation_on_irrigation_line_q".localized(args: [device.nickname])
        
        self.irrigationOptions = ListsManager.shared.getIrrigationTypes({(error, types) in
            if let err = error {
                self.showPopup(error: err)
            } else {
                self.irrigationOptions = types
                self.tableViewHeight.constant = CGFloat(self.irrigationOptions.count) * self.kCellHeight + self.kTablesVerticalMargins
                self.tableView.reloadData()
            }
        })
        
        self.tableViewHeight.constant = CGFloat(self.irrigationOptions.count) * self.kCellHeight + self.kTablesVerticalMargins
        self.tableView.reloadData()
    }
}

extension IrrigationSettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return irrigationOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let radioButtonOptionCell = tableView.dequeueReusableCell(withIdentifier: RadioButtonOptionTableViewCell.storyboardId) as? RadioButtonOptionTableViewCell {
            radioButtonOptionCell.configure(
                option: irrigationOptions[indexPath.row].name,
                selected: device?.irrigationType == irrigationOptions[indexPath.row].id
            )
            
            return radioButtonOptionCell
        }
        
        return UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }

    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let deviceId = device?.id {
            let data: [String: AnyObject] = ["irrigationType": irrigationOptions[indexPath.row].id as AnyObject]

            showLoadingSpinner("loading".localized)
            FloApiRequest(
                controller: "v2/devices/\(deviceId)",
                method: .post,
                queryString: nil,
                data: data,
                done: { (error, _ ) in
                    self.hideLoadingSpinner()
                    if let e = error {
                        self.showPopup(error: e)
                    } else {
                        self.device?.irrigationType = self.irrigationOptions[indexPath.row].id
                        tableView.reloadData()
                    }
                }
            ).secureFloRequest()
        }
    }
}
