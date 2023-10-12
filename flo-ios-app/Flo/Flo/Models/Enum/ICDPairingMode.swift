//
//  Enums.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/16/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

internal enum ICDWebSocketMode {
    case connectedSocket
    case scanWifi
    case uploadedCerts
    case icdSetConfig
}

internal enum ICDWebSocketGoal {
    case none
    case getICDAvailbleWifiList
    case updateICDNetworkSettings
    case uploadCertFiles
}
