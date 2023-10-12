//
//  FloWebSocketDelelgate.swift
//  Flo
//
//  Created by Maurice Bachelor on 4/14/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation

@objc protocol FloWebSocketSsidDelegate: class {
    @objc optional func receievedIcdSsids(_ ssids: [WiFiModel]?)
    @objc optional func errorUpdatingIcdNetworkSettings(_ message: String)
    @objc optional func finishedIcdNetworkSettingUpdateCheckIfOnline()
    @objc optional func errorUploadingCertFiles()
    @objc optional func errorSavingIcdClientCredintials()
    @objc optional func finishedUploadingCerts()
}
