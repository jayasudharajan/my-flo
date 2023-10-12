//
//  FloOptionButtonCell.swift
//  Flo
//
//  Created by Matias Paillet on 10/4/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

internal class FloOptionButtonCell: UITableViewCell {

    @IBOutlet fileprivate weak var option: FloOptionButton!

    fileprivate var didPressOption: (() -> Void)?

    @IBAction public func didPressOptionButton(_ button: FloOptionButton) {
        didPressOption?()
    }

    public func configure(name: String, selected: Bool, didPressOption: @escaping (() -> Void)) {
        option.isSelected = selected
        option.setTitle(name, for: .normal)
        self.didPressOption = didPressOption
    }
}
