//
//  ICDSetCertModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 4/26/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

internal class ICDSetCertModel: Mappable {
    
    public var encodedCaCert: String?
    public var encodedClientCert: String?
    public var encodedClientKey: String?
    
    init(serverCert: String, clientCert: String, clientKey: String) {
        encodedCaCert = serverCert
        encodedClientCert = clientCert
        encodedClientKey = clientKey
    }
    
    required init?(map: Map) {}
    
    func mapping(map: Map) {
        encodedCaCert <- map["encoded_ca_cert"]
        encodedClientCert <- map["encoded_client_cert"]
        encodedClientKey <- map["encoded_client_key"]
    }
}
