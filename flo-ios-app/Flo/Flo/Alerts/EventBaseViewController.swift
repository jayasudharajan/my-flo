//
//  EventBaseViewController.swift
//  Flo
//
//  Created by Nicolás Stefoni on 11/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit

internal class EventBaseViewController: FloBaseViewController {
    
    public var event: EventModel!
    public var allowsUserInteraction: Bool = true
    public var feedbackResult: [[String: AnyObject]] = []
    
    @IBOutlet public weak var titleLabel: UILabel!
    
    @IBOutlet public weak var stackView: UIView!
    @IBOutlet public weak var stackHeight: NSLayoutConstraint!
    @IBOutlet public weak var column1ValueLabel: UILabel!
    @IBOutlet public weak var column1DescLabel: UILabel!
    @IBOutlet public weak var column2PreLabel: UILabel!
    @IBOutlet public weak var column2ValueLabel: UILabel!
    @IBOutlet public weak var column2DescLabel: UILabel!
    @IBOutlet public weak var column3ValueLabel: UILabel!
    @IBOutlet public weak var column3DescLabel: UILabel!
    
    @IBOutlet public weak var clearAlertButton: UIButton!
    @IBOutlet public weak var valveView: UIView!
    @IBOutlet public weak var valveViewHeight: NSLayoutConstraint!
    
    @IBAction public func clearAlertAction() {
        if let feedbackFlow = event.feedbackFlow {
            setUpFeedbackFlow(feedbackFlow)
        } else if !(event.alert?.actions ?? []).isEmpty {
            showActionsMenu()
        } else {
            confirmAction(snoozingSeconds: 0)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let severity = event.alert?.severity ?? .info
        let alertId = event.alert?.id ?? 0
        let isShutoff = event.alert?.isShutoff ?? false
        
        switch severity {
        case .critical:
            view.layer.addGradient(from: StyleHelper.colors.darkRed, to: StyleHelper.colors.red, angle: 90)
            
            if !isShutoff {
                stackHeight.constant = 48
                stackView.isHidden = false
                
                column1ValueLabel.text = "\(String(format: "%.2f", MeasuresHelper.adjust(event.gpm, ofType: .flow))) \(MeasuresHelper.unitAbbreviation(for: .flow))"
                column1DescLabel.text = "flow_rate_during_event".localized
                column2ValueLabel.text = elapsedTimeToString(event.duration)
                column2DescLabel.text = "event_duration".localized
                column3ValueLabel.text = "\(String(format: "%.2f", MeasuresHelper.adjust(event.galUsed, ofType: .volume))) \(MeasuresHelper.unitName(for: .volume))"
                column3DescLabel.text = "total_amount_used".localized(args: [MeasuresHelper.unitName(for: .volume).localized])
            }
        case .warning:
            view.layer.addGradient(from: StyleHelper.colors.darkOrange, to: StyleHelper.colors.orange, angle: 90)
            
            if alertId > 27 && alertId < 32 && !isShutoff {
                stackHeight.constant = 48
                stackView.isHidden = false
                column1DescLabel.text = "health_test_duration".localized
                column2PreLabel.text = "up_to".localized
                column2DescLabel.text = "est_daily_water_loss".localized
                column3DescLabel.text = "pressure_loss".localized
                
                fetchHealthTestResult()
            }
        case .info:
            view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
            clearAlertButton.isHidden = true
        }
        
        if allowsUserInteraction {
            clearAlertButton.layer.cornerRadius = clearAlertButton.frame.height / 2
            clearAlertButton.layer.borderWidth = 1
            clearAlertButton.layer.borderColor = StyleHelper.colors.transparency20.cgColor
            clearAlertButton.backgroundColor = StyleHelper.colors.transparency
        } else {
            clearAlertButton.isHidden = true
        }
        
        titleLabel.text = event.displayTitle.isEmpty ? event.alert?.name : event.displayTitle
        
        if let device = event.device, severity != .info, let alert = event.alert, (alert.id < 28 || alert.id > 31), allowsUserInteraction {
            let valveController = ValveCardViewController.getInstance()
            valveController.updateWith(deviceInfo: device)
            addContentController(valveController, toView: valveView)
        } else {
            valveView.isHidden = true
            valveViewHeight.constant = 24
        }
    }
    
    // MARK: - Overrides
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    // MARK: - Fetch health test result
    fileprivate func fetchHealthTestResult() {
        column1ValueLabel.text = elapsedTimeToString(event.duration)
        column2ValueLabel.text = "\(String(format: "%.0f", MeasuresHelper.adjust(event.leakLossMaxGal, ofType: .volume).rounded())) \(MeasuresHelper.unitAbbreviation(for: .volume))"
        column3ValueLabel.text = "\(String(format: "%.0f", event.psiDelta.rounded()))%"
        
        if let device = event.device, let roundId = event.roundId {
            showLoadingSpinner("loading".localized)
            HealthTestHelper.getHealthTestStatus(device: device, roundId: roundId) { (_, result) in
                self.hideLoadingSpinner()
                
                if let r = result {
                    self.column1ValueLabel.text = self.elapsedTimeToString(Double(r.testDuration))
                    self.column2ValueLabel.text = "\(String(format: "%.0f", MeasuresHelper.adjust(r.leakLossMaxGal, ofType: .volume).rounded())) \(MeasuresHelper.unitAbbreviation(for: .volume))"
                    self.column3ValueLabel.text = "\(String(format: "%.0f", r.deltaPressure.rounded()))%"
                }
            }
        }
    }
    
    // MARK: - Interval string formatter
    fileprivate func elapsedTimeToString(_ elapsedTime: Double) -> String {
        var elapsedTimeString = ""
        let hours = Int(elapsedTime / 3600)
        let minutes = Int(elapsedTime.truncatingRemainder(dividingBy: 3600) / 60)
        let seconds = Int(elapsedTime.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            elapsedTimeString = "\(hours) h"
        }
        if minutes > 0 {
            elapsedTimeString += elapsedTimeString.isEmpty ? "" : " "
            elapsedTimeString += "\(minutes) " + "min_s_".localized
        }
        if seconds > 0 && hours == 0 {
            elapsedTimeString += elapsedTimeString.isEmpty ? "" : " "
            elapsedTimeString += "\(seconds) " + "seconds".localized
        }
        if elapsedTimeString.isEmpty {
            elapsedTimeString = "0 " + "seconds".localized
        }
        
        return elapsedTimeString
    }
    
    // MARK: - Feedback menu
    public func setUpFeedbackFlow(_ feedbackFlow: AlertFeedbackFlow) {
        let title = (event.displayTitle.isEmpty ? event.alert?.name : event.displayTitle) ?? "clear_alert".localized
        var popupOptions: [AlertPopupOption] = []
        
        if feedbackFlow.type == .text, let feedbackOption = feedbackFlow.options.first {
            let textInputView = AlertPopupTextFieldHeader.getInstance()
            showPopup(
                title: title,
                description: feedbackFlow.title,
                inputView: textInputView,
                acceptButtonText: "submit".localized,
                acceptButtonAction: {
                    if let property = feedbackOption.property {
                        self.feedbackResult.append([
                            "property": property as AnyObject,
                            "value": textInputView.getText() as AnyObject
                        ])
                    }
                    if let flow = feedbackOption.flow {
                        self.setUpFeedbackFlow(flow)
                    } else {
                        self.sendFeedback(snoozingSeconds: feedbackOption.action?.snoozeSeconds ?? 0)
                    }
                },
                cancelButtonText: "cancel".localized
            )
        } else {
            for feedbackOption in feedbackFlow.options {
                popupOptions.append(AlertPopupOption(title: feedbackOption.displayText, type: .normal) {
                    if let property = feedbackOption.property {
                        self.feedbackResult.append([
                            "property": property as AnyObject,
                            "value": feedbackOption.value
                        ])
                    }
                    if let flow = feedbackOption.flow {
                        self.setUpFeedbackFlow(flow)
                    } else {
                        self.sendFeedback(snoozingSeconds: feedbackOption.action?.snoozeSeconds ?? 0)
                    }
                })
            }
            
            popupOptions.append(AlertPopupOption(title: "cancel".localized, type: .cancel))
            
            showPopup(
                title: (event.displayTitle.isEmpty ? event.alert?.name : event.displayTitle) ?? "clear_alert".localized,
                description: feedbackFlow.title,
                options: popupOptions
            )
        }
    }
    
    public func sendFeedback(snoozingSeconds: Int) {
        self.showLoadingSpinner("loading".localized)
        
        let data: [String: AnyObject] = [
            "feedback": feedbackResult as AnyObject
        ]
        
        FloApiRequest(
            controller: "v2/alerts/\(event.id)/userFeedback",
            method: .post,
            queryString: nil,
            data: data,
            done: { (error, _) in
                self.hideLoadingSpinner()
                
                if let e = error {
                    LoggerHelper.log("Send feedback error on: POST v2/alerts/\(self.event.id)/userFeedback: " + e.message, level: .error)
                    self.showPopup(error: e)
                } else {
                    self.confirmAction(snoozingSeconds: snoozingSeconds)
                }
            }
        ).secureFloRequest()
    }
    
    // MARK: - Actions menu
    public func showActionsMenu() {
        if let alert = event.alert, !alert.actions.isEmpty {
            var options: [AlertPopupOption] = []
            for action in alert.actions {
                options.append(AlertPopupOption(title: action.text, type: .normal) {
                    self.confirmAction(snoozingSeconds: action.snoozeSeconds)
                })
            }
            options.append(AlertPopupOption(title: "cancel".localized, type: .cancel))
            
            showPopup(
                title: "take_action_title".localized,
                options: options
            )
        }
    }
    
    public func confirmAction(snoozingSeconds: Int) {
        if let alert = event.alert, let device = event.device {
            self.showLoadingSpinner("loading".localized)
            
            let specialIds = [28, 29, 30, 31]
            let alertIds = specialIds.contains(alert.id) ? specialIds : [alert.id]
            let data: [String: AnyObject] = [
                "deviceId": device.id as AnyObject,
                "alarmIds": alertIds as AnyObject,
                "snoozeSeconds": snoozingSeconds as AnyObject
            ]
            
            FloApiRequest(
                controller: "v2/alerts/action",
                method: .post,
                queryString: nil,
                data: data,
                done: { (error, _) in
                    self.hideLoadingSpinner()
                    
                    if let e = error {
                        LoggerHelper.log("Take action error on: POST v2/alerts/action: " + e.message, level: .error)
                        self.showPopup(error: e)
                    } else {
                        for viewController in self.navigationController?.viewControllers ?? [] {
                            if let alertsViewController = viewController as? AlertsViewController {
                                self.navigationController?.popToViewController(alertsViewController, animated: true)
                                break
                            }
                        }
                    }
                }
            ).secureFloRequest()
        }
    }

}
