//
//  LocationAmenitiesViewController.swift
//  Flo
//
//  Created by Matias Paillet on 6/14/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class LocationAmenitiesViewController: BaseAddLocationStepViewController, UITableViewDataSource,
UITableViewDelegate, AmenitiesCellDelegate {
    
    fileprivate let kCellHeight: CGFloat = 43.5
    fileprivate let kHeaderHeight: CGFloat = 14 * 2
    
    @IBOutlet fileprivate weak var tableIndoors: UITableView!
    @IBOutlet fileprivate weak var tableOutdoors: UITableView!
    @IBOutlet fileprivate weak var tablePlumbing: UITableView!
    @IBOutlet fileprivate weak var indoorsTableViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var outdoorsTableViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var appliancesTableViewHeight: NSLayoutConstraint!
    
    fileprivate var indoorsAmenities: [BaseListModel] = []
    fileprivate var outdoorsAmenities: [BaseListModel] = []
    fileprivate var plumbingAmenities: [BaseListModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.tableIndoors.layer.cornerRadius = 10
        self.tableOutdoors.layer.cornerRadius = 10
        self.tablePlumbing.layer.cornerRadius = 10
        
        let appliances = ListsManager.shared.getAppliances({ (error, types) in
            if let err = error {
                self.showPopup(error: err)
            } else {
                self.indoorsAmenities = types.first?.indoor ?? []
                self.outdoorsAmenities = types.first?.outdoors ?? []
                self.plumbingAmenities = types.first?.appliances ?? []
                self.refreshTableViewsHeights()
            }
        })
        
        self.indoorsAmenities = appliances.first?.indoor ?? []
        self.outdoorsAmenities = appliances.first?.outdoors ?? []
        self.plumbingAmenities = appliances.first?.appliances ?? []
        self.refreshTableViewsHeights()
    }
    
    fileprivate func refreshTableViewsHeights() {
        self.indoorsTableViewHeight.constant = CGFloat(self.indoorsAmenities.count) * self.kCellHeight + self.kHeaderHeight
        self.tableIndoors.reloadData()
        
        self.outdoorsTableViewHeight.constant = CGFloat(self.outdoorsAmenities.count) * self.kCellHeight + self.kHeaderHeight
        self.tableOutdoors.reloadData()
        
        self.appliancesTableViewHeight.constant = CGFloat(self.plumbingAmenities.count) * self.kCellHeight + self.kHeaderHeight
        self.tablePlumbing.reloadData()
    }
    
    // MARK: UITableViewDataSource
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case tableIndoors:
            return indoorsAmenities.count
        case tableOutdoors:
            return outdoorsAmenities.count
        case tablePlumbing:
            return plumbingAmenities.count
        default:
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AmenitiesCell") as? AmenitiesCell else {
            return UITableViewCell()
        }
        
        cell.delegate = self
        switch tableView {
        case tableIndoors:
            let amenity = indoorsAmenities[indexPath.row]
            cell.configure(amenity, isSelected: AddLocationBuilder.shared.indoorAmenities.contains(amenity.id), group: "indoors")
        case tableOutdoors:
            let amenity = outdoorsAmenities[indexPath.row]
            cell.configure(amenity, isSelected: AddLocationBuilder.shared.outdoorAmenities.contains(amenity.id), group: "outdoors")
        case tablePlumbing:
            let amenity = plumbingAmenities[indexPath.row]
            cell.configure(amenity, isSelected: AddLocationBuilder.shared.plumbingAppliances.contains(amenity.id), group: "plumbing")
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 14))
        headerView.backgroundColor = UIColor.white
        return headerView
    }
    
    // MARK: AmenitiesCellDelegate
    
    public func didChangeAmenity(selected: Bool, amenity: BaseListModel, forGroup: String) {
        switch forGroup {
        case "indoors":
            if !selected {
                AddLocationBuilder.shared.indoorAmenities.removeAll(where: { $0 == amenity.id })
            } else {
                AddLocationBuilder.shared.indoorAmenities.append(amenity.id)
            }
        case "outdoors":
            if !selected {
                AddLocationBuilder.shared.outdoorAmenities.removeAll(where: { $0 == amenity.id })
            } else {
                AddLocationBuilder.shared.outdoorAmenities.append(amenity.id)
            }
        case "plumbing":
            if !selected {
                AddLocationBuilder.shared.plumbingAppliances.removeAll(where: { $0 == amenity.id })
            } else {
                AddLocationBuilder.shared.plumbingAppliances.append(amenity.id)
            }
        default:
            break
        }
    }
    
    // MARK: Actions
    
    @IBAction public func goNext() {
        let storyboard = UIStoryboard(name: "Locations", bundle: nil)
        let nextStep = storyboard.instantiateViewController(withIdentifier: LocationNumberOfPeopleViewController.storyboardId)
        self.navigationController?.pushViewController(nextStep, animated: true)
    }
}
