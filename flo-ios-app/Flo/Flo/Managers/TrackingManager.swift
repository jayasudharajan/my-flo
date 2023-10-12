//
//  TrackingManager.swift
//  Flo
//
//  Created by Nicolás Stefoni on 14/11/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import Mixpanel
import Embrace

internal class TrackingManager {
    
    // User properties
    public static let kPropertyEmail = "$email"
    
    // Events
    public static let kEventUserOnPrefix = "app_user_on_"
    
    public static let kEventAlarmSlider = "app_alarm_action_taken_slider"
    public static let kEventAlarmDropdown = "app_alarm_action_taken_dropdown"
    public static let kEventWaterOn = "app_water_valve_on"
    public static let kEventWaterOff = "app_water_valve_off"
    public static let kEventDeviceModeHome = "app_device_switched_to_home"
    public static let kEventDeviceModeAway = "app_device_switched_to_away"
    public static let kEventDeviceModeSleep = "app_device_switched_to_sleep"
    public static let kEventLogin = "app_user_login"
    public static let kEventLogout = "app_user_logout"
    public static let kEventLeakTest = "app_leaked_test_pushed"
    public static let kEventPairingComplete = "app_pairing_complete"
    public static let kEventTapChat = "app_tap_chat"
    public static let kEventOpenedChat = "app_opened_chat"
    public static let kEventOpenedTroubleshootTips = "app_opened_troubleshoot_tips"
    public static let kEventManageFloProtect = "app_manage_home_protect"
    public static let kEventAddFloProtectBase = "add_floprotect_floprotect"
    public static let kEventAddFloProtectFixtures = "add_floprotect_fixtures"
    public static let kEventSetupGuide = "click_setup_guide"
    
    // Actions
    public static let kAlarmActionPrefix = "app_alarm_action_"
    
    // Controllers
    public static let kControllerPairing = "pairing"
    public static let kControllerPairingIntro = "pairing_intro"
    public static let kControllerPairingScanQr = "pairing_scan_qr"
    public static let kControllerPairingPushToConnect = "pairing_push_to_connect"
    public static let kControllerPairingConnectToDeviceWifi = "pairing_connect_to_device_wifi"
    public static let kControllerPairingSelectWifi = "pairing_select_wifi"
    public static let kControllerPairingWifiCredentials = "pairing_wifi_credentials"
    public static let kControllerPairingFinalizing = "pairing_finalizing"
    public static let kControllerPairingComplete = "pairing_complete"
    public static let kControllerDashboard = "dashboard"
    public static let kControllerControlPanel = "control_panel"
    public static let kControllerAlarm = "alarm"
    public static let kControllerAlarmTroubleshoot = "alarm_troubleshoot"
    public static let kControllerFloProtect = "home_protect"
    
    // MARK: - Singleton
    public class var shared: TrackingManager {
        struct Static {
            static let instance = TrackingManager()
        }
        return Static.instance
    }
    
    fileprivate var tracker: Mixpanel!
    
    fileprivate init() {
        tracker = Mixpanel(token: PlistHelper.valueForKey("FloMixpanelKey") as? String ?? "",
                           launchOptions: nil,
                           andFlushInterval: UInt(60))
    }
    
    public func identify(_ id: String, email: String? = "") {
        //Track on Embrace
        Embrace.sharedInstance()?.setUserIdentifier(id)
//        //Don't set username for security reasons unless it's neccesary in the future
//        Embrace.sharedInstance().setUsername("")
        
        //Track on Mixpanel
        tracker.identify(id)
        
        if email != nil {
            Embrace.sharedInstance()?.setUserEmail(email!)
            self.tracker.people.set(TrackingManager.kPropertyEmail, to: email!)
        }
        
        UserSessionManager.shared.checkUserSubscription(id) { (subscribed, _) in
            FloApiRequest(controller: "v1/info/users/\(id)", method: .get, queryString: nil, data: nil, done: { ( error, data) in
                
                if error != nil {
                    return
                }
                
                var groupId = ""
                if let r = data as? [String: AnyObject] {
                    if let items = r["items"] as? NSArray {
                        for i in items {
                            if let item = i as? NSDictionary {
                                
                                if let e = item["email"] as? String {
                                    Embrace.sharedInstance()?.setUserEmail(e)
                                    self.tracker.people.set(TrackingManager.kPropertyEmail, to: e)
                                }
                                
                                if let account = item["account"] as? NSDictionary {
                                    if let groupIdResp = account["group_id"] as? String {
                                        groupId = groupIdResp
                                    }
                                }
                            }
                        }
                    }
                }
                
                //Set user as paid user if it's subscribed
                if subscribed {
                    Embrace.sharedInstance()?.setUserAsPayer()
                }
                
                self.tracker.registerSuperPropertiesOnce([
                    "group_id": groupId,
                    "is_subscriber": subscribed
                ])
                self.track(TrackingManager.kEventLogin)
            }).secureFloRequest()
        }
    }
    
    public func startTimer(_ event: String) {
        tracker.timeEvent(event)
    }
    
    public func track(_ event: String, detail: String = "") {
        if detail.isEmpty {
            tracker.track(event)
        } else {
            tracker.track(event, properties: ["state": detail])
        }
    }
    
    public func reset() {
        tracker.reset()
    }
    
}
