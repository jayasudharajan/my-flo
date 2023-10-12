//
//  ICDPairingWebSocketModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 4/14/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import Starscream
import Crashlytics

open class ICDPairingWebSocketModel: WebSocketDelegate {
    
    // MARK: - Singleton
    class var sharedInstance: ICDPairingWebSocketModel {
        struct Static {
            static let instance = ICDPairingWebSocketModel()
        }
        return Static.instance
    }
    
    var icdLoginToken: String?
    weak var delegate: FloWebSocketSsidDelegate?
    
    var socket: WebSocket
    var socketMode: ICDWebSocketMode?
    var socketGoal: ICDWebSocketGoal
    var homeWiFiData: WiFiModel?
    var certDataRequest: ICDCertUploadRequestModel?
    
    fileprivate init() {
        LoggerHelper.log("First connect", object: "wss://192.168.3.1:8000", level: .debug)
        
        socket = WebSocket(url: URL(string: "wss://192.168.3.1:8000")!)
        socketGoal = .none
        socket.overrideTrustHostname = true
        //socket.desiredTrustHostname = "flodevice"
    }
    
    // Should be called when the connection to the device using the gateway ip failed.
    // This method needs some time after the wificonnection is made with the device, so the DNS Table has time to propagate.
    public func reconfigureWithDNS() {
        LoggerHelper.log("Reconfiguring DNS to", object: "wss://flodevice:8000", level: .debug)
        
        let oldSocket = socket
        if socket.isConnected {
            socket.disconnect()
        }
        
        socket = WebSocket(url: URL(string: "wss://flodevice:8000")!)
        socket.overrideTrustHostname = true
        socket.desiredTrustHostname = "flodevice"
        socket.security = oldSocket.security
        socket.disableSSLCertValidation = oldSocket.disableSSLCertValidation
    }
    
    public func setSelfSignedCertificate(_ data: Data) {
        socket.security = SSLSecurity(certs: [SSLCert(data: data)], usePublicKeys: false)
        socket.disableSSLCertValidation = true
    }
    
    internal func setGoal(_ goal: ICDWebSocketGoal, icdLoginToken: String) {
        socketGoal = goal
        self.icdLoginToken = icdLoginToken
    }
    
    internal func setGoalWithCert(_ goal: ICDWebSocketGoal, icdLoginToken: String, certDataRequest: ICDCertUploadRequestModel) {
        socketGoal = goal
        self.icdLoginToken = icdLoginToken
        self.certDataRequest = certDataRequest
    }
    
    public func connectICDWebSocket() {
        connectWebSocket()
    }
    
    public func connectWebSocket() {
        if isICDConnected() {
            socketMode = .connectedSocket
            webSocketMessageHandler("emulated-connect")
        } else {
            socket.delegate = self
            LoggerHelper.log("Will connect", object: socketGoal, level: .debug)
            socket.connect()
        }
    }
    
    public func disconnect() {
        LoggerHelper.log("Will disconnect", level: .debug)
        socket.disconnect(forceTimeout: -1)
    }
    
    public func isICDConnected() -> Bool {
        return socket.isConnected
    }
    
    public func websocketDidConnect(socket: WebSocketClient) {
        LoggerHelper.log("Connected", level: .debug)
        
        loginGatewayWebSocket()
    }
    
    public func loginGatewayWebSocket() {
        if let token = icdLoginToken {
            if let loginInfo = ICDLoginRequestModel(token: token).toJSONString(prettyPrint: false) {
                socketMode = .connectedSocket
                LoggerHelper.log("Sending connection info", object: loginInfo, level: .debug)
                socket.write(string: loginInfo)
            }
        }
    }
    
    public func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        if let e = error {
            LoggerHelper.log("Disconnected", object: e.localizedDescription, level: .debug)
            
            if e.localizedDescription == "The operation couldn’t be completed. Socket is not connected" || e.localizedDescription == "write wait timed out" {
                if socketMode == .icdSetConfig {//We are kicked off icd wifi
                    if let d = delegate as? FinalPairingViewController {
                        d.finishedIcdNetworkSettingUpdateCheckIfOnline() //UPDATE to check MQTT
                    }
                } else {
                     LoggerHelper.log("websocket is disconnected: \(e.localizedDescription)", level: .debug)
                }
            } else {
                LoggerHelper.log("Socket purposely disconnected: \(e.localizedDescription)", level: .debug)
            }
        } else {
            LoggerHelper.log("Disconnected", level: .debug)
        }
    }
    
    public func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        LoggerHelper.log("Received message", object: text, level: .debug)
        
        webSocketMessageHandler(text)
    }
    
    public func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        LoggerHelper.log("Received data", object: data, level: .debug)
    }
    
    fileprivate func webSocketMessageHandler(_ text: String) {
        if let mode = socketMode {
            switch mode {
            case .connectedSocket:
                if socketGoal == .getICDAvailbleWifiList {
                    getGatewayAvailableSsids()
                } else if socketGoal == .uploadCertFiles {
                    if certDataRequest != nil {
                        uploadCerts()
                    }
                } else if socketGoal == .updateICDNetworkSettings {
                    updateICDNetworkSettings()
                }
            case .scanWifi:
                if let ssids: IcdWifiScanResponseModel = text.convertToObject(), let result = ssids.result {
                    delegate?.receievedIcdSsids!(result)
                }
            case .icdSetConfig:
                //More than likely we will not get here due to kicking us off when network settings are updated
                socket.disconnect()
                if let result: ICDSetNetworkConfigResponseModel = text.convertToObject(), let r = result.result {
                    if r {
                        delegate?.finishedIcdNetworkSettingUpdateCheckIfOnline!()
                    } else {
                        delegate?.errorSavingIcdClientCredintials!()
                    }
                } else {
                    delegate?.finishedIcdNetworkSettingUpdateCheckIfOnline!()
                }
            case .uploadedCerts:
                LoggerHelper.log("Certificates uploaded", level: .debug)
                delegate?.finishedUploadingCerts!()
            }
        }
    }
    
    fileprivate func getGatewayAvailableSsids() {
        if let gatewaySsidList = IcdWifiScanRequestModel().toJSONString(prettyPrint: false) {
            socketMode = .scanWifi
            LoggerHelper.log("Requesting available SSIDs", object: gatewaySsidList, level: .debug)
            socket.write(string: gatewaySsidList)
        }
    }
    
    fileprivate func uploadCerts() {
        if let certRequest = certDataRequest {
            if let json = certRequest.toJSONString(prettyPrint: false) {
                self.socketMode = .uploadedCerts
                LoggerHelper.log("Uploading certificates", object: json, level: .debug)
                self.socket.write(string: json)
            }
        } else {
            LoggerHelper.log("Certificates upload failed", level: .error)
            delegate?.errorUploadingCertFiles!()
        }
    }
    
    fileprivate func updateICDNetworkSettings() {
        if let wifidata = homeWiFiData {
            let config = NetworkConfigModel(wifidata)
            if let setConfig = ICDSetNetworkConfigRequestModel(config: config).toJSONString(prettyPrint: false) {
                socketMode = .icdSetConfig
                LoggerHelper.log("Updating network settings", object: setConfig, level: .debug)
                socket.write(string: setConfig)
            }
        } else {
            delegate?.errorUpdatingIcdNetworkSettings!("Error: Please re-enter WiFi Information")
        }
    }
    
}
