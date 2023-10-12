//
//  StatusManager.swift
//  Flo
//
//  Created by Nicolás Stefoni on 16/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import Firebase
import FirebaseAuth

class StatusManager {
    
    public class var shared: StatusManager {
        struct Static {
            static let instance = StatusManager()
        }
        return Static.instance
    }
    
    public var firestoreToken = ""
    
    fileprivate let appData: [String: AnyObject] = [
        "appName": (PlistHelper.valueForKey("CFBundleName") as? String ?? "") as AnyObject,
        "appVersion": "\(Bundle.main.versionNumber) - \(Bundle.main.buildNumber)" as AnyObject
    ]
    fileprivate var authenticating = false
    fileprivate(set) var authenticated = false
    fileprivate var db: Firestore?
    fileprivate var deviceListeners: [ListenerRegistration] = []
    fileprivate var devices: [DeviceModel] = []
    fileprivate var deviceFirstStatus: [String: DeviceStatus] = [:]
    fileprivate var presenceTimer: Timer?
    fileprivate let kPresenceTimerInterval: Double = 30
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    // MARK: - Authentication
    public func authenticate(_ callback: @escaping (Bool) -> Void) {
        if !authenticating {
            authenticating = true
            
            FloApiRequest(
                controller: "v2/session/firestore",
                method: .post,
                queryString: nil,
                data: nil,
                done: { (error, data) in
                    if let d = data as? NSDictionary, let token = d["token"] as? String {
                        self.internalAuthenticate(withToken: token, callback)
                    } else {
                        if let e = error {
                            LoggerHelper.log("Something went wrong while retrieving Firestore token: " + e.message, level: .error)
                        }
                        self.authenticating = false
                        self.authenticated = false
                        callback(false)
                    }
                }
            ).secureFloRequest()
        }
    }
    
    public func authenticate(withToken token: String, _ callback: @escaping (Bool) -> Void) {
        if !authenticating {
            authenticating = true
            self.internalAuthenticate(withToken: token, callback)
        }
    }
    
    fileprivate func internalAuthenticate(withToken token: String, _ callback: @escaping (Bool) -> Void) {
        Auth.auth().signIn(withCustomToken: token, completion: { (_, error) in
            self.authenticating = false
            if let e = error {
                self.authenticated = false
                
                LoggerHelper.log(e)
                callback(false)
            } else {
                self.authenticated = true
                
                let settings = Firestore.firestore().settings
                settings.isPersistenceEnabled = false
                Firestore.firestore().settings = settings
                
                self.db = Firestore.firestore()
                self.db?.clearPersistence(completion: { (error) in
                    if let e = error {
                        LoggerHelper.log(e)
                    }
                    self.updatePresence()
                    self.firestoreToken = token
                    callback(true)
                })
            }
        })
    }
    
    // MARK: - Tracking methods
    public func trackMacAddress(_ macAddress: String, onUpdate: @escaping (DeviceStatus) -> Void) {
        stopTracking()
        
        if authenticated {
            let deviceListener = db?.collection("devices").document(macAddress).addSnapshotListener { (document, _) in
                if document?.metadata.isFromCache == false, let deviceData = document?.data(), let status = DeviceStatus(deviceData as AnyObject) {
                    onUpdate(status)
                }
            }
            if let listener = deviceListener {
                deviceListeners.append(listener)
            }
        } else {
            // Re-authenticate if not authenticated for some reason
            authenticate { (success) in
                if success {
                    self.trackMacAddress(macAddress, onUpdate: onUpdate)
                }
            }
        }
    }
    
    public func trackDevices(_ devices: [DeviceModel], onUpdate: @escaping (DeviceStatus) -> Void) {
        stopTracking()
        
        if authenticated {
            for device in devices {
                let deviceListener = db?.collection("devices").document(device.macAddress).addSnapshotListener { (document, _) in
                    if document?.metadata.isFromCache == false, let deviceData = document?.data(), let status = DeviceStatus(deviceData as AnyObject) {
                        // We will discard the first message of any connection
                        if self.deviceFirstStatus[status.macAddress] == nil {
                            self.deviceFirstStatus[status.macAddress] = status
                            return
                        }
                        
                        for trackedDevice in self.devices where trackedDevice.macAddress == status.macAddress {
                            if !trackedDevice.isInstalled && status.isInstalled == true {
                                DeviceInstalledViewController.instantiate(for: trackedDevice)
                            }
                            trackedDevice.setStatus(status)
                            if status.willShutOffAt != nil {
                                ShutOffPopupViewController.instantiate(for: trackedDevice)
                            }
                            break
                        }
                        onUpdate(status)
                    }
                }
                if let listener = deviceListener {
                    deviceListeners.append(listener)
                    self.devices.append(device)
                }
            }
        } else {
            // Re-authenticate if not authenticated for some reason
            authenticate { (success) in
                if success {
                    self.trackDevices(devices, onUpdate: onUpdate)
                }
            }
        }
    }
    
    public func stopTracking() {
        while let deviceListener = deviceListeners.popLast() {
            deviceListener.remove()
        }
        devices = []
        deviceFirstStatus = [:]
    }
    
    // MARK: - Update presence
    @objc fileprivate func updatePresence() {
        if !authenticated {
            authenticate({ _ in })
            return
        }
        
        FloApiRequest(
            controller: "v2/presence/me",
            method: .post,
            queryString: nil,
            data: appData,
            done: { (error, _) in
                if let e = error {
                    LoggerHelper.log("Error updating presence!: " + e.message, level: .error)
                }
            }
        ).secureFloRequest()
        
        presenceTimer?.invalidate()
        presenceTimer = nil
        presenceTimer = Timer.scheduledTimer(timeInterval: kPresenceTimerInterval, target: self, selector: #selector(updatePresence), userInfo: nil, repeats: false)
    }
    
    // MARK: - App going foreground/background callbacks
    @objc fileprivate func willEnterForeground() {
        if authenticated {
            updatePresence()
        } else if !authenticating {
            authenticate { _ in }
        }
    }
    
    @objc fileprivate func didEnterBackground() {
        presenceTimer?.invalidate()
        presenceTimer = nil
    }
    
    // MARK: - Logout
    public func logout() {
        stopTracking()
        authenticated = false
        authenticating = false
        presenceTimer?.invalidate()
        presenceTimer = nil
    }
}
