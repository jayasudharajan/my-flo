//
//  RequestMethodType.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/31/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

internal enum RequestMethodType {
    case post
    case get
    case delete
    case put
}

extension RequestMethodType {
    func toString() -> String {
        switch self {
        case .post:
            return "post"
        case .get:
            return "get"
        case .delete:
            return "delete"
        case .put:
            return "put"
        }
    }
}
