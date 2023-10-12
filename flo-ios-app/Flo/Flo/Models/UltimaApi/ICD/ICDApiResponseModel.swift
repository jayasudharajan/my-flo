//
//  FloGatewayBaseApiResult.swift
//  Flo
//
//  Created by Maurice Bachelor on 3/22/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import ObjectMapper

internal class ICDAPIResponseModel<TResult, TParam>: ICDBaseModel {
    public var fromMethod: String?
    public var result: TResult?
    public var fromParams: TParam?
}
