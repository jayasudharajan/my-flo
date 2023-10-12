//
//  AlertTableViewCell.swift
//  Flo
//
//  Created by Josefina Perez on 13/08/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class AlertTableViewCell: UITableViewCell {
    
    fileprivate var timer: Timer?
    fileprivate var date: Date!
    
    @IBOutlet fileprivate weak var backView: UIView!
    @IBOutlet fileprivate weak var alertsStatusImageView: UIImageView!
    @IBOutlet fileprivate weak var lblAlertName: UILabel!
    @IBOutlet fileprivate weak var lblDeviceName: UILabel!
    @IBOutlet fileprivate weak var timeLabel: UILabel!
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    public func configure(with event: EventModel, asLog: Bool = false) {
        date = event.createdAt
        configureTimer()
        
        backView.layer.cornerRadius = 10
        alertsStatusImageView.image = event.alert?.severity.icon
        lblAlertName.text = event.displayTitle.isEmpty ? event.alert?.name : event.displayTitle
        lblDeviceName.text = (event.device?.nickname ?? event.device?.model)
        timeLabel.text = event.createdAt.getRelativeTimeSinceNow()
        
        for layer in backView.layer.sublayers ?? [] where layer is FloGradientLayer {
            layer.removeFromSuperlayer()
        }
        
        if asLog {
            backView.backgroundColor = StyleHelper.colors.transparency20
        } else if event.alert?.severity == .critical {
            backView.backgroundColor = StyleHelper.colors.red
        } else {
            backView.layer.addGradient(from: StyleHelper.colors.orange, to: StyleHelper.colors.darkOrange, angle: 270)
        }
    }
    
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
                self.timeLabel.text = self.date.getRelativeTimeSinceNow()
            }
        } else {
            timer?.invalidate()
            timer = nil
        }
    }
    
    fileprivate func needsDateRefreshing() -> Bool {
        let units = Set<Calendar.Component>([.year, .month, .day, .hour, .minute, .second])
        let components = Calendar.current.dateComponents(units, from: date, to: Date())
        
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
