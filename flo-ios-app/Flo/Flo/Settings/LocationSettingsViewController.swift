//
//  LocationSettingsViewController.swift
//  Flo
//
//  Created by Josefina Perez on 11/07/2019.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

import UIKit
import EasyTipView

internal class LocationSettingsViewController: FloBaseViewController, UITableViewDelegate,
    UITableViewDataSource, FloPickerDelegate, AmenitiesCellDelegate {
    
    @IBOutlet fileprivate weak var txtAddressLine1: UITextField!
    @IBOutlet fileprivate weak var txtAddressLine2: UITextField!
    @IBOutlet fileprivate weak var txtCountry: UITextField!
    @IBOutlet fileprivate weak var txtCity: UITextField!
    @IBOutlet fileprivate weak var txtState: UITextField!
    @IBOutlet fileprivate weak var txtStateFreeText: UITextField!
    @IBOutlet fileprivate weak var txtZipcode: UITextField!
    @IBOutlet fileprivate weak var txtTimezone: UITextField!
    @IBOutlet fileprivate weak var btnPlus: UIButton!
    @IBOutlet fileprivate weak var btnMinus: UIButton!
    @IBOutlet fileprivate weak var btnOccupants: UIButton!
    @IBOutlet fileprivate weak var homeTypeTableView: UITableView!
    @IBOutlet fileprivate weak var homeTypeTableViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var homeUsageTableView: UITableView!
    @IBOutlet fileprivate weak var homeUsageTableViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var homeSizeTableView: UITableView!
    @IBOutlet fileprivate weak var homeSizeTableViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var numberOfFloorsTableView: UITableView!
    @IBOutlet fileprivate weak var numberOfFloorsTableViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var bathrooms: UISlider!
    @IBOutlet fileprivate weak var typesOfPlumbingTableView: UITableView!
    @IBOutlet fileprivate weak var typesOfPlumbingTableViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var sourcesOfWaterTableView: UITableView!
    @IBOutlet fileprivate weak var sourcesOfWaterTableViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var indoorAmenitiesTableView: UITableView!
    @IBOutlet fileprivate weak var indoorAmenitiesTableViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var outdoorAmenitiesTableView: UITableView!
    @IBOutlet fileprivate weak var outdoorAmenitiesTableViewHeight: NSLayoutConstraint!
    @IBOutlet fileprivate weak var plumbingAppliancesTableView: UITableView!
    @IBOutlet fileprivate weak var plumbingAppliancesTableViewHeight: NSLayoutConstraint!
    
    fileprivate let kRadioButtonOptionCellHeight: CGFloat = 43
    fileprivate var bathroomTooltip: EasyTipView?
    fileprivate var bathroomTooltipPreferences: EasyTipView.Preferences?
    fileprivate var validator: Validator!
    fileprivate var countryPicker: FloPicker?
    fileprivate var statePicker: FloPicker?
    fileprivate var timezonePicker: FloPicker?
    
    fileprivate var pipeTypeOptions: [PipeType] = []
    fileprivate var homeUsageOptions: [ResidenceType] = []
    fileprivate var indoorsAmenities: [BaseListModel] = []
    fileprivate var outdoorsAmenities: [BaseListModel] = []
    fileprivate var plumbingAmenities: [BaseListModel] = []
    
    public var location: LocationModel!
    
    fileprivate func textFieldsToValidate() -> [UITextField] {
        return [txtAddressLine1, txtCity, txtZipcode, txtCountry, txtState, txtTimezone]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeBuilder()
        
        view.layer.addGradient(from: StyleHelper.colors.darkBlue, to: StyleHelper.colors.gradient1Secondary, angle: 90)
        setupNavBarWithBack(andTitle: "home_profile".localized, tint: StyleHelper.colors.white,
                            titleColor: StyleHelper.colors.white)
        
        btnPlus.styleSquareWithRoundCorners(borderColor: StyleHelper.colors.gray.cgColor)
        btnMinus.styleSquareWithRoundCorners(borderColor: StyleHelper.colors.gray.cgColor)
        btnOccupants.styleSquareWithRoundCorners(borderColor: StyleHelper.colors.gray.cgColor)
        
        bathroomTooltipPreferences = EasyTipView.Preferences()
        bathroomTooltipPreferences?.drawing.foregroundColor = StyleHelper.colors.white
        bathroomTooltipPreferences?.drawing.backgroundColor = StyleHelper.colors.cyan
        bathroomTooltipPreferences?.animating.dismissDuration = 0.001
        bathroomTooltipPreferences?.animating.dismissOnTap = false
        bathroomTooltipPreferences?.drawing.arrowPosition = .top
        
        self.validator = Validator(objectsToValidate: textFieldsToValidate())
        
        self.pipeTypeOptions = ListsManager.shared.getPipeTypes({ (error, types) in
            if let err = error {
                self.showPopup(error: err)
            } else {
                self.pipeTypeOptions = types
                self.redrawConstraints()
                self.typesOfPlumbingTableView.reloadData()
            }
        })
        
        self.homeUsageOptions = ListsManager.shared.getResidenceTypes({ (error, types) in
            if let err = error {
                self.showPopup(error: err)
            } else {
                self.homeUsageOptions = types
                self.redrawConstraints()
                self.homeUsageTableView.reloadData()
            }
        })
        
        let appliances = ListsManager.shared.getAppliances({ (error, types) in
            if let err = error {
                self.showPopup(error: err)
            } else {
                self.indoorsAmenities = types.first?.indoor ?? []
                self.outdoorsAmenities = types.first?.outdoors ?? []
                self.plumbingAmenities = types.first?.appliances ?? []
                self.redrawConstraints()
                self.indoorAmenitiesTableView.reloadData()
                self.outdoorAmenitiesTableView.reloadData()
                self.plumbingAppliancesTableView.reloadData()
            }
        })
        
        self.indoorsAmenities = appliances.first?.indoor ?? []
        self.outdoorsAmenities = appliances.first?.outdoors ?? []
        self.plumbingAmenities = appliances.first?.appliances ?? []
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        redrawConstraints()
    }
    
    fileprivate func redrawConstraints() {
        homeTypeTableViewHeight.constant = CGFloat(LocationInfoHelper.getHomeTypes().count)
               * kRadioButtonOptionCellHeight + 16
        homeUsageTableViewHeight.constant = CGFloat(self.homeUsageOptions.count)
            * kRadioButtonOptionCellHeight + 16
        homeSizeTableViewHeight.constant = CGFloat(LocationInfoHelper.getLocationSizes().count)
            * kRadioButtonOptionCellHeight + 16
        numberOfFloorsTableViewHeight.constant = CGFloat(LocationInfoHelper.getNumberOfFloors().count)
            * kRadioButtonOptionCellHeight + 16
        typesOfPlumbingTableViewHeight.constant = CGFloat(self.pipeTypeOptions.count)
            * kRadioButtonOptionCellHeight + 16
        sourcesOfWaterTableViewHeight.constant = CGFloat(LocationInfoHelper.getSourcesOfWater().count)
            * kRadioButtonOptionCellHeight + 16
        indoorAmenitiesTableViewHeight.constant = CGFloat(indoorsAmenities.count)
            * kRadioButtonOptionCellHeight + 16
        outdoorAmenitiesTableViewHeight.constant = CGFloat(outdoorsAmenities.count)
            * kRadioButtonOptionCellHeight + 16
        plumbingAppliancesTableViewHeight.constant = CGFloat(plumbingAmenities.count)
            * kRadioButtonOptionCellHeight + 16
    }
    
    fileprivate func initializeBuilder() {
        showLoadingSpinner("please_wait".localized)
        //Initialize builder
        AddLocationBuilder.shared.start({ _ in
            self.hideLoadingSpinner()
            self.setupCountries()
            
            guard let country = AddLocationBuilder.shared.getCountryLocale(countryId: self.location.country) else {
                return
            }
            
            AddLocationBuilder.shared.getSelectedCountryInfo(selectedCountry: country, { _ in
                
                AddLocationBuilder.shared.changeSelectedCountry(country)
                
                if let state = AddLocationBuilder.shared.getRegion(region: self.location.state) {
                    AddLocationBuilder.shared.changeSelectedRegion(state)
                }
                
                if let timezone = AddLocationBuilder.shared.getTimezone(timezoneId: self.location.timezone) {
                    AddLocationBuilder.shared.changeSelectedTimezone(timezone)
                }
                
                self.setupStates()
                self.setupTimezones()
                
                self.fillWithLocationInfo()
            })
        
        })
        
        AddLocationBuilder.shared.startWithLocation(self.location)
    }
    
    fileprivate func fillWithLocationInfo() {
        
        txtAddressLine1.text = location.address
        _ = performValidationsOn(txtAddressLine1)
        
        txtAddressLine2.text = location.address2
        
        if let country = AddLocationBuilder.shared.getCountryLocale(countryId: location.country) {
            txtCountry.text = country.name
            validator.markAsValid(txtCountry)
        }
        
        txtCity.text = location.city
        _ = performValidationsOn(txtCity)
        
        if txtStateFreeText.isHidden, let state = AddLocationBuilder.shared.getRegion(region: location.state) {
            txtState.text = state.name
        } else {
            txtStateFreeText.text = location.state
            _ = performValidationsOn(txtStateFreeText)
        }
        validator.markAsValid(txtState)
        
        txtZipcode.text = location.postalCode
        _ = performValidationsOn(txtZipcode)
        
        txtTimezone.text = location.timezone
        validator.markAsValid(txtTimezone)
        
        btnOccupants.setTitle("\(location.occupants)", for: .normal)
        bathrooms.setValue(Float(location.toiletCount * 2), animated: true)
        //Delay this a bit so screen is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.showTooltipInSlider()
        }
    }
    
    // MARK: - Overrides
    override func shouldHideNavBar() -> Bool {
        return false
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get { return true }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    override func goBack() {
        guard !FloApiRequest.demoModeEnabled() else {
            showFeatureNotSupportedInDemoModeAlert()
            super.goBack()
            return
        }
        
        //If validations didn't pass, go back without doing any changes
        if !updateLocation() {
            super.goBack()
        }
    }
    
    // MARK: Country Picker
    
    fileprivate func setupCountries() {
        var displayNames = [String?]()
        for locale in LocationInfoHelper.countries {
            displayNames.append(locale.name)
        }
        self.countryPicker = FloPicker(textField: self.txtCountry, withData: displayNames as [AnyObject])
        self.countryPicker?.setPlaceholder("select_a_country".localized)
        self.countryPicker?.shouldDisplayCancelButton = false
        self.countryPicker?.delegate = self
        txtCountry.inputView = countryPicker
        txtCountry.addRightImage(named: "arrow-down-blue", withTarget: self, andAction: #selector(self.openCountryPicker))
    }
    
    @objc fileprivate func openCountryPicker() {
        txtCountry.becomeFirstResponder()
    }
    
     // MARK: State Picker
    fileprivate func cleanStateField() {
        self.txtState.text = ""
        self.txtStateFreeText.text = ""
        self.txtState.rightView = nil
        validator.markAsInvalid(txtState)
    }
    
    fileprivate func setupStates() {
        
        guard let states = AddLocationBuilder.shared.selectedCountry?.regions, states.count > 0 else {
            self.txtStateFreeText.isHidden = false
            return
        }
        
        self.txtStateFreeText.isHidden = true
        LocationInfoHelper.states = states
        var displayNames = [String?]()
        for region in LocationInfoHelper.states {
            displayNames.append(region.name)
        }
        self.statePicker = FloPicker(textField: self.txtState, withData: displayNames as [AnyObject])
        self.statePicker?.setPlaceholder("state".localized)
        self.statePicker?.shouldDisplayCancelButton = false
        self.statePicker?.delegate = self
        DispatchQueue.main.async {
            self.txtState.addRightImage(named: "arrow-down-blue", withTarget: self, andAction: #selector(self.openStatePicker))
        }
    }
    
    @objc fileprivate func openStatePicker() {
        txtState.becomeFirstResponder()
    }
    
    fileprivate func showTooltipInSlider() {
        for v in bathrooms.subviews {
            if let target = v as? UIImageView, target.subviews.count > 0 {
                self.bathroomTooltip?.dismiss()
                self.bathroomTooltip = EasyTipView(text: (self.bathrooms.value / 2).clean, preferences: self.bathroomTooltipPreferences!)
                self.bathroomTooltip?.show(animated: false, forView: target, withinSuperview: self.bathrooms)
            }
        }
    }
    
    // MARK: Timezone Picker
    
    fileprivate func cleanTimeZoneField() {
        self.txtTimezone.text = ""
        self.txtTimezone.rightView = nil
        validator.markAsInvalid(txtTimezone)
    }
    
    fileprivate func setupTimezones() {
        
        guard let timezones = AddLocationBuilder.shared.selectedCountry?.timezones else {
            return
        }
        
        LocationInfoHelper.timezones = timezones
        var displayNames = [String?]()
        for timezone in LocationInfoHelper.timezones {
            displayNames.append(timezone.name)
        }
        self.timezonePicker = FloPicker(textField: self.txtTimezone, withData: displayNames as [AnyObject])
        self.timezonePicker?.setPlaceholder("timezone".localized)
        self.timezonePicker?.shouldDisplayCancelButton = false
        self.timezonePicker?.delegate = self
        DispatchQueue.main.async {
            self.txtTimezone.addRightImage(named: "arrow-down-blue", withTarget: self, andAction: #selector(self.openTimezonePicker))
        }
    }
    
    @objc fileprivate func openTimezonePicker() {
        txtTimezone.becomeFirstResponder()
    }
    
    fileprivate func resetStateAndTimezonePickers() {
        AddLocationBuilder.shared.changeSelectedRegion(nil)
        setupStates()
        AddLocationBuilder.shared.changeSelectedTimezone(nil)
        setupTimezones()
    }
    
    // MARK: - Text field delegate
    override public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override public func textFieldDidEndEditing(_ textField: UITextField) {
        _  = performValidationsOn(textField)
        return
    }
    
    // MARK: FloPickerDelegate
    
    func pickerDidSelectRow(_ picker: FloPicker, row: Int) {
        
        switch picker {
        case countryPicker:
            let count = LocationInfoHelper.countries.count
            
            guard count > row else {
                return
            }
            
            self.txtCountry.text = LocationInfoHelper.countries[row].name
            AddLocationBuilder.shared.changeSelectedCountry(LocationInfoHelper.countries[row]) { (success) in
                if success {
                    self.resetStateAndTimezonePickers()
                }
            }
            AddLocationBuilder.shared.changeSelectedRegion(nil)
            cleanStateField()
            AddLocationBuilder.shared.changeSelectedTimezone(nil)
            cleanTimeZoneField()
            
            if AddLocationBuilder.shared.selectedCountry != nil {
                self.validator.markAsValid(txtCountry)
            } else {
                self.validator.markAsInvalid(txtCountry)
            }
            
        case statePicker:
            let count = LocationInfoHelper.states.count
            guard count > row else {
                return
            }
            self.txtState.text = LocationInfoHelper.states[row].name
            AddLocationBuilder.shared.changeSelectedRegion(LocationInfoHelper.states[row])
            if AddLocationBuilder.shared.selectedState != nil {
                self.validator.markAsValid(txtState)
            } else {
                self.validator.markAsInvalid(txtState)
            }
            
        case timezonePicker:
            let count = LocationInfoHelper.timezones.count
            guard count > row else {
                return
            }
            self.txtTimezone.text = LocationInfoHelper.timezones[row].name
            AddLocationBuilder.shared.changeSelectedTimezone(LocationInfoHelper.timezones[row])
            if AddLocationBuilder.shared.selectedTimezone != nil {
                self.validator.markAsValid(txtTimezone)
            } else {
                self.validator.markAsInvalid(txtTimezone)
            }
            
        default:
            break
        }
    }
    
    // MARK: - Table view delegate and data source
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case homeTypeTableView:
            return LocationInfoHelper.getHomeTypes().count
        case homeUsageTableView:
            return self.homeUsageOptions.count
        case homeSizeTableView:
            return LocationInfoHelper.getLocationSizes().count
        case numberOfFloorsTableView:
            return LocationInfoHelper.getNumberOfFloors().count
        case typesOfPlumbingTableView:
            return self.pipeTypeOptions.count
        case sourcesOfWaterTableView:
            return LocationInfoHelper.getSourcesOfWater().count
        case indoorAmenitiesTableView:
            return indoorsAmenities.count
        case outdoorAmenitiesTableView:
            return outdoorsAmenities.count
        case plumbingAppliancesTableView:
            return plumbingAmenities.count
        default:
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableView {
        case homeTypeTableView:
            guard let radioButtonOptionCell = tableView.dequeueReusableCell(withIdentifier: "radioButtonOptionCell") as?
                RadioButtonOptionTableViewCell else {
                    return UITableViewCell()
            }
            
            let current = AddLocationBuilder.shared.locationType
            let option = LocationInfoHelper.getHomeTypes()[indexPath.row]
            
            radioButtonOptionCell.configure(option: option.displayName,
                                            selected: current == option.backendIdentifier)
            return radioButtonOptionCell
        case homeUsageTableView:
            guard let radioButtonOptionCell = tableView.dequeueReusableCell(withIdentifier: "radioButtonOptionCell") as?
                RadioButtonOptionTableViewCell else {
                    return UITableViewCell()
            }
            
            let currentTypeOfHome = AddLocationBuilder.shared.residenceType
            let locationTypeOfHome = self.homeUsageOptions[indexPath.row]
            
            radioButtonOptionCell.configure(option: locationTypeOfHome.name,
                                            selected: currentTypeOfHome == locationTypeOfHome.id)
            return radioButtonOptionCell
        case homeSizeTableView:
            guard let radioButtonOptionCell = tableView.dequeueReusableCell(withIdentifier: "radioButtonOptionCell") as?
                RadioButtonOptionTableViewCell else {
                    return UITableViewCell()
            }
            
            let currentLocationSize = AddLocationBuilder.shared.locationSize
            let locationSize = LocationInfoHelper.getLocationSizes()[indexPath.row]
            
            radioButtonOptionCell.configure(option: locationSize.displayName,
                                            selected: currentLocationSize == locationSize.backendIdentifier)
            
            return radioButtonOptionCell
        case numberOfFloorsTableView:
            guard let radioButtonOptionCell = tableView.dequeueReusableCell(withIdentifier: "radioButtonOptionCell") as?
                RadioButtonOptionTableViewCell else {
                    return UITableViewCell()
            }
            
            let currentLocationStories = AddLocationBuilder.shared.stories
            let locationStories = LocationInfoHelper.getNumberOfFloors()[indexPath.row]
            
            radioButtonOptionCell.configure(option: locationStories.displayName,
                                            selected: currentLocationStories == locationStories.numberOfFloors)
            return radioButtonOptionCell
        case typesOfPlumbingTableView:
            guard let radioButtonOptionCell = tableView.dequeueReusableCell(withIdentifier: "radioButtonOptionCell") as?
                RadioButtonOptionTableViewCell else {
                    return UITableViewCell()
            }
            
            let currentTypeOfPlumbing = AddLocationBuilder.shared.plumbingType
            let locationTypeOfPlumbing = self.pipeTypeOptions[indexPath.row]
            
            radioButtonOptionCell.configure(option: locationTypeOfPlumbing.name,
                                            selected: currentTypeOfPlumbing == locationTypeOfPlumbing.id)
            return radioButtonOptionCell
        case sourcesOfWaterTableView:
            guard let radioButtonOptionCell = tableView.dequeueReusableCell(withIdentifier: "radioButtonOptionCell") as?
                RadioButtonOptionTableViewCell else {
                    return UITableViewCell()
            }
            
            let currentWaterSource = AddLocationBuilder.shared.waterSource
            let locationWaterSource = LocationInfoHelper.getSourcesOfWater()[indexPath.row]
            
            radioButtonOptionCell.configure(option: locationWaterSource.displayName,
                                            selected: currentWaterSource == locationWaterSource.backendIdentifier)
            return radioButtonOptionCell
        case indoorAmenitiesTableView:
            guard let amenitiesCell = tableView.dequeueReusableCell(withIdentifier: "AmenitiesCell") as? AmenitiesCell else {
                return UITableViewCell()
            }
            
            let currentIndoorAmenities = AddLocationBuilder.shared.indoorAmenities
            let locationIndoorAmenity = indoorsAmenities[indexPath.row]
            amenitiesCell.delegate = self
            amenitiesCell.configure(locationIndoorAmenity,
                                    isSelected: currentIndoorAmenities.contains(locationIndoorAmenity.id),
                                    group: "indoors")
            
            return amenitiesCell
        case outdoorAmenitiesTableView:
            guard let amenitiesCell = tableView.dequeueReusableCell(withIdentifier: "AmenitiesCell") as? AmenitiesCell else {
                return UITableViewCell()
            }
            
            let currentOutdoorAmenities = AddLocationBuilder.shared.outdoorAmenities
            let locationOutdoorAmenity = outdoorsAmenities[indexPath.row]
            
            amenitiesCell.delegate = self
            amenitiesCell.configure(locationOutdoorAmenity,
                                    isSelected: currentOutdoorAmenities.contains(locationOutdoorAmenity.id),
                                    group: "outdoors")
            
            return amenitiesCell
        case plumbingAppliancesTableView:
            guard let amenitiesCell = tableView.dequeueReusableCell(withIdentifier: "AmenitiesCell") as? AmenitiesCell else {
                return UITableViewCell()
            }
            
            let currentPlumbingAmenities = AddLocationBuilder.shared.plumbingAppliances
            let locationPlumbingAmenity = plumbingAmenities[indexPath.row]
            
            amenitiesCell.delegate = self
            amenitiesCell.configure(locationPlumbingAmenity,
                                    isSelected: currentPlumbingAmenities.contains(locationPlumbingAmenity.id),
                                    group: "plumbing")
            
            return amenitiesCell
            
        default:
            return UITableViewCell()
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableView {
        case homeTypeTableView:
            AddLocationBuilder.shared.locationType =
                LocationInfoHelper.getHomeTypes()[indexPath.row].backendIdentifier
        case homeUsageTableView:
            AddLocationBuilder.shared.residenceType = self.homeUsageOptions[indexPath.row].id
        case homeSizeTableView:
            AddLocationBuilder.shared.locationSize =
                LocationInfoHelper.getLocationSizes()[indexPath.row].backendIdentifier
        case numberOfFloorsTableView:
            AddLocationBuilder.shared.stories = LocationInfoHelper.getNumberOfFloors()[indexPath.row].numberOfFloors
        case typesOfPlumbingTableView:
            AddLocationBuilder.shared.plumbingType = self.pipeTypeOptions[indexPath.row].id
        case sourcesOfWaterTableView:
            AddLocationBuilder.shared.waterSource =
                LocationInfoHelper.getSourcesOfWater()[indexPath.row].backendIdentifier
        default:
            break
        }
        
        tableView.reloadData()
    }
    
    // MARK: Actions
    
    @IBAction fileprivate func increaseOccupants() {
        var numberOfOccupants = AddLocationBuilder.shared.occupants ?? 0
        
        if numberOfOccupants < LocationInfoHelper.kOccupantsMax {
            numberOfOccupants += 1
            btnOccupants.setTitle("\(numberOfOccupants)", for: .normal)
            
            AddLocationBuilder.shared.set(occupants: numberOfOccupants)
        }
    }
    
    @IBAction fileprivate func decreaseOccupants() {
        var numberOfOccupants = AddLocationBuilder.shared.occupants ?? 0
        
        if numberOfOccupants > LocationInfoHelper.kOccupantsMin {
            numberOfOccupants -= 1
            btnOccupants.setTitle("\(numberOfOccupants)", for: .normal)
            
            AddLocationBuilder.shared.set(occupants: numberOfOccupants)
        }
    }
    
    @IBAction fileprivate func sliderValueChanged(_ sender: UISlider) {
        let sensitivity = sender.value.rounded()
        sender.setValue(sensitivity, animated: true)
        self.showTooltipInSlider()
        AddLocationBuilder.shared.set(toiletCount: self.bathrooms.value / 2)
    }
    
    // MARK: Validations
    
    fileprivate func performValidationsOn( _ textField: UITextField) -> Bool {
        textField.cleanError()
        
        switch textField {
        case txtAddressLine1:
            guard !(self.txtAddressLine1.text?.isEmpty() ?? true) else {
                txtAddressLine1.displayError("address_not_empty".localized)
                validator.markAsInvalid(txtAddressLine1)
                break
            }
            
            validator.markAsValid(txtAddressLine1)
        case txtCity:
            guard !(self.txtCity.text?.isEmpty() ?? true) else {
                txtCity.displayError("city_not_empty".localized)
                validator.markAsInvalid(txtCity)
                break
            }
            
            validator.markAsValid(txtCity)
        case txtZipcode:
            guard !(self.txtZipcode.text?.isEmpty() ?? true) else {
                txtZipcode.displayError("zipcode_not_empty".localized)
                validator.markAsInvalid(txtZipcode)
                break
            }
            
            validator.markAsValid(txtZipcode)
        case txtState:
            guard !(self.txtState.text?.isEmpty() ?? true) else {
                txtState.displayError("state_not_empty".localized)
                validator.markAsInvalid(txtState)
                break
            }
            
            validator.markAsValid(txtState)
        case txtStateFreeText:
            guard !(self.txtStateFreeText.text?.isEmpty() ?? true) else {
                txtStateFreeText.displayError("state_not_empty".localized)
                validator.markAsInvalid(txtState)
                break
            }
            
            validator.markAsValid(txtState)
        case txtTimezone:
            guard !(self.txtTimezone.text?.isEmpty() ?? true) else {
                txtTimezone.displayError("timezone_not_empty".localized)
                validator.markAsInvalid(txtTimezone)
                break
            }
            
            validator.markAsValid(txtTimezone)
        default:
            break
        }
        
        return true
    }
    
    // MARK: - Service call
    
    //Returns true if all validations have passed. Otherwise returns false
    fileprivate func updateLocation() -> Bool {
        let controls = textFieldsToValidate()
        for c in controls {
            if !self.performValidationsOn(c) {
                return false
            }
        }
        
        if !validator.allChecksPassed() {
            return false
        }
        
        guard let countryName = AddLocationBuilder.shared.selectedCountry?.name else {
            return false
        }
        
        let state = txtStateFreeText.isHidden ? AddLocationBuilder.shared.selectedState?.name : txtStateFreeText.text
        if !txtStateFreeText.isHidden { AddLocationBuilder.shared.freeTextState = txtStateFreeText.text }
        
        guard let stateName = state else {
            return false
        }
        
        guard let timezoneName = AddLocationBuilder.shared.selectedTimezone?.id else {
            return false
        }
        
        AddLocationBuilder.shared.set(address: txtAddressLine1.text!,
                                      address2: txtAddressLine2.text,
                                      country: countryName,
                                      city: txtCity.text!,
                                      state: stateName,
                                      zipcode: txtZipcode.text!,
                                      timezone: timezoneName)
       
        let result = AddLocationBuilder.shared.build(update: true)
        if result.error != nil {
            LoggerHelper.log(result.error?.localizedDescription ?? "Error on AddLocationBuilder.build()", level: .error)
            return false
        }
        
        showLoadingSpinner("please_wait".localized)
        
        FloApiRequest(
            controller: "v2/locations/\(self.location.id)",
            method: .post,
            queryString: nil,
            data: result.result,
            done: { (error, _ ) in
                self.hideLoadingSpinner()
                if let e = error {
                    self.showPopup(error: e)
                    super.goBack()
                } else {
                    LocationsManager.shared.updateLocationLocally(
                        id: self.location.id,
                        LocationModel(AddLocationBuilder.shared)
                    )
                    super.goBack()
                }
            }
        ).secureFloRequest()
        
        return true
    }
    
    // MARK: AmenitiesCellDelegate
    
    public func didChangeAmenity(selected: Bool, amenity: BaseListModel, forGroup: String) {
        switch forGroup {
        case "indoors":
            if !selected {
                AddLocationBuilder.shared.indoorAmenities.removeAll(where: { $0 == amenity.id })
            } else {
                AddLocationBuilder.shared.indoorAmenities.append(amenity.id)
            }
        case "outdoors":
            if !selected {
                AddLocationBuilder.shared.outdoorAmenities.removeAll(where: { $0 == amenity.id })
            } else {
                AddLocationBuilder.shared.outdoorAmenities.append(amenity.id)
            }
        case "plumbing":
            if !selected {
                AddLocationBuilder.shared.plumbingAppliances.removeAll(where: { $0 == amenity.id })
            } else {
                AddLocationBuilder.shared.plumbingAppliances.append(amenity.id)
            }
        default:
            break
        }
    }
}
