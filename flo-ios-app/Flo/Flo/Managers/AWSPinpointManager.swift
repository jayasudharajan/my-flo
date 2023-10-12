//
//  AWSPinpointManager.swift
//  Flo
//
//  Created by Matias Paillet on 12/28/18.
//  Copyright © 2018 Flo Technologies. All rights reserved.
//

import AWSCore
import AWSPinpoint
import AWSMobileClient

internal class AWSPinpointManager {
    
    fileprivate var pinpoint: AWSPinpoint?
    
    // MARK: Singleton
    public class var shared: AWSPinpointManager {
        struct Static {
            static let instance = AWSPinpointManager()
        }
        return Static.instance
    }
    
    public func initialize(_ application: UIApplication,
                           withLaunchOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        // Create AWSMobileClient to connect with AWS
        AWSMobileClient.default().initialize { (userState, error) in
            if let error = error {
                LoggerHelper.log("Error initializing AWSMobileClient: \(error.localizedDescription)", level: .error)
            } else if let userState = userState {
                LoggerHelper.log("AWSMobileClient initialized. Current UserState: \(userState.rawValue)", level: .debug)
            }
        }
        
        // Initialize AWS Pinpoint
        let pinpointConfiguration = AWSPinpointConfiguration.defaultPinpointConfiguration(launchOptions: launchOptions)
        pinpoint = AWSPinpoint(configuration: pinpointConfiguration)
    }
    
    // MARK: push notifications
    public func interceptDidRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        //Register device token on pinpoint
        pinpoint?.notificationManager.interceptDidRegisterForRemoteNotifications(withDeviceToken: deviceToken)
    }
    
    public func interceptDidReceiveRemoteNotification(_ userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler:@escaping (UIBackgroundFetchResult) -> Void) {
        //Track push notification reception through pinpoint
        pinpoint?.notificationManager.interceptDidReceiveRemoteNotification(userInfo,
                                                                            fetchCompletionHandler: completionHandler)
    }
    
    // MARK: UserManagement
    public func loginUser(withId userId: String) {
        if let targetingClient = pinpoint?.targetingClient {
            let endpoint = targetingClient.currentEndpointProfile()
            // Create a user and set its userId property
            let user = AWSPinpointEndpointProfileUser()
            user.userId = userId
            // Assign the user to the endpoint
            endpoint.user = user
            // Update the endpoint with the targeting client
            targetingClient.update(endpoint)
        }
    }
    
    public func getCurrentEndpointId() -> String? {
        if let targetingClient = pinpoint?.targetingClient {
            return targetingClient.currentEndpointProfile().endpointId
        }
        return nil
    }
    
    // MARK: EventLogging
    public func logEvent(_ eventName: String,
                         withParams params: [String: String],
                         withMetrics metrics: [String: NSNumber]) {
        let event = pinpoint?.analyticsClient.createEvent(withEventType: eventName)
        
        for p in params {
            event?.addAttribute(p.value, forKey: p.key)
        }
        
        for m in metrics {
            event?.addMetric(m.value, forKey: m.key)
        }
        
        pinpoint?.analyticsClient.record(event!)
        pinpoint?.analyticsClient.submitEvents()
    }
    
    public func logEvent(_ eventName: String, withParams params: [String: String]) {
        logEvent(eventName, withParams: params, withMetrics: [:])
    }
    
    public func logEvent(_ eventName: String) {
        logEvent(eventName, withParams: [:], withMetrics: [:])
    }
    
}
