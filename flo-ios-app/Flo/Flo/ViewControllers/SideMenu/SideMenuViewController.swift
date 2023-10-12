//
//  SideMenuViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 06/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import SideMenu

internal class SideMenuViewController: FloBaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet fileprivate weak var containerView: UIView!
    @IBOutlet fileprivate weak var userDataLabel: UILabel!
    @IBOutlet fileprivate weak var locationsTableView: UITableView!
    @IBOutlet fileprivate weak var btnLogout: UIButton!
    
    @IBAction fileprivate func termsAndPrivacyAction() {
        let storyboard = UIStoryboard(name: "Registration", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: SignupTermsViewController.storyboardId)
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction fileprivate func logoutAction() {
        showLogoutPopup()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.layer.cornerRadius = 27
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let user = UserSessionManager.shared.user {
            userDataLabel.text = user.firstName + " " + user.lastName
        } else {
            userDataLabel.text = "demo_mode".localized
        }
        locationsTableView.reloadData()
        locationsTableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        
        btnLogout.setTitle(FloApiRequest.demoModeEnabled() ? "exit_demo_mode".localized : "log_out".localized, for: .normal)
    }
    
    // MARK: - TableView protocol methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = 1 // AddLocation cell always visible
        let amountOfLocations = LocationsManager.shared.locations.count
        
        numberOfRows += amountOfLocations == 0 ? 1 : amountOfLocations
        
        return numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let amountOfLocations = LocationsManager.shared.locations.count
        let locations: [LocationModel] = LocationsManager.shared.locations
        
        if indexPath.row == 0 {
            if amountOfLocations == 0 {
                if let cell = tableView.dequeueReusableCell(withIdentifier: "NoLocationsPlaceholder") {
                    return cell
                }
            } else {
                if let cell = tableView.dequeueReusableCell(withIdentifier: SelectedLocationTableViewCell.storyboardId) as? SelectedLocationTableViewCell {
                    cell.configure(locations[indexPath.row])
                    return cell
                }
            }
        } else if indexPath.row >= amountOfLocations {
            if let cell = tableView.dequeueReusableCell(withIdentifier: AddLocationTableViewCell.storyboardId) as? AddLocationTableViewCell {
                return cell
            }
        } else {
            if let cell = tableView.dequeueReusableCell(withIdentifier: UnselectedLocationTableViewCell.storyboardId) as? UnselectedLocationTableViewCell {
                cell.configure(locations[indexPath.row])
                return cell
            }
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let amountOfLocations = LocationsManager.shared.locations.count
        let kAddLocationCellHeight: CGFloat = 58
        let kSelectedLocationCellHeight: CGFloat = 196
        let kUnselectedLocationCellHeight: CGFloat = 132
        
        if indexPath.row == 0 {
            if amountOfLocations == 0 {
                return tableView.frame.height - kAddLocationCellHeight
            } else {
                return kSelectedLocationCellHeight
            }
        } else if indexPath.row >= amountOfLocations {
            return kAddLocationCellHeight
        } else {
            return kUnselectedLocationCellHeight
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let amountOfLocations = LocationsManager.shared.locations.count
        
        if indexPath.row > 0 {
            if indexPath.row >= amountOfLocations {
                self.goToAddHome()
            } else {
                UserSessionManager.shared.selectedLocationId = LocationsManager.shared.locations[indexPath.row].id
                
                if let dashboard = SideMenuManager.default.menuLeftNavigationController?.sideMenuDelegate as? DashboardViewController {
                    dashboard.refreshLocation()
                }
                
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: Navigation
    fileprivate func goToAddHome() {
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        if let controller = storyboard.instantiateViewController(
            withIdentifier: LocationTypeViewController.storyboardId) as? LocationTypeViewController {
            navigationController?.pushViewController(controller, animated: true)
        }
    }
    
    // MARK: - Logout
    fileprivate func showLogoutPopup() {
        showPopup(
            title: FloApiRequest.demoModeEnabled() ? "exit_demo_mode".localized : "log_out".localized,
            description: FloApiRequest.demoModeEnabled() ?
                "are_you_sure_you_want_to_exit_demo_mode_q".localized :
                "are_you_sure_you_want_to_log_out_of_flo_q".localized,
            acceptButtonText: "ok".localized,
            acceptButtonAction: {
                self.dismiss(animated: true, completion: {
                    self.logout()
                })
            },
            cancelButtonText: "cancel".localized
        )
    }
    
    fileprivate func logout() {
        showLoadingSpinner("please_wait".localized)
        
        let logoutUser = [
            "mobile_device_id": (UIDevice.current.identifierForVendor?.uuidString as AnyObject),
            "aws_endpoint_id": (AWSPinpointManager.shared.getCurrentEndpointId() as AnyObject)
        ]
        
        FloApiRequest(controller: "v1/logout", method: .post, queryString: nil, data: logoutUser, done: { (_, _) in
            self.hideLoadingSpinner()
            
            UserSessionManager.shared.logout()
            TrackingManager.shared.track(TrackingManager.kEventLogout)
            
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            if let login = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
                let navigation = UINavigationController(rootViewController: login)
                UIApplication.shared.switchRootViewController(navigation, animated: true)
            }
        }).secureFloRequest()
    }
    
}
