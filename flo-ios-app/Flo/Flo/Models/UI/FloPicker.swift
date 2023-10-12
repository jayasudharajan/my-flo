//
//  FloPicker.swift
//  Flo
//
//  Created by Maurice Bachelor on 6/30/16.
//  Copyright © 2016 Flo Technologies. All rights reserved.
//

import Foundation
import UIKit
import DownPicker

internal class FloPicker: DownPicker {
    public weak var delegate: FloPickerDelegate?
    
    override init(textField tf: UITextField!) {
        super.init(textField: tf)
    }
    
    override init(textField: UITextField!, withData: [Any]!) {
        super.init(textField: textField, withData: withData)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    override func textFieldDidBeginEditing(_ textField: UITextField) {
      delegate?.didBeginEdit?(textField)
    }
    override func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.didEndEdit?(textField)
    }
    override func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        super.pickerView(pickerView, didSelectRow: row, inComponent: component)
        delegate?.pickerDidSelectRow(self, row: row)
    }
}
