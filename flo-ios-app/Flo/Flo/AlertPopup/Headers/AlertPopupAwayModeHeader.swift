//
//  AlertPopupAwayModeHeader.swift
//  Flo
//
//  Created by Nicolás Stefoni on 04/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal enum IrrigationStatus: String {
    case scheduleFound = "schedule_found"
    case scheduleNotFound = "schedule_not_found"
    case noIrrigation = "no_irrigation_in_home"
    case learning = "learning"
    case internalError = "internal_error"
}

internal class AlertPopupAwayModeHeader: UIView, AlertPopupHeaderProtocol {
    
    fileprivate var irrigationEnabled = false
    fileprivate var dismissAllowed = false
    fileprivate var irrigationStatus = IrrigationStatus.internalError
    fileprivate var irrigationData: [[String]] = []
    fileprivate var irrigationRects: [CGRect] = []
    fileprivate let kSecondsPerDay: CGFloat = 60 * 60 * 24

    @IBOutlet fileprivate weak var irrigationSwitch: UISwitch!
    @IBOutlet fileprivate weak var irrigationInfoView: UIView!
    @IBOutlet fileprivate weak var graphContainerView: UIView!
    @IBOutlet fileprivate weak var barsContainerView: UIView!
    @IBOutlet fileprivate weak var irrigationResultLabel: UILabel!
    @IBOutlet fileprivate weak var irrigationResultView: UIView!
    @IBOutlet fileprivate weak var hintView: UIView!
    @IBOutlet fileprivate weak var hintLabel: UILabel!
    @IBOutlet fileprivate weak var hintButton: UIButton!
    
    @IBAction func irrigationSwitchAction(_ sender: UISwitch) {
        graphContainerView.layer.removeAllAnimations()
        graphContainerView.isHidden = !sender.isOn
        UIView.animate(withDuration: 0.3, animations: {
            self.graphContainerView.alpha = sender.isOn ? 1 : 0
        })
    }
    
    @IBAction func hintAction(_ sender: UIButton) {
        if !hintButton.isSelected {
            if sender == hintButton {
                hintLabel.text = "est_irrigation_tooltip".localized
            } else {
                hintLabel.text = "irrigation_not_found_tooltip".localized
            }
        }
        
        let finishesHidden = hintButton.isSelected
        hintButton.isSelected = !hintButton.isSelected
        hintView.isHidden = false
        finishesHidden ? (hintView.alpha = 1) : (hintView.alpha = 0)
        
        UIView.animate(
            withDuration: 0.3,
            animations: {
                finishesHidden ? (self.hintView.alpha = 0) : (self.hintView.alpha = 1)
            },
            completion: { complete in
                if complete {
                    self.hintView.isHidden = finishesHidden
                }
            }
        )
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        loadIrrigationData()
    }
    
    // MARK: - Instantiation
    public class func getInstance() -> AlertPopupAwayModeHeader {
        if let view = UINib(nibName: String(describing: AlertPopupAwayModeHeader.self), bundle: nil).instantiate(withOwner: nil, options: nil).first as? AlertPopupAwayModeHeader {
            return view
        }
        
        return AlertPopupAwayModeHeader()
    }
    
    // MARK: - View getter
    public func getIrrigationStatus() -> Bool? {
        return irrigationEnabled != irrigationSwitch.isOn ? irrigationSwitch.isOn : nil
    }
    
    // MARK: - AlertPopupHeader protocol methods
    public func allowsDismiss() -> Bool {
        return dismissAllowed
    }
    
    // MARK: - Methods to display irrigation
    fileprivate func loadIrrigationData() {
        if let deviceId = LocationsManager.shared.selectedLocation?.devices.first?.id {
            FloApiRequest(
                controller: "v2/devices/\(deviceId)",
                method: .get,
                queryString: ["expand": "irrigationSchedule"],
                data: nil,
                done: { (_, data) in
                self.dismissAllowed = true
                self.irrigationData = []
                self.irrigationRects = []
                    
                if let dict = data as? NSDictionary,
                    let irrigationDict = dict["irrigationSchedule"] as? NSDictionary,
                    let irrigationEnabled = irrigationDict["isEnabled"] as? Bool,
                    let computationDict = irrigationDict["computed"] as? NSDictionary {
                    let computationStatusKey = computationDict["status"] as? String ?? IrrigationStatus.internalError.rawValue
                    let computationTimes = computationDict["times"] as? [[String]] ?? []
                    
                    self.irrigationEnabled = irrigationEnabled
                    self.irrigationSwitch.isEnabled = true
                    self.irrigationSwitch.isOn = irrigationEnabled
                    self.graphContainerView.isHidden = !irrigationEnabled
                    self.irrigationInfoView.isHidden = computationTimes.isEmpty
                    self.irrigationStatus = irrigationEnabled ? (IrrigationStatus(rawValue: computationStatusKey) ?? .internalError) : .scheduleNotFound
                    
                    if self.irrigationStatus == .scheduleFound {
                        self.irrigationResultView.isHidden = true
                        var finalTimes: [[String]] = []
                        
                        for i in 0 ..< computationTimes.count {
                            if let startDateString = computationTimes[i].first,
                                let endDateString = computationTimes[i].last,
                                let startDate = Date.isoTimeToDate(startDateString),
                                let endDate = Date.isoTimeToDate(endDateString) {
                                
                                let bars = self.createBars(from: startDate, to: endDate)
                                self.irrigationRects.append(contentsOf: bars)
                                for _ in bars {
                                    finalTimes.append(computationTimes[i])
                                }
                            }
                        }
                        
                        self.irrigationData = finalTimes
                        self.drawBars(color: StyleHelper.colors.blue)
                    } else {
                        self.setExampleBars()
                        self.irrigationResultLabel.text = self.irrigationStatus.rawValue.localized
                    }
                } else {
                    self.setExampleBars()
                    self.irrigationResultLabel.text = IrrigationStatus.internalError.rawValue.localized
                }
                    
                if !self.graphContainerView.isHidden {
                    UIView.animate(withDuration: 0.3, animations: {
                        self.graphContainerView.alpha = 1
                    })
                }
            }).secureFloRequest()
        }
    }
    
    fileprivate func createBars(from startDate: Date, to endDate: Date) -> [CGRect] {
        var bars: [CGRect] = []
        
        let scale = barsContainerView.frame.width / kSecondsPerDay
        let height = barsContainerView.frame.height
        
        let startInterval = startDate.localTimeIntervalFrom00hs()
        let endInterval = endDate.localTimeIntervalFrom00hs()
        
        let xOffset = CGFloat(startInterval) * scale
        var rect = CGRect(x: xOffset, y: 0, width: 0, height: 0)
        
        if startInterval <= endInterval {
            let width = (CGFloat(endInterval) * scale) - xOffset
            rect.size = CGSize(width: width, height: height)
            
            bars.append(rect)
        } else {
            var width = barsContainerView.frame.width - xOffset
            rect.size = CGSize(width: width, height: height)
            bars.append(rect)
            
            width = CGFloat(endInterval) * scale
            rect = CGRect(origin: .zero, size: CGSize(width: width, height: height))
            bars.append(rect)
        }
        
        return bars
    }
    
    fileprivate func drawBars(color: UIColor) {
        for bar in barsContainerView.subviews {
            bar.removeFromSuperview()
        }
        
        for i in 0 ..< irrigationRects.count {
            let bar = UIControl(frame: irrigationRects[i])
            bar.tag = i
            bar.backgroundColor = color
            bar.layer.cornerRadius = 3
            barsContainerView.addSubview(bar)
        }
    }
    
    fileprivate func setExampleBars() {
        irrigationData = []
        irrigationRects = []
        
        let exampleTimes = [["00:00:00", "04:00:00"], ["08:00:00", "12:00:00"], ["16:00:00", "20:00:00"]]
        for i in 0 ..< exampleTimes.count {
            if let startDateString = exampleTimes[i].first,
                let endDateString = exampleTimes[i].last,
                let startDate = Date.isoTimeToDate(startDateString),
                let endDate = Date.isoTimeToDate(endDateString) {
                
                let bars = createBars(from: startDate, to: endDate)
                irrigationRects.append(contentsOf: bars)
            }
        }
        drawBars(color: StyleHelper.colors.lightGray)
    }

}
