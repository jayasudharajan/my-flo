//
//  Float+Utils.swift
//  Flo
//
//  Created by Matias Paillet on 6/14/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

extension Float {
    var clean: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }
}
