//
//  PRVSettingsViewController.swift
//  Flo
//
//  Created by Matias Paillet on 10/18/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class PRVSettingsViewController: FloBaseViewController {

    fileprivate let kTablesVerticalMargins: CGFloat = 8 + 8
    fileprivate let kCellHeight: CGFloat = 45
    fileprivate var prvInstallationOptions: [PRVInstallationType] = []
    fileprivate var prvInstallationTypeSelected: PRVInstallationType?
    
    @IBOutlet fileprivate weak var nicknameLabel: UILabel!
    @IBOutlet fileprivate weak var tableView: UITableView!
    @IBOutlet fileprivate weak var tableViewHeight: NSLayoutConstraint!
    
    public var device: DeviceModel!
    
    override public func shouldHideNavBar() -> Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavBarWithBack(andTitle: "pressure_reducing_valve".localized, tint: StyleHelper.colors.white, titleColor: StyleHelper.colors.white)
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        nicknameLabel.text = device.nickname
        
        self.prvInstallationOptions = ListsManager.shared.getPRVInstallationTypes({(error, types) in
            if let err = error {
                self.showPopup(error: err)
            } else {
                self.prvInstallationOptions = types
                self.tableViewHeight.constant = CGFloat(self.prvInstallationOptions.count) * self.kCellHeight + self.kTablesVerticalMargins
                self.tableView.reloadData()
            }
        })
        
        self.tableViewHeight.constant = CGFloat(self.prvInstallationOptions.count) * self.kCellHeight + self.kTablesVerticalMargins
        self.tableView.reloadData()
    }
}

extension PRVSettingsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return prvInstallationOptions.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let radioButtonOptionCell = tableView.dequeueReusableCell(withIdentifier: RadioButtonOptionTableViewCell.storyboardId) as? RadioButtonOptionTableViewCell {
               radioButtonOptionCell.configure(
                   option: prvInstallationOptions[indexPath.row].name,
                   selected: device?.prvInstallation == prvInstallationOptions[indexPath.row].id
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
            let data: [String: AnyObject] = ["prvInstallation": prvInstallationOptions[indexPath.row].id as AnyObject]
            
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
                        self.device?.prvInstallation = self.prvInstallationOptions[indexPath.row].id
                        tableView.reloadData()
                    }
                }
            ).secureFloRequest()
        }
    }
}
