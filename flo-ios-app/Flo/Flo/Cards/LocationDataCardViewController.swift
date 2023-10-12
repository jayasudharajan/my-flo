//
//  LocationDataCardViewController.swift
//  Flo
//
//  Created by Matias Paillet on 6/7/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal protocol SystemModeSelectorDelegate: class {
    func systemModeAction()
}

internal class LocationDataCardViewController: CardViewController, SystemModeSelectorDelegate {
    
    fileprivate var location: LocationModel?
    fileprivate var lastSystemMode: SystemMode?
    fileprivate var systemModeSelector: SystemModeSelectorViewController!
    
    override var height: CGFloat {
        return 50
    }
    
    @IBOutlet fileprivate weak var nameLabel: UILabel!
    @IBOutlet fileprivate weak var systemModeView: UIView!
    @IBOutlet fileprivate weak var systemModeButton: UIButton!
    @IBOutlet fileprivate weak var systemModeImageView: UIImageView!
    @IBOutlet fileprivate weak var systemModeArrowImageView: UIImageView!
    
    @IBAction public func systemModeAction() {
        systemModeButton.isSelected = !systemModeButton.isSelected
        systemModeButton.alpha = systemModeButton.isSelected ? 1 : 0.2
        systemModeImageView.tintColor = systemModeButton.isSelected ? StyleHelper.colors.blue : .white
        systemModeArrowImageView.tintColor = systemModeButton.isSelected ? StyleHelper.colors.blue : .white
        let imageName = systemModeButton.isSelected ? "arrow-up-black" : "arrow-down-black"
        systemModeArrowImageView.image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        
        if systemModeButton.isSelected {
            let topConstraintConstant = view.convert(
                systemModeView.frame.origin,
                to: UIApplication.shared.keyWindow?.rootViewController?.view
            ).y + systemModeView.frame.height + 8
            systemModeSelector.setTopConstraintConstant(topConstraintConstant)
            present(systemModeSelector, animated: true, completion: nil)
        } else {
            systemModeSelector.dismiss(animated: true, completion: nil)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear
        view.clipsToBounds = true
        
        systemModeSelector = SystemModeSelectorViewController.getInstance(delegate: self)
        systemModeView.layer.cornerRadius = 10
        systemModeArrowImageView.image = UIImage(named: "arrow-down-black")?.withRenderingMode(.alwaysTemplate)
    }
    
    override public func updateWith(locationInfo: LocationModel) {
        NotificationCenter.default.removeObserver(self)
        
        location = locationInfo
        nameLabel.text = locationInfo.nickname
        systemModeSelector.setLocation(locationInfo)
        
        if locationInfo.devices.isEmpty {
            systemModeView.isHidden = true
        } else {
            systemModeView.isHidden = false
            
            for device in locationInfo.devices {
                NotificationCenter.default.addObserver(self, selector: #selector(onUpdate(_:)), name: device.statusUpdateNotificationName, object: nil)
            }
            setupSystemModeSelector()
        }
    }
    
    // MARK: - Realtime updates
    @objc func onUpdate(_ notification: Notification) {
        setupSystemModeSelector()
    }
    
    // MARK: - System mode selector
    fileprivate func setupSystemModeSelector() {
        if let location = location, !location.devices.isEmpty {
            var systemModeEnabled = false
            for device in location.devices where !device.systemModeLocked && device.isConnected {
                systemModeEnabled = true
                break
            }
            
            if systemModeEnabled != systemModeButton.isEnabled {
                systemModeButton.isEnabled = systemModeEnabled
                systemModeView.alpha = systemModeEnabled ? 1 : 0.5
                
                if !systemModeButton.isEnabled && systemModeButton.isSelected {
                    systemModeAction()
                }
            }
            
            if location.systemMode != lastSystemMode {
                lastSystemMode = location.systemMode
                systemModeImageView.image = UIImage(named: location.systemMode.rawValue + "-mode-icon")?.withRenderingMode(.alwaysTemplate)
            }
        } else {
            systemModeView.isHidden = true
        }
    }
}

internal class SystemModeSelectorViewController: UIViewController {
    
    fileprivate weak var delegate: SystemModeSelectorDelegate?
    fileprivate var location: LocationModel?
    fileprivate var topConstraintConstant: CGFloat = 16
    fileprivate var lastSystemMode: SystemMode?
    fileprivate var systemModes: [SystemMode] = [.home, .away, .sleep]
    
    @IBOutlet fileprivate var topConstraint: NSLayoutConstraint!
    @IBOutlet fileprivate var containerView: UIView!
    @IBOutlet fileprivate var systemModeViews: [UIView]!
    
    @IBAction fileprivate func dismissAction() {
        delegate?.systemModeAction()
    }
    
    @IBAction fileprivate func systemModeAction(_ sender: UIButton) {
        if !sender.isSelected {
            updateSystemMode(to: systemModes[sender.superview?.tag ?? 0])
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = StyleHelper.colors.mainButtonInactive.cgColor
        
        let blurEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurEffectView.frame = containerView.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(blurEffectView)
        containerView.sendSubviewToBack(blurEffectView)
        
        for view in systemModeViews {
            view.layer.cornerRadius = 8
            view.layer.borderWidth = 1
            view.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        topConstraint.constant = topConstraintConstant
        updateSystemMode(to: location?.systemMode ?? .home, triggeringActions: false)
    }
    
    // MARK: - System mode selection methods
    fileprivate func updateSystemMode(to systemMode: SystemMode, triggeringActions: Bool = true) {
        for i in 0 ..< systemModes.count {
            if let button = systemModeViews[i].viewWithTag(6) as? UIButton, let selectedView = systemModeViews[i].viewWithTag(66) {
                let selected = systemModes[i] == systemMode
                systemModeViews[i].backgroundColor = selected ? .white : .clear
                systemModeViews[i].layer.borderColor = selected ? StyleHelper.colors.lightBlue.cgColor : UIColor.clear.cgColor
                button.isSelected = selected
                selectedView.isHidden = !selected
            }
        }
        
        if triggeringActions {
            switch systemMode {
            case .home:
                setMode(.home)
            case .away:
                showAwayPopup()
            case .sleep:
                showSleepPopup()
            }
        }
    }
    
    fileprivate func showSleepPopup() {
        let options = [
            AlertPopupOption(title: "sleep_2h".localized, action: { self.setMode(.sleep, sleepMinutes: 120) }),
            AlertPopupOption(title: "sleep_24h".localized, action: { self.setMode(.sleep, sleepMinutes: 1440) }),
            AlertPopupOption(title: "sleep_72h".localized, action: { self.setMode(.sleep, sleepMinutes: 4320) }),
            AlertPopupOption(title: "cancel".localized, type: .cancel, action: {
                self.updateSystemMode(to: self.location?.systemMode ?? .home, triggeringActions: false)
            })
        ]
        
        showPopup(
            title: "sleep_mode".localized,
            description: "sleep_mode_desc".localized,
            acceptButtonText: "confirm".localized,
            acceptButtonAction: {
                self.showPopup(
                    title: "sleep_mode".localized,
                    options: options
                )
            },
            cancelButtonText: "cancel".localized,
            cancelButtonAction: {
                self.updateSystemMode(to: self.location?.systemMode ?? .home, triggeringActions: false)
            }
        )
    }
    
    fileprivate func showAwayPopup() {
        let awayModeInputView = AlertPopupAwayModeHeader.getInstance()
        showPopup(
            title: "away_mode".localized,
            description: "away_mode_desc".localized,
            inputView: awayModeInputView,
            acceptButtonText: "enable_away_mode".localized,
            acceptButtonAction: {
                self.setAwayMode(irrigationStatus: awayModeInputView.getIrrigationStatus())
            },
            cancelButtonText: "cancel".localized,
            cancelButtonAction: {
                self.updateSystemMode(to: self.location?.systemMode ?? .home, triggeringActions: false)
            }
        )
    }
    
    fileprivate func setAwayMode(irrigationStatus: Bool?) {
        if let location = location {
            if let updatedIrrigationStatus = irrigationStatus {
                let irrigationData = ["isEnabled": updatedIrrigationStatus as AnyObject]
                let data = ["irrigationSchedule": irrigationData as AnyObject]
                FloApiRequest(
                    controller: "v2/locations/\(location.id)",
                    method: .post,
                    queryString: nil,
                    data: data,
                    done: { (error, _) in
                        if error != nil {
                            self.updateSystemMode(to: location.systemMode, triggeringActions: false)
                        } else {
                            self.setMode(.away)
                        }
                    }
                ).secureFloRequest()
            } else {
                self.setMode(.away)
            }
        }
    }
    
    fileprivate func setMode(_ mode: SystemMode, sleepMinutes: Int = 0) {
        var data = ["target": mode.rawValue as AnyObject]
        if mode == .sleep {
            data["revertMode"] = "home" as AnyObject
            data["revertMinutes"] = sleepMinutes as AnyObject
        }
        
        if let location = location {
            FloApiRequest(
                controller: "v2/locations/\(location.id)/systemMode",
                method: .post,
                queryString: nil,
                data: data,
                done: { (error, _) in
                    if let e = error, e.status != 409 {
                        self.updateSystemMode(to: location.systemMode, triggeringActions: false)
                    } else {
                        location.systemMode = mode
                        self.delegate?.systemModeAction()
                    }
                }
            ).secureFloRequest()
        }
    }
    
    // MARK: - Instantiation
    public class func getInstance(delegate: SystemModeSelectorDelegate) -> SystemModeSelectorViewController {
        let storyboard = UIStoryboard(name: "Cards", bundle: nil)
        
        if let systemModeSelectorVC = storyboard.instantiateViewController(withIdentifier: SystemModeSelectorViewController.storyboardId) as? SystemModeSelectorViewController {
            systemModeSelectorVC.delegate = delegate
            return systemModeSelectorVC
        }
        
        return SystemModeSelectorViewController()
    }
    
    public func setLocation(_ location: LocationModel?) {
        self.location = location
    }
    
    public func setTopConstraintConstant(_ topConstraintConstant: CGFloat) {
        self.topConstraintConstant = topConstraintConstant
    }
}
