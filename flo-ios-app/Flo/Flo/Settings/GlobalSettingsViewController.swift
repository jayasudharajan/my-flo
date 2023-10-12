//
//  GlobalSettingsViewController.swift
//  Flo
//
//  Created by Josefina Perez on 15/08/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class GlobalSettingsViewController: FloBaseViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet fileprivate weak var locationsTableHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var lblUserName: UILabel!
    @IBOutlet fileprivate weak var imperialCheckMark: UIImageView!
    @IBOutlet fileprivate weak var metricCheckMark: UIImageView!
    @IBOutlet fileprivate weak var btnImperial: UIButton!
    @IBOutlet fileprivate weak var btnMetric: UIButton!
    @IBOutlet fileprivate weak var lblLanguage: UILabel!
    @IBOutlet fileprivate weak var lblAppVersion: UILabel!
    @IBOutlet fileprivate weak var locationsTable: UITableView!
    
    fileprivate let kLocationCellHeight: CGFloat = 58
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        setupNavBar(with: "settings".localized)
        fillWithInformation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        locationsTable.reloadData()
        locationsTableHeight.constant = kLocationCellHeight +
            kLocationCellHeight * CGFloat(LocationsManager.shared.locations.count) + 10
    }
    
    fileprivate func fillWithInformation() {
        guard let user = UserSessionManager.shared.user else {
            return
        }
        
        lblUserName.text = "\(user.firstName) \(user.lastName)"
        lblLanguage.text = LanguageHelper.getCurrentLanguage().abbreviation.uppercased()
        lblAppVersion.text = "\(Bundle.main.versionNumber) - \(Bundle.main.buildNumber)"
        
        selectUnitSystem()
    }
    
    fileprivate func selectUnitSystem() {
        let unitSystem = MeasuresHelper.getMeasureSystem()
        
        imperialCheckMark.isHidden = unitSystem != .imperial
        metricCheckMark.isHidden = unitSystem != .metricKpa
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Table view protocol
    
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LocationsManager.shared.locations.count
    }
    
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let locationCell = tableView.dequeueReusableCell(withIdentifier: "locationCell")
            as? ConnectedDeviceTableViewCell else {
                return UITableViewCell()
        }
        
        locationCell.updateWith(location: LocationsManager.shared.locations[indexPath.row])
        return locationCell
    }
    
    internal func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kLocationCellHeight
    }
    
    internal func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return kLocationCellHeight
    }
    
    internal func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let locationFooter = tableView.dequeueReusableCell(withIdentifier: "locationFooter")
            as? ConnectWithNewDeviceTableViewCell else {
                return UITableViewCell()
        }
        
        return locationFooter
    }
    
    internal func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Settings", bundle: nil)
        guard let homeSettingsViewController =
            storyboard.instantiateViewController(withIdentifier: HomeSettingsViewController.storyboardId)
                as? HomeSettingsViewController else {
                    return
        }

        homeSettingsViewController.location = LocationsManager.shared.locations[indexPath.row]
        navigationController?.pushViewController(homeSettingsViewController, animated: true)
    }
    
    // MARK: - Actions
    @IBAction fileprivate func addLocation() {
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        if let controller = storyboard.instantiateViewController(
            withIdentifier: LocationTypeViewController.storyboardId) as? LocationTypeViewController {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    @IBAction fileprivate func updateUnitSystem(_ sender: UIButton) {
        
        if !FloApiRequest.demoModeEnabled() {
            
            guard let userId = UserSessionManager.shared.user?.id else {
                return
            }
            
            let unitSystem: MeasureSystem = sender == btnImperial ? .imperial : .metricKpa
            
            showLoadingSpinner("please_wait".localized)
            
            FloApiRequest(
                controller: "v2/users/\(userId)",
                method: .post,
                queryString: nil,
                data: ["unitSystem": unitSystem.rawValue as AnyObject],
                done: { (error, _ ) in
                    self.hideLoadingSpinner()
                    if let e = error {
                        self.showPopup(error: e)
                    } else {
                        MeasuresHelper.setMeasureSystem(unitSystem)
                        self.selectUnitSystem()
                    }
            }).secureFloRequest()
        } else {
            showFeatureNotSupportedInDemoModeAlert()
        }
    }

}
