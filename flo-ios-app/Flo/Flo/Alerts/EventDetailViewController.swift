//
//  EventDetailViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 20/08/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class EventDetailViewController: EventBaseViewController {
    
    fileprivate var timer: Timer?
    
    @IBOutlet fileprivate weak var iconImageView: UIImageView!
    @IBOutlet fileprivate weak var locationDeviceLabel: UILabel!
    @IBOutlet fileprivate weak var timestampLabel: UILabel!
    @IBOutlet fileprivate weak var descriptionLabel: UILabel!
    
    @IBOutlet fileprivate weak var troubleshootButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var eventTitle = ""
        let severity = event.alert?.severity ?? .info
        
        switch severity {
        case .critical:
            eventTitle = "critical_alert".localized
        case .warning:
            eventTitle = "warning_alert".localized
        case .info:
            eventTitle = "informative_alert".localized
            troubleshootButton.isHidden = true
        }
        
        setupNavBarWithBack(andTitle: eventTitle, tint: StyleHelper.colors.white, titleColor: StyleHelper.colors.white)
        
        if allowsUserInteraction {
            troubleshootButton.layer.cornerRadius = troubleshootButton.frame.height / 2
            troubleshootButton.layer.addGradient(from: StyleHelper.colors.cyan, to: StyleHelper.colors.darkCyan, angle: 90)
        } else {
            troubleshootButton.isHidden = true
        }
        
        iconImageView.image = severity.icon
        
        let locationLabel = (event.location?.nickname ?? "").isEmpty ? event.location?.address : event.location?.nickname
        let deviceLabel = (event.device?.nickname ?? "").isEmpty ? event.device?.model : event.device?.nickname
        locationDeviceLabel.text = (locationLabel ?? "?") + ", " + (deviceLabel ?? "?")
        timestampLabel.text = event.createdAt.getRelativeTimeSinceNow()
        descriptionLabel.text = event.displayMessage
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        timer = nil
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let alertTroubleshootVC = segue.destination as? EventTroubleshootViewController {
            alertTroubleshootVC.event = event
            alertTroubleshootVC.allowsUserInteraction = allowsUserInteraction
        }
    }
    
    // MARK: - Timestamp refreshing methods
    fileprivate func configureTimer() {
        timer?.invalidate()
        timer = nil
        
        if needsDateRefreshing() {
            timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        }
    }
    
    @objc fileprivate func tick() {
        if needsDateRefreshing() {
            DispatchQueue.main.async {
                self.timestampLabel.text = self.event.createdAt.getRelativeTimeSinceNow()
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    fileprivate func needsDateRefreshing() -> Bool {
        let units = Set<Calendar.Component>([.year, .month, .day, .hour, .minute, .second])
        let components = Calendar.current.dateComponents(units, from: event.createdAt, to: Date())
        
        guard
            let year = components.year,
            let month = components.month,
            let day = components.day,
            let hour = components.hour,
            let minute = components.minute,
            let second = components.second
        else { return false }
        
        if year > 0 || month > 0 || day > 0 || hour > 0 || minute > 5 {
            return false
        } else if minute == 5 {
            return second < 5
        } else {
            return true
        }
    }

}
