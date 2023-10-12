//
//  DeviceModel.swift
//  Flo
//
//  Created by Nicolás Stefoni on 10/06/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import SwiftyJSON

internal enum ValveState: String {
    case open, closed, inTransition, testRunning
    
    public var postData: [String: AnyObject] {
        let target: [String: AnyObject] = ["target": rawValue as AnyObject]
        let data: [String: AnyObject] = ["valve": target as AnyObject]
        
        return data
    }
}

internal class DeviceModel: JsonParsingProtocol {
    
    fileprivate let kInstalledAndConfiguredKey = "-installedAndConfigured"
    
    public let id: String
    public var nickname: String
    public let createdAt: Date
    public let macAddress: String
    public let type: String
    public let model: String
    public let fwVersion: String
    public let serialNumber: String
    public let fwProperties: [String: Any]
    public let isFloSenseActive: Bool
    public var irrigationType: String?
    public var prvInstallation: String?
    public let installDate: Date?
    public var systemModeLocked: Bool
    public let wiFiSsid: String
    public let flowThreshold: Threshold
    public let temperatureThreshold: Threshold
    public let pressureThreshold: Threshold
    public let criticalAlerts: Int
    public let warningAlerts: Int
    
    public var isInstalledAndConfigured: Bool {
        get {
            if !UserDefaults.standard.bool(forKey: macAddress + kInstalledAndConfiguredKey) {
                if irrigationType != nil && prvInstallation != nil {
                    UserDefaults.standard.set(true, forKey: macAddress + kInstalledAndConfiguredKey)
                    return true
                }
                return false
            }
            return true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: macAddress + kInstalledAndConfiguredKey)
        }
    }
    
    // Status dependant properties
    fileprivate let _isConnected: Bool
    public var isConnected: Bool {
        return status?.isConnected ?? _isConnected
    }
    fileprivate let _isInstalled: Bool
    public var isInstalled: Bool {
        return status?.isInstalled ?? _isInstalled
    }
    fileprivate let _valveState: ValveState
    public var valveState: ValveState {
        get { status?.valveState ?? _valveState }
        set { status?.valveState = newValue } // Setter needed for DemoMode
    }
    fileprivate let _systemMode: SystemMode
    public var systemMode: SystemMode {
        return status?.systemMode ?? _systemMode
    }
    fileprivate let _wiFiSignal: Int
    public var wiFiSignal: Int {
        return status?.wiFiSignal ?? _wiFiSignal
    }
    
    // Status properties
    public var healthTestStatus: HealthTestStatus? {
        get { return status?.healthTestStatus }
        set { status?.healthTestStatus = newValue } // Setter needed for DemoMode
    }
    public var gpm: Double? {
        return status?.gpm
    }
    public var psi: Double? {
        return status?.psi
    }
    public var tempF: Double? {
        return status?.tempF
    }
    public var willShutOffAt: Date? {
        return status?.willShutOffAt
    }
    
    // Status
    fileprivate var status: DeviceStatus?
    
    public var statusUpdateNotificationName: Notification.Name {
        return Notification.Name("kDeviceStatusUpdate-" + macAddress)
    }
    
    public class func statusUpdateNotificationName(with macAddress: String) -> Notification.Name {
        return Notification.Name("kDeviceStatusUpdate-" + macAddress)
    }
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        guard
            let id = json["id"].string,
            let macAddress = json["macAddress"].string,
            let isConnected = json["isConnected"].bool
        else {
            LoggerHelper.log("Error parsing DeviceModel", level: .error)
            return nil
        }
        
        let createdAtString = json["createdAt"].stringValue
        createdAt = Date.iso8601ToDate(createdAtString) ?? Date()
        type = json["deviceType"].stringValue
        model = json["deviceModel"].stringValue
        
        let nick = json["nickname"].stringValue
        if !nick.isEmpty {
            nickname = nick
        } else {
           let friendlyType = DevicesHelper.getTypeFriendly(self.type)
            if friendlyType != self.type {
                nickname = friendlyType
            } else {
                nickname = DevicesHelper.getTypeFriendly(self.model)
            }
        }
        
        let installDict = json["installStatus"].dictionaryValue
        _isInstalled = installDict["isInstalled"]?.bool ?? false
        installDate = Date.iso8601ToDate(installDict["installDate"]?.string ?? "")
        
        irrigationType = json["irrigationType"].string
        prvInstallation = json["prvInstallation"].string
        
        fwProperties = json["fwProperties"].dictionaryObject ?? [:]
        isFloSenseActive = json["fwProperties"]["flosense_state"].boolValue
        
        let connectionDict = json["connectivity"].dictionaryValue
        wiFiSsid = connectionDict["ssid"]?.string ?? json["fwProperties"]["wifi_sta_ssid"].stringValue
        _wiFiSignal = connectionDict["rssi"]?.int ?? json["fwProperties"]["wifi_rssi"].intValue
        fwVersion = json["fwVersion"].string ?? json["fwProperties"]["fw_ver_a"].string ?? "not_available".localized
        serialNumber = json["serialNumber"].string ?? json["fwProperties"]["serial_number"].string ?? "not_available".localized
        
        var criticalAlerts = 0
        var warningAlerts = 0
        let alarms = json["notifications"]["pending"]["alarmCount"].arrayValue
        for alarm in alarms {
            if let severity = AlertSeverity(rawValue: alarm["severity"].stringValue) {
                switch severity {
                case .critical:
                    criticalAlerts += 1
                case .warning:
                    warningAlerts += 1
                default:
                    break
                }
            }
        }
        self.criticalAlerts = criticalAlerts
        self.warningAlerts = warningAlerts
        
        let valveDict = json["valve"].dictionaryValue
        let valveStateKey = valveDict["lastKnown"]?.string ?? "closed"
        _valveState = ValveState(rawValue: valveStateKey) ?? .closed
        let modeDict = json["systemMode"].dictionaryValue
        let systemModeKey = modeDict["target"]?.string ?? (modeDict["lastKnown"]?.string ?? "sleep")
        _systemMode = SystemMode(rawValue: systemModeKey) ?? .sleep
        
        systemModeLocked = modeDict["isLocked"]?.bool ?? true
        
        let thresholdsDict = json["hardwareThresholds"].dictionaryValue
        flowThreshold = Threshold(dict: thresholdsDict, measureType: .flow)
        temperatureThreshold = Threshold(dict: thresholdsDict, measureType: .temperature)
        pressureThreshold = Threshold(dict: thresholdsDict, measureType: .pressure)
        
        // Parse this to have a status in demo mode
        if let statusDict = json["status"].dictionary {
            status = DeviceStatus(statusDict as AnyObject)
        }
        
        self.id = id
        self.macAddress = macAddress
        _isConnected = isConnected
    }
    
    public class func array(_ objects: [Any]?) -> [DeviceModel] {
        var devices: [DeviceModel] = []
        
        for object in objects ?? [] {
            if let device = DeviceModel(object as AnyObject) {
                devices.append(device)
            } else if let dict = object as? NSDictionary, let id = dict["id"] as? String, let device = DevicesHelper.getOneLocally(id) {
                devices.append(device)
            }
        }
        
        return devices
    }
    
    public func setStatus(_ status: DeviceStatus) {
        self.status = status
    }
    
    public func setStatus(_ device: DeviceModel) {
        self.status = device.status
    }
    
    public func setNickname(_ nickname: String) {
        self.nickname = nickname
    }
    
    public func setIsLocked(_ isLocked: Bool) {
        self.systemModeLocked = isLocked
    }
    
    public func equalsTo(_ device: DeviceModel) -> Bool {
        let selfAddress = String(format: "%p", unsafeBitCast(self, to: Int.self))
        let deviceAddress = String(format: "%p", unsafeBitCast(device, to: Int.self))
        
        if selfAddress == deviceAddress {
            return true
        }
        
        return false
    }
}

internal class DeviceToPair {
    
    public var nickname = ""
    public let model: String
    public let typeFriendly: String
    public let type: String
    public var locationId: String?
    public let image: UIImage?
    public var qrCode: DeviceQRCode? {
        didSet {
            if let qrCodeUnwrapped = qrCode, qrCodeUnwrapped.deviceId == nil {
                qrCode?.deviceId = macAddress
            }
        }
    }
    public var newWiFi: WiFiModel?
    fileprivate let macAddress: String?
    
    init(model: String, type: String, locationId: String? = nil) {
        self.model = model
        self.type = type
        typeFriendly = DevicesHelper.getTypeFriendly(type)
        self.locationId = locationId
        macAddress = nil
        image = UIImage(named: type) ?? UIImage(named: model)
    }
    
    init(device: DeviceModel, locationId: String) {
        nickname = device.nickname
        model = device.model
        type = device.type
        typeFriendly = DevicesHelper.getTypeFriendly(type)
        self.locationId = locationId
        macAddress = device.macAddress
        image = UIImage(named: device.type) ?? UIImage(named: device.model)
    }
    
    public var pairingCompleteModel: [String: AnyObject] {
        var dictionary = [String: AnyObject]()
        let locationDict: [String: AnyObject] = ["id": locationId as AnyObject]
        
        dictionary["macAddress"] = (macAddress ?? qrCode?.deviceId ?? "") as AnyObject
        dictionary["nickname"] = nickname as AnyObject
        dictionary["location"] = locationDict as AnyObject
        dictionary["deviceType"] = type as AnyObject
        dictionary["deviceModel"] = model as AnyObject
        
        return dictionary
    }
}

internal class DeviceQRCode: JsonParsingProtocol {
    
    public let apName: String
    public var deviceId: String?
    public let loginToken: String
    public let clientCert: String
    public let clientKey: String
    public let serverCert: String
    public let websocketCert: String
    public let websocketCertDer: String
    public let websocketKey: String
    public let firestoreToken: String
    
    required init?(_ object: AnyObject?) {
        let json = JSON(object as? [String: AnyObject] ?? [:])
        guard
            let apName = json["ap_name"].string ?? json["apName"].string,
            let loginToken = json["login_token"].string ?? json["loginToken"].string,
            let clientCert = json["client_cert"].string ?? json["clientCert"].string,
            let clientKey = json["client_key"].string ?? json["clientKey"].string,
            let serverCert = json["server_cert"].string ?? json["serverCert"].string,
            let websocketCert = json["websocket_cert"].string ?? json["websocketCert"].string,
            let websocketCertDer = json["websocket_cert_der"].string ?? json["websocketCertDer"].string,
            let websocketKey = json["websocket_key"].string ?? json["websocketKey"].string
        else {
            LoggerHelper.log("Error parsing DeviceQRCode", level: .error)
            return nil
        }
        
        let firestoreDict = json["firestore"].dictionary
        let firestoreToken = firestoreDict?["token"]?.string ?? StatusManager.shared.firestoreToken
        
        self.apName = apName
        self.deviceId = json["device_id"].string ?? json["deviceId"].string
        self.loginToken = loginToken
        self.clientCert = clientCert
        self.clientKey = clientKey
        self.serverCert = serverCert
        self.websocketCert = websocketCert
        self.websocketCertDer = websocketCertDer
        self.websocketKey = websocketKey
        self.firestoreToken = firestoreToken
    }
}

internal class DeviceStatus: JsonParsingProtocol {
    
    public var dictionary: [String: AnyObject]
    public let macAddress: String
    public let gpm: Double
    public let psi: Double
    public let tempF: Double
    public let isConnected: Bool
    public let isInstalled: Bool?
    public var valveState: ValveState
    public let systemMode: SystemMode
    public let wiFiSignal: Int
    public var healthTestStatus: HealthTestStatus?
    public var consumptionToday: Double?
    public var updated: Date?
    public let alertsAmount: Int
    public let willShutOffAt: Date?
    
    required init?(_ object: AnyObject?) {
        dictionary = object as? [String: AnyObject] ?? [:]
        let json = JSON(dictionary)
        guard
            let macAddress = json["deviceId"].string
        else {
            LoggerHelper.log("Error parsing DeviceStatus", level: .error)
            return nil
        }
        
        let telemetry = json["telemetry"].dictionaryValue
        let currentTelemetry = telemetry["current"]?.dictionaryValue
        let gpm = currentTelemetry?["gpm"]?.double ?? 0.0
        let psi = currentTelemetry?["psi"]?.double ?? 0.0
        let tempF = currentTelemetry?["tempF"]?.double ?? 0.0
        let isConnected = json["isConnected"].bool ?? false
        let modeDict = json["systemMode"].dictionaryValue
        let connectionDict = json["connectivity"].dictionaryValue
        
        let installDict = json["installStatus"].dictionaryValue
        isInstalled = installDict["isInstalled"]?.bool
        
        let systemModeKey = modeDict["target"]?.string ?? (modeDict["lastKnown"]?.string ?? "sleep")
        systemMode = SystemMode(rawValue: systemModeKey) ?? .sleep
        
        wiFiSignal = connectionDict["rssi"]?.int ?? 0
        
        self.macAddress = macAddress
        self.gpm = gpm
        self.psi = psi
        self.tempF = tempF
        self.isConnected = isConnected
        
        if let healthTestStatus = json["healthTest"].dictionary?["status"]?.string {
            self.healthTestStatus = HealthTestStatus(rawValue: healthTestStatus)
        }
        
        if let consumptionToday = json["waterConsumption"].dictionary?["estimateToday"]?.double {
            self.consumptionToday = consumptionToday
        }
        
        let valveDict = json["valve"].dictionaryValue
        var valveStateKey = valveDict["lastKnown"]?.string ?? "closed"
        if valveStateKey == "opened" { valveStateKey = "open" }
        
        if healthTestStatus == .running && (ValveState(rawValue: valveStateKey) ?? .closed) == .closed {
            valveState = .testRunning
        } else {
            valveState = ValveState(rawValue: valveStateKey) ?? .closed
        }
        
        self.updated = json["updated"].string != nil ?
            json["updated"].string?.toDate(withFormat: "yyyy-MM-dd'T'HH:mm:ssZ") : nil
        
        alertsAmount = json["notifications"]["pending"]["alarmCount"].arrayValue.count
        
        let shutOffDate = json["shutoff"]["scheduledAt"].string?.toDate(withFormat: "yyyy-MM-dd'T'HH:mm:ssZ") ?? Date()
        willShutOffAt = shutOffDate > Date() ? shutOffDate : nil
    }
    
}
