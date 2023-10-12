//
//  FloRequestErrorModel.swift
//  Flo
//
//  Created by Maurice Bachelor on 6/29/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

internal final class FloRequestErrorModel {
    
    public var title: String
    public var message: String
    public var originalServerMessage: String?
    public var status: Int?
    
    init(title: String, message: String, status: Int?, serverMessage: String? = nil) {
        self.title = title
        self.message = message
        self.status = status
        self.originalServerMessage = serverMessage
    }
    
}
