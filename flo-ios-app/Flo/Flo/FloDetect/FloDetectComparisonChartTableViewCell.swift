//
//  FloDetectComparisonChartTableViewCell.swift
//  Flo
//
//  Created by Nicolás Stefoni on 16/09/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import PieCharts

internal protocol FloDetectChartCellDelegate: class {
    func addFloDetect()
}

internal class FloDetectComparisonChartTableViewCell: UITableViewCell {
    
    fileprivate let kItemWidth: CGFloat = 48
    fileprivate let kMinHorizontalMargin: CGFloat = 20
    fileprivate weak var delegate: FloDetectChartCellDelegate?
    fileprivate var fixtures: [FixtureModel] = []
    fileprivate var computationStatus: ComputationStatus = .executed
    
    @IBOutlet fileprivate weak var chartView: PieChart!
    @IBOutlet fileprivate weak var selectedChartView: PieChart!
    @IBOutlet fileprivate weak var notSubscribedView: UIView!
    @IBOutlet fileprivate weak var chartContainerView: UIView!
    @IBOutlet fileprivate weak var fixturesCollectionView: UICollectionView!
    
    @IBOutlet fileprivate weak var selectedFixtureContainerView: UIView!
    @IBOutlet fileprivate weak var fixtureView: UIView!
    @IBOutlet fileprivate weak var fixtureImageView: UIImageView!
    @IBOutlet fileprivate weak var fixtureNameLabel: UILabel!
    @IBOutlet fileprivate weak var fixtureGallonsLabel: UILabel!
    @IBOutlet fileprivate weak var fixtureRatioLabel: UILabel!
    
    @IBOutlet fileprivate weak var infoContainerView: UIView!
    @IBOutlet fileprivate weak var infoTitleLabel: UILabel!
    @IBOutlet fileprivate weak var infoDescriptionLabel: UILabel!
    
    @IBOutlet fileprivate weak var totalView: UIView!
    @IBOutlet fileprivate weak var totalLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        notSubscribedView.layer.cornerRadius = 8
        notSubscribedView.layer.shadowRadius = 6
        notSubscribedView.layer.shadowOffset = CGSize(width: 0, height: 6)
        notSubscribedView.layer.shadowOpacity = 0.3
        notSubscribedView.layer.shadowColor = StyleHelper.colors.darkBlue.cgColor
        notSubscribedView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(addFloDetect)))
        
        chartView.innerRadius = chartView.frame.width / 3
        chartView.outerRadius = chartView.frame.width / 2
        
        selectedChartView.innerRadius = selectedChartView.frame.width / 3
        selectedChartView.outerRadius = selectedChartView.frame.width / 2
        selectedChartView.animDuration = 0
        selectedChartView.selectedOffset = 0
        selectedChartView.delegate = self
        
        fixtureView.layer.cornerRadius = fixtureView.frame.height / 2
        
        totalView.layer.cornerRadius = 8
        totalView.layer.borderColor = UIColor(hex: "EBEFF5").cgColor
        totalView.layer.borderWidth = 1
    }
    
    @objc fileprivate func addFloDetect() {
        delegate?.addFloDetect()
    }

    // MARK: - PieChart methods
    public func configure(computation: FixturesComputationModel, delegate: FloDetectChartCellDelegate) {
        fixtures = computation.fixtures.filter({ (fixture) -> Bool in
            return fixture.consumption > 0
        })
        computationStatus = computation.status
        self.delegate = delegate
        fixturesCollectionView.reloadData()
        reset()
        
        chartContainerView.alpha = computation.status == .notSubscribed ? 0.3 : 1
        fixturesCollectionView.alpha = computation.status == .notSubscribed ? 0.3 : 1
        notSubscribedView.isHidden = computation.status != .notSubscribed
        
        var total: Double = 0
        for fixture in fixtures {
            total += fixture.consumption
        }
        totalLabel.text = String(format: "%.1f \(MeasuresHelper.unitAbbreviation(for: .volume))", total)
        
        if computationStatus == .executed || computationStatus == .notSubscribed {
            selectedFixtureContainerView.isHidden = false
            infoContainerView.isHidden = true
            
            var models: [PieSliceModel] = []
            var clearModels: [PieSliceModel] = []
            var maxConsumptionFixture: FixtureModel?
            var maxConsumption: Double = -1
            var totalConsumption: Double = 0
            
            for fixture in fixtures {
                totalConsumption += fixture.consumption
                models.append(PieSliceModel(value: fixture.consumption, color: fixture.type.color, obj: fixture.type))
                clearModels.append(PieSliceModel(value: fixture.consumption, color: .clear, obj: fixture.type))
                
                if fixture.consumption > maxConsumption {
                    maxConsumption = fixture.consumption
                    maxConsumptionFixture = fixture
                }
            }
            
            chartView.models = models
            selectedChartView.models = clearModels
            
            if let fixture = maxConsumptionFixture {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.setFixture(fixture, selected: true)
                })
            }
        } else {
            selectedFixtureContainerView.isHidden = true
            infoContainerView.isHidden = false
            
            if computationStatus == .noUsage {
                infoTitleLabel.text = "no_fixture_data_detected".localized
                infoDescriptionLabel.text = "no_fixture_data_detected_description".localized
            } else if computationStatus == .learning {
                infoTitleLabel.text = "learning".localized
                infoDescriptionLabel.text = "fixture_learning_description".localized
            }
            
            selectedChartView.models = [PieSliceModel(value: 100, color: StyleHelper.colors.lightBlue, obj: nil)]
        }
    }
    
    fileprivate func reset() {
        for layer in chartView.layers {
            layer.clear()
        }
        chartView.models = []
        chartView.removeSlices()
        
        for layer in selectedChartView.layers {
            layer.clear()
        }
        selectedChartView.models = []
        selectedChartView.removeSlices()
    }
    
    fileprivate func setFixture(_ fixture: FixtureModel, selected: Bool) {
        DispatchQueue.main.async {
            for slice in self.selectedChartView.slices {
                if let type = slice.data.model.obj as? FixtureType, type == fixture.type {
                    if !slice.view.selected {
                        slice.view.selected = true
                    }
                    slice.view.color = type.color
                } else {
                    slice.view.color = .clear
                }
            }
            
            if selected {
                self.fixtureView.backgroundColor = fixture.type.color.withAlphaComponent(0.2)
                self.fixtureImageView.tintColor = fixture.type.color
                self.fixtureImageView.image = fixture.type.image
                self.fixtureNameLabel.text = fixture.type.name
                self.fixtureGallonsLabel.text = String(format: "%.1f ", fixture.consumption) + MeasuresHelper.unitAbbreviation(for: .volume)
                self.fixtureRatioLabel.text = "\(Int(fixture.ratio * 100))%"
            }
        }
    }
}

extension FloDetectComparisonChartTableViewCell: PieChartDelegate {
    
    func onSelected(slice: PieSlice, selected: Bool) {
        if let fixtureType = slice.data.model.obj as? FixtureType {
            for fixture in fixtures where fixture.type == fixtureType {
                setFixture(fixture, selected: selected)
                break
            }
        }
    }
}

extension FloDetectComparisonChartTableViewCell: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fixtures.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FixtureCollectionItem", for: indexPath)
        if let fixtureView = cell.contentView.subviews.first {
            fixtureView.layer.cornerRadius = fixtureView.frame.height / 2
            fixtureView.backgroundColor = fixtures[indexPath.row].type.color
            
            let fixtureImageView = fixtureView.subviews.first as? UIImageView
            fixtureImageView?.tintColor = .white
            fixtureImageView?.image = fixtures[indexPath.row].type.image
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if computationStatus == .executed || computationStatus == .notSubscribed {
            setFixture(fixtures[indexPath.row], selected: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        var inset = UIEdgeInsets(top: 0, left: kMinHorizontalMargin, bottom: 0, right: kMinHorizontalMargin)
        let widthItemsSeparated = kItemWidth * CGFloat(fixtures.count) + kMinHorizontalMargin * CGFloat(fixtures.count - 1)
        
        if widthItemsSeparated + kMinHorizontalMargin * 2 < collectionView.frame.width {
            let lateralMargin = (collectionView.frame.width - widthItemsSeparated) / 2
            inset.left = lateralMargin
            inset.right = lateralMargin
        }
        
        return inset
    }
}
