//
//  FloPickerDelegate.swift
//  Flo
//
//  Created by Maurice Bachelor on 6/30/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import UIKit

@objc internal protocol FloPickerDelegate: class {
    @objc optional func didBeginEdit(_ textField: UITextField)
    @objc optional func didEndEdit(_ textField: UITextField)
    func pickerDidSelectRow(_ picker: FloPicker, row: Int)
}
