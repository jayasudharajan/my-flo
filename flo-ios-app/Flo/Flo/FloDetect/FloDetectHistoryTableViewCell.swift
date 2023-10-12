//
//  FloDetectHistoryTableViewCell.swift
//  Flo
//
//  Created by Juan Pablo on 10/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class FloDetectHistoryTableViewCell: UITableViewCell {
    
    @IBOutlet fileprivate weak var feedbackView: UIView!
    @IBOutlet fileprivate weak var feedbackImageView: UIImageView!
    @IBOutlet fileprivate weak var wrongFixtureLabel: UILabel!
    @IBOutlet fileprivate weak var eventDateLabel: UILabel!
    @IBOutlet fileprivate weak var eventDurationLabel: UILabel!
    @IBOutlet fileprivate weak var eventConsumptionLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        feedbackView.layer.cornerRadius = feedbackView.frame.height / 2
    }
    
    public func configure(_ fixtureUsage: FixtureUsageModel) {
        if let feedback = fixtureUsage.feedback {
            feedbackView.backgroundColor = .white
            feedbackImageView.isHidden = false
            wrongFixtureLabel.isHidden = false
            
            if feedback.caseType == .correct {
                feedbackImageView.image = UIImage(named: "check-blue-icon")
                wrongFixtureLabel.text = ""
            } else {
                feedbackImageView.image = UIImage(named: "cross-blue-icon")
                wrongFixtureLabel.text = "(was " + fixtureUsage.type.name + ")"
            }
        } else {
            feedbackView.backgroundColor = UIColor(hex: "C3D3DE")
            feedbackImageView.isHidden = true
            wrongFixtureLabel.isHidden = true
            wrongFixtureLabel.text = ""
        }
        
        eventDateLabel.text = fixtureUsage.startDate.getDayHours()
        
        var interval = ""
        let hours = Int(fixtureUsage.duration / 3600)
        let minutes = Int(fixtureUsage.duration.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds = Int(fixtureUsage.duration.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            interval = "\(hours)h"
        }
        if minutes > 0 {
            interval += interval.isEmpty ? "" : " "
            interval += "\(minutes)" + "min".localized
        }
        if seconds > 0 && hours == 0 {
            interval += interval.isEmpty ? "" : " "
            interval += "\(seconds)" + "sec".localized
        }
        if interval.isEmpty {
            interval = "0" + "sec".localized
        }
        
        eventDurationLabel.text = interval
        eventConsumptionLabel.text = String(format: "%.1f \(MeasuresHelper.unitAbbreviation(for: .volume))", fixtureUsage.consumption)
    }
    
}

internal protocol FloDetectHistoryHeaderDelegate: class {
    func headerSelected(section: Int)
}

internal class FloDetectHistoryTableViewHeader: UITableViewCell {
    
    fileprivate weak var delegate: FloDetectHistoryHeaderDelegate?
    fileprivate var index = 0
    
    @IBOutlet fileprivate weak var fixtureImageView: UIImageView!
    @IBOutlet fileprivate weak var fixtureNameLabel: UILabel!
    @IBOutlet fileprivate weak var eventsAmountLabel: UILabel!
    @IBOutlet fileprivate weak var eventsConsumptionLabel: UILabel!
    @IBOutlet fileprivate weak var arrowImageView: UIImageView!
    
    @IBAction fileprivate func tapAction() {
        delegate?.headerSelected(section: index)
    }
    
    public func configure(_ fixture: FixtureModelExpandable, index: Int, delegate: FloDetectHistoryHeaderDelegate) {
        self.delegate = delegate
        self.index = index
        
        fixtureImageView.image = fixture.type.image
        fixtureNameLabel.text = fixture.type.name
        eventsAmountLabel.text = "\(fixture.fixtureUsages.count) " + (fixture.fixtureUsages.count == 1 ? "event" : "events")
        
        var consumption: Double = 0
        for fixtureUsage in fixture.fixtureUsages {
            consumption += fixtureUsage.consumption
        }
        eventsConsumptionLabel.text = String(format: "%.1f \(MeasuresHelper.unitAbbreviation(for: .volume))", consumption)
        
        var arrowImage = fixture.expanded ? UIImage(named: "arrow-up-black") : UIImage(named: "arrow-down-black")
        arrowImage = arrowImage?.withRenderingMode(.alwaysTemplate)
        arrowImageView.image = arrowImage
    }
}
