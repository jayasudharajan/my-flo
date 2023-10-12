//
//  AppDelegate.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/14/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import Firebase
import IQKeyboardManager
import SideMenu
import Embrace
import Instabug

@UIApplicationMain
internal class AppDelegate: UIResponder, UIApplicationDelegate {
    
    fileprivate let kDeviceOfflineId = 33
    
    public var window: UIWindow?
    public var reachability: FloApiCheck!
    fileprivate var cover: UIVisualEffectView!
    
    // MARK: Lifecycle
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //Configure debug/production only frameworks
        #if DEBUG
        //UserSessionManager.shared.logout()
        #else
        //Embrace SDK
        if let embraceKey = PlistHelper.valueForKey("FloEmbraceKey") as? String {
            Embrace.sharedInstance().start(withKey: embraceKey)
        }
        //Crashlytics
        Fabric.with([Crashlytics.self, Answers.self])
        #endif
        
        AWSPinpointManager.shared.initialize(application, withLaunchOptions: launchOptions)
        ChatHelper.initialize()
        FirebaseApp.configure()
        if let key = PlistHelper.valueForKey("FloInstabugKey") as? String {
            Instabug.start(withToken: key, invocationEvents: [.shake, .screenshot])
            Instabug.sdkDebugLogsLevel = .none
        }
        IQKeyboardManager.shared().isEnabled = true
        IQKeyboardManager.shared().isEnableAutoToolbar = true
        IQKeyboardManager.shared().shouldResignOnTouchOutside = true
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let sideMenuNavController = storyboard.instantiateViewController(withIdentifier: "SideMenu") as? UISideMenuNavigationController {
            SideMenuManager.default.menuLeftNavigationController = sideMenuNavController
            SideMenuManager.default.menuWidth = 312
            SideMenuManager.default.menuFadeStatusBar = false
            SideMenuManager.default.menuPresentMode = .menuSlideIn
        }
        
        _ = FloGlobalServices.instance // Wake in up the services
        self.reachability = FloApiCheck.reachabilityForInternetConnection()
        self.reachability.startNotifier()
        
        // Security fix: prevent disclosing info on backgrounding snapshots
        UIApplication.shared.ignoreSnapshotOnNextApplicationLaunch()
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Security fix: prevent disclosing info on backgrounding snapshots
        if window != nil {
            cover = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
            cover.frame = window!.frame
            window!.addSubview(cover)
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        AppVersionHelper.validate()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Security fix: prevent disclosing info on backgrounding snapshots
        if cover != nil {
            cover.removeFromSuperview()
            cover = nil
        }
        
        if let tokenString = UserSessionManager.shared.pushToken {
            var tokenData = [
                "mobile_device_id": (UIDevice.current.identifierForVendor?.uuidString as AnyObject),
                "token": (tokenString as AnyObject)
            ]
            if let awsEndpointId = AWSPinpointManager.shared.getCurrentEndpointId() {
                tokenData["aws_endpoint_id"] = awsEndpointId as AnyObject
            }
            
            FloApiRequest(
                controller: "v1/pushnotificationtokens/ios",
                method: .post,
                queryString: nil,
                data: tokenData,
                done: { (_, _) in }
            ).secureFloRequest()
        }
    }
    
    // MARK: Deep Linking
    @available(iOS 9.0, *)
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if let sourceApp = options[.sourceApplication] as? String {
            return application(app, open: url, sourceApplication: sourceApp, annotation: "a")
        } else {
            return application(app, open: url, sourceApplication: nil, annotation: "a")
        }
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return openfromURL(url)
    }
    
    func openfromURL(_ url: URL) -> Bool {
        switch url.host {
        case "home", "dashboard":
            goToDashboard()
        case "registration2":
            let data = url.path.split(separator: "/").map(String.init)
            guard data.count == 1 else {
                return false
            }
            let token = data[0]
            
            if UserSessionManager.shared.authorization != nil {
                let logoutUser = [
                    "mobile_device_id": (UIDevice.current.identifierForVendor?.uuidString as AnyObject),
                    "aws_endpoint_id": (AWSPinpointManager.shared.getCurrentEndpointId() as AnyObject)
                ]
                
                FloApiRequest(controller: "v1/logout", method: .post, queryString: nil, data: logoutUser, done: { (_, _) in
                    UserSessionManager.shared.logout()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.verifyEmailWithToken(token: token)
                    }
                }).secureFloRequest()
                
                TrackingManager.shared.track(TrackingManager.kEventLogout)
            } else {
                self.verifyEmailWithToken(token: token)
            }
        default:
            LoggerHelper.log("Unrecognized deeplink received: \(url.absoluteString)", level: .warning)
        }
        
        return false
    }
    
    fileprivate func verifyEmailWithToken(token: String) {
        let topViewControler = UIApplication.topViewController() as? FloBaseViewController
        
        topViewControler?.showLoadingSpinner("verifying_email_address".localized)
        
        var data = [String: AnyObject]()
        data["token"] = token as AnyObject
        let clientId = PlistHelper.valueForKey("FloApiClientID") as AnyObject
        data["clientId"] = clientId
        data["clientSecret"] = clientId
        
        FloApiRequest(
            controller: "v2/users/register/verify",
            method: .post,
            queryString: nil,
            data: data,
            done: { (error, response) in
                topViewControler?.hideLoadingSpinner()
                if let e = error {
                    topViewControler?.showPopup(description: e.message)
                } else if let auth = OAuthModel(response) {
                    UserSessionManager.shared.upsertAuthorization(auth)
                    self.goToDashboard()
                } else {
                    topViewControler?.showPopup(
                        description: "an_error_occurred_getting_the_authorization_data_from_server".localized
                    )
                    return
                }
            }
        ).unsecureFloRequest()
    }
    
    // MARK: Push Notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenChars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
        var tokenString = ""
        for i in 0 ..< deviceToken.count {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        LoggerHelper.log("Push Notification token retrieved: \(tokenString)", level: .debug)
        
        var tokenData = [
            "mobile_device_id": (UIDevice.current.identifierForVendor?.uuidString as AnyObject),
            "token": (tokenString as AnyObject)
        ]
        if let awsEndpointId = AWSPinpointManager.shared.getCurrentEndpointId() {
            tokenData["aws_endpoint_id"] = awsEndpointId as AnyObject
        }
        LoggerHelper.log("Token data", object: tokenData, level: .debug)
        
        FloApiRequest(controller: "v1/pushnotificationtokens/ios", method: .post, queryString: nil, data: tokenData, done: { (error, _) in
            if let e = error {
                LoggerHelper.log(e.message, level: .error)
            } else {
                LoggerHelper.log("Token sent to server", level: .debug)
                UserSessionManager.shared.pushToken = tokenString
            }
        }).secureFloRequest()
        
        AWSPinpointManager.shared.interceptDidRegisterForRemoteNotifications(withDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        LoggerHelper.log("Failed to register push notification token:", object: error, level: .error)
        UserSessionManager.shared.pushToken = nil
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        AWSPinpointManager.shared.interceptDidReceiveRemoteNotification(userInfo, fetchCompletionHandler: completionHandler)
        
        if UserSessionManager.shared.authorization != nil {
            LoggerHelper.log("Did recieve Remote Notification", level: .debug)
            handlePushNotification(userInfo: userInfo)
            completionHandler(UIBackgroundFetchResult.newData)
            return
        }
        completionHandler(UIBackgroundFetchResult.noData)
    }
    
    fileprivate func handlePushNotification(userInfo: [AnyHashable: Any]) {
        if let aps = userInfo["aps"] as? [String: AnyObject], let category = aps["category"] as? [String: AnyObject] {
            if let eventNotification = category["FloAlarmNotification"] as? NSDictionary, let eventId = eventNotification["id"] as? String {
                handleEventNotification(eventId: eventId)
            }
        } else if let data = userInfo["data"] as? NSDictionary, let messageData = data["jsonBody"] as? NSDictionary {
            InAppMessageManager.instance.showMessage(messageData)
        } else {
            LoggerHelper.log("Unrecognized push notifications payload received:", object: userInfo, level: .warning)
        }
    }
    
    fileprivate func handleEventNotification(eventId: String) {
        waitForApplicationStartUp {
            let topViewController = UIApplication.topViewController()
            if topViewController as? EventBaseViewController == nil && topViewController as? HealthTestResultsViewController == nil {
                AlertsManager.shared.getEvent(eventId, callback: { (event) in
                    let storyboard = UIStoryboard(name: "Alerts", bundle: nil)
                    if let e = event, let eventDetailViewController = storyboard.instantiateViewController(withIdentifier: EventDetailViewController.storyboardId) as? EventDetailViewController {
                        eventDetailViewController.event = e
                    
                        if let navController = topViewController?.navigationController {
                            navController.pushViewController(eventDetailViewController, animated: true)
                        } else {
                            self.goToDashboard(thenPush: eventDetailViewController)
                        }
                    } else {
                        LoggerHelper.log("Received a push notification, but there is no event on cloud with ID: \(eventId)", level: .error)
                    }
                })
            } else {
                LoggerHelper.log("Received a push notification, but user is already on an event detail or health test result", level: .warning)
            }
        }
    }
    
    // MARK: - New app flow methods
    public func goToLogin() {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        
        let loginVC = storyboard.instantiateViewController(withIdentifier: LoginViewController.storyboardId)
        let navController = UINavigationController(rootViewController: loginVC)
        UIApplication.shared.switchRootViewController(navController, animated: true)
    }
    
    fileprivate func goToDashboard(thenPush viewController: UIViewController? = nil) {
        let topViewControler = UIApplication.topViewController() as? FloBaseViewController
        topViewControler?.showLoadingSpinner("loading".localized)
        
        UserSessionManager.shared.getUser { (_, user) in
            topViewControler?.hideLoadingSpinner()
            
            if let u = user {
                TrackingManager.shared.identify(u.id, email: u.email)
                AWSPinpointManager.shared.loginUser(withId: u.id)
                AWSPinpointManager.shared.logEvent("register", withParams: ["email": u.email])
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let entryPoint = storyboard.instantiateViewController(withIdentifier: TabBarController.storyboardId) as? TabBarController {
                UIApplication.shared.keyWindow?.rootViewController = entryPoint
                UIApplication.shared.keyWindow?.makeKeyAndVisible()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let topViewController = viewController, let navController = entryPoint.selectedViewController as? UINavigationController {
                        navController.pushViewController(topViewController, animated: true)
                    }
                }
            }
        }
    }
    
    // MARK: - Wait till application is ready to present new controllers
    fileprivate func waitForApplicationStartUp(_ ready: @escaping () -> Void) {
        if UIApplication.topViewController() == nil || UIApplication.topViewController() as? LoadingViewController != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.waitForApplicationStartUp {
                    ready()
                }
            }
        } else {
            ready()
        }
    }

}
