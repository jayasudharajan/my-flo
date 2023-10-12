//
//  AddLocationBuilder.swift
//  Flo
//
//  Created by Matias Paillet on 6/12/19.
//  Copyright © 2019 Flo Technologies. All rights reserved.
//

internal class AddLocationBuilder {
    
    public var city: String?
    public var postalCode: String?
    public var address: String?
    public var address2: String?
    public var country: String?
    public var state: String?
    public var timezone: String?
    public var nickname: String?
    public var occupants: Int?
    public var plumbingType: String?
    public var gallonsPerDayGoal: Double?
    public var waterShutoffKnown: String?
    public var waterSource: String?
    public var indoorAmenities: [String] = []
    public var outdoorAmenities: [String] = []
    public var plumbingAppliances: [String] = []
    public var locationSize: String?
    public var locationType: String?
    public var residenceType: String?
    public var stories: Int?
    public var toiletCount: Float?
    public var waterUtility: String?
    public var homeownersInsurance: String?
    public var hasPastWaterDamage: Bool?
    public var pastWaterDamageClaimAmount: String?
    
    //Properties not set by add or update flow but needed
    public var id: String?
    public var devices: [DeviceModel]?
    public var isProfileComplete: Bool?
    public var showerBathCount: Int?
    public var systemMode: SystemMode?
    public var systemModeLocked: Bool?
    public var floProtect: Bool?
    
    //Builder properties to help on the flow
    public var countries: [FloLocale] = []
    public var selectedCountry: FloLocale?
    public var selectedState: LocaleRegion?
    public var selectedTimezone: LocaleTimezone?
    public var freeTextState: String?
    
    // MARK: - Singleton
    public class var shared: AddLocationBuilder {
        struct Static {
            static let instance = AddLocationBuilder()
        }
        return Static.instance
    }
    
    // MARK: Internal methods
    
    fileprivate func getCountriesInfo(_ idsToRetrieve: String, _ whenFinished: ((_ success: Bool) -> Void)? = nil) {
        FloApiRequest(
            controller: "v2/lists",
            method: .get,
            queryString: ["id": idsToRetrieve],
            data: nil,
            done: ({ ( error, data) in
            if error != nil {
                whenFinished?(false)
                return
            }
                
            var allLocales = [FloLocale]()
            if let dict = data as? NSDictionary, let list = dict["items"] as? [NSDictionary] {
                allLocales = FloLocale.array(list)
            }
            
            //Append info to existing countries
            for locale in allLocales {
                var existed = false
                for (i, existingLocale) in self.countries.enumerated() where existingLocale.id == locale.id {
                    //If existing locale had no data, replace with the new
                    if existingLocale.regions.isEmpty || existingLocale.timezones.isEmpty {
                        self.countries.remove(at: i)
                        self.countries.append(locale)
                    }
                    
                    existed = true
                    break
                }
                
                if !existed {
                    self.countries.append(locale)
                }
            }
                
            self.countries = self.countries.sorted(by: { return FloLocale.compareTwoLocales($0, $1) })
            
            //If user doesn't have a selected country, pre fill with phone's one
            if self.selectedCountry == nil {
                if let locale = allLocales.filter({ (locale) -> Bool in
                    let localeId = String(Locale.current.identifier.split(separator: "_").last ?? "").lowercased()
                    return locale.id == localeId
                }).first {
                    self.selectedCountry = locale
                    self.resetStateAndTimezone()
                } else if let locale = self.countries.first {
                    self.selectedCountry = locale
                    self.resetStateAndTimezone()
                }
            } else { //Update selected country in case it got prepopulated with more info
                if let country = self.countries.filter({ $0.id == self.selectedCountry?.id }).first {
                    self.selectedCountry = country
                }
            }
                
            LocationInfoHelper.countries = self.countries
                
            whenFinished?(true)
            
        })).secureFloRequest()
    }
    
    fileprivate func fetchCountryInfoIfNeeded(_ whenFinished: ((_ success: Bool) -> Void)? = nil) {
        if selectedCountry == nil {
            return
        }
        
        if self.selectedCountry!.regions.isEmpty || self.selectedCountry!.timezones.isEmpty {
            self.getCountriesInfo(formatInfoForCountry(self.selectedCountry!), whenFinished)
        } else {
            whenFinished?(true)
        }
    }
    
    fileprivate func formatInfoForCountry(_ locale: FloLocale) -> String {
        return "country,region_\(locale.id.lowercased()),timezone_\(locale.id.lowercased())"
    }
    
    fileprivate func resetStateAndTimezone() {
        self.selectedState = nil
        let localTimeZoneName = TimeZone.current.identifier
        self.selectedTimezone = self.selectedCountry?.timezones.filter({ $0.id == localTimeZoneName }).first
    }
    
    public func changeSelectedCountry(_ locale: FloLocale, _ whenFinished: @escaping ((_ success: Bool) -> Void)) {
        self.selectedCountry = self.countries.filter({ $0.id == locale.id }).first
        resetStateAndTimezone()
        fetchCountryInfoIfNeeded(whenFinished)
    }
    
    public func changeSelectedCountry(_ locale: FloLocale) {
        self.selectedCountry = self.countries.filter({ $0.id == locale.id }).first
    }
    
    public func changeSelectedRegion(_ region: LocaleRegion?) {
        self.selectedState = region
    }
    
    public func changeSelectedTimezone(_ timezone: LocaleTimezone?) {
        self.selectedTimezone = timezone
    }
    
    public func getCountryLocale(countryId: String) -> FloLocale? {
        return self.countries.filter({ $0.id == countryId}).first
    }
    
    public func getRegion(region: String) -> LocaleRegion? {
        return (self.selectedCountry?.regions.filter({ $0.id.lowercased() == region.lowercased()}).first ??
        self.selectedCountry?.regions.filter({ $0.name.lowercased() == region.lowercased()}).first)
    }
    
    public func getTimezone(timezoneId: String) -> LocaleTimezone? {
        return self.selectedCountry?.timezones.filter({ $0.id == timezoneId}).first
    }
    
    // MARK: Setters
    public func set(locationType: String, locationUse: String) {
        self.locationType = locationType
        self.residenceType = locationUse
    }
    
    public func set(nickname: String) {
        self.nickname = nickname
    }
    
    public func set(address: String, address2: String?, country: String, city: String, state: String,
                    zipcode: String, timezone: String) {
        self.address = address
        self.address2 = address2
        self.country = country
        self.city = city
        self.state = state
        self.postalCode = zipcode
        self.timezone = timezone
    }
    
    public func set(address: String) {
        self.address = address
    }
    
    public func set(address2: String) {
        self.address2 = address2
    }
    
    public func set(country: String) {
        self.country = country
    }
    
    public func set(city: String) {
        self.city = city
    }
    
    public func set(state: String) {
        self.state = state
    }
    
    public func set(zipcode: String) {
        self.postalCode = zipcode
    }
    
    public func set(timezone: String) {
        self.timezone = timezone
    }
    
    public func set(locationSize: String) {
        self.locationSize = locationSize
    }
    
    public func set(stories: Int, toiletCount: Float) {
        self.stories = stories
        self.toiletCount = toiletCount
    }
    
    public func set(stories: Int) {
        self.stories = stories
    }
    
    public func set(toiletCount: Float) {
        self.toiletCount = toiletCount
    }
    
    public func set(plumbingType: String, waterShutoffKnown: String, waterSource: String) {
        self.plumbingType = plumbingType
        self.waterShutoffKnown = waterShutoffKnown
        self.waterSource = waterSource
    }
    
    public func set(plumbingType: String) {
        self.plumbingType = plumbingType
    }
    
    public func set(waterShutoffKnown: String) {
        self.waterShutoffKnown = waterShutoffKnown
    }
    
    public func set(waterSource: String) {
        self.waterSource = waterSource
    }
    
    public func set(occupants: Int) {
        self.occupants = occupants
    }
    
    public func set(gallonsPerDayGoal: Double) {
        self.gallonsPerDayGoal = gallonsPerDayGoal
    }
    
    public func set(homeInsurance: String?, hasPastWaterDamage: Bool, claimedAmount: String?) {
        self.homeownersInsurance = homeInsurance
        self.hasPastWaterDamage = hasPastWaterDamage
        self.pastWaterDamageClaimAmount = claimedAmount
    }
    
    public func set(homeInsurance: String?) {
        self.homeownersInsurance = homeInsurance
    }
    
    public func set(hasPastWaterDamage: Bool) {
        self.hasPastWaterDamage = hasPastWaterDamage
    }
    
    public func set(claimedAmount: String?) {
        self.pastWaterDamageClaimAmount = claimedAmount
    }
    
    public func set(waterUtility: String) {
        self.waterUtility = waterUtility
    }
    
    // MARK: Builder methods
    public func start(_ whenFinished: ((_ success: Bool) -> Void)? = nil) {
        self.clean()
        self.getCountriesInfo("country,region_us,timezone_us", whenFinished)
        
        //Preload lists
        _ = ListsManager.shared.getPipeTypes { _, _ in }
        _ = ListsManager.shared.getAppliances { _, _ in }
    }
    
    public func getSelectedCountryInfo(selectedCountry: FloLocale, _ whenFinished: ((_ success: Bool) -> Void)? = nil) {
        self.selectedCountry = selectedCountry
        self.fetchCountryInfoIfNeeded(whenFinished)
    }
    
    public func startWithLocation(_ location: LocationModel) {
        self.initWithLocation(location)
    }
    
    public func startWithCurrentLocation() {
        guard let location = LocationsManager.shared.selectedLocation else {
            return
        }
        self.initWithLocation(location)
    }
    
    fileprivate func initWithLocation(_ location: LocationModel) {
        set(address: location.address, address2: location.address2, country: location.country,
                                      city: location.city, state: location.state, zipcode: location.postalCode,
                                      timezone: location.timezone)
        
        set(locationSize: location.locationSize)
        set(stories: location.stories)
        set(plumbingType: location.plumbingType)
        set(waterSource: location.waterSource)
        indoorAmenities = location.indoorAmenities
        outdoorAmenities = location.outdoorAmenities
        plumbingAppliances = location.plumbingAppliances
        set(toiletCount: Float(location.toiletCount))
        set(occupants: location.occupants)
        set(gallonsPerDayGoal: location.gallonsPerDayGoal)
        set(locationType: location.locationType, locationUse: location.residenceType)
        set(waterShutoffKnown: location.waterShutoffKnown)
        set(nickname: location.nickname)
        set(homeInsurance: location.homeownersInsurance, hasPastWaterDamage: location.hasPastWaterDamage, claimedAmount: location.pastWaterDamageClaimAmount)
        
        id = location.id
        devices = location.devices
        isProfileComplete = location.isProfileComplete
        showerBathCount = location.showerBathCount
        systemMode = location.systemMode
        systemModeLocked = location.systemModeLocked
        floProtect = location.floProtect
        
        if let selectedCountry = getCountryLocale(countryId: country ?? "") {
            changeSelectedCountry(selectedCountry)
        }
        
        if let selectedRegion = getRegion(region: state ?? "") {
            changeSelectedRegion(selectedRegion)
        }
        
        if let selectedTimezone = getTimezone(timezoneId: timezone ?? "") {
            changeSelectedTimezone(selectedTimezone)
        }
    }
    
    public func clean() {
        self.city = nil
        self.postalCode = nil
        self.address = nil
        self.address2 = nil
        self.country = nil
        self.state = nil
        self.timezone = nil
        self.nickname = nil
        self.occupants = nil
        self.plumbingType = nil
        self.gallonsPerDayGoal = nil
        self.waterShutoffKnown = nil
        self.indoorAmenities = []
        self.outdoorAmenities = []
        self.locationSize = nil
        self.locationType = nil
        self.stories = nil
        self.toiletCount = nil
        self.waterSource = nil
        self.plumbingAppliances = []
        self.waterUtility = nil
        self.homeownersInsurance = nil
        self.hasPastWaterDamage = nil
        self.pastWaterDamageClaimAmount = nil
        
        self.countries = []
        self.selectedCountry = nil
        self.selectedState = nil
        self.selectedTimezone = nil
    }
    
    public func build(update: Bool = false) -> (result: [String: AnyObject], error: NSError?) {
        var info = [String: AnyObject]()
        
        guard let state = (self.selectedState != nil ? selectedState?.id : freeTextState) else {
            return (info, NSError.initWithMessage("state_not_empty".localized) )
        }
        
        guard let timezone = self.selectedTimezone else {
            return (info, NSError.initWithMessage("timezone_not_empty".localized) )
        }
        
        guard let country = self.selectedCountry else {
            return (info, NSError.initWithMessage("country_not_empty".localized) )
        }
        
        info["nickname"] = self.nickname as AnyObject
        info["address"] = self.address as AnyObject
        if !(self.address2 ?? "").isEmpty { info["address2"] = self.address2 as AnyObject }
        info["city"] = self.city as AnyObject
        info["state"] = state as AnyObject
        info["country"] = country.id as AnyObject
        info["postalCode"] = self.postalCode as AnyObject
        info["timezone"] = timezone.id as AnyObject
        let currentSystem = MeasuresHelper.getMeasureSystem()
        let goal = currentSystem == .imperial ? self.gallonsPerDayGoal :
            MeasuresHelper.adjust(self.gallonsPerDayGoal ?? 0, ofType: .volume, from: currentSystem, to: .imperial)
        info["gallonsPerDayGoal"] = goal as AnyObject
        info["occupants"] = self.occupants as AnyObject
        info["stories"] = self.stories as AnyObject
        info["waterShutoffKnown"] = self.waterShutoffKnown as AnyObject
        info["indoorAmenities"] = self.indoorAmenities as AnyObject
        info["outdoorAmenities"] = self.outdoorAmenities as AnyObject
        info["plumbingAppliances"] = self.plumbingAppliances as AnyObject
        info["locationType"] = self.locationType as AnyObject
        info["residenceType"] = self.residenceType as AnyObject
        info["waterSource"] = self.waterSource as AnyObject
        info["locationSize"] = self.locationSize as AnyObject
        info["showerBathCount"] = Int(self.toiletCount ?? 0) as AnyObject
        let toiletAdditions =  self.toiletCount?.truncatingRemainder(dividingBy: 1) != 0.0 ? 1 : 0
        info["toiletCount"] = Int(self.toiletCount ?? 0) + toiletAdditions as AnyObject
        info["plumbingType"] = self.plumbingType as AnyObject
        if !(self.waterUtility ?? "").isEmpty { info["waterUtility"] = self.waterUtility as AnyObject }
        if !(self.homeownersInsurance ?? "").isEmpty { info["homeownersInsurance"] = self.homeownersInsurance as AnyObject }
        info["hasPastWaterDamage"] = (self.hasPastWaterDamage ?? false) as AnyObject
        if !(self.pastWaterDamageClaimAmount ?? "").isEmpty { info["pastWaterDamageClaimAmount"] = self.pastWaterDamageClaimAmount as AnyObject }
        
        //Account info needs to be added as well
        if !update { info["account"] = ["id": UserSessionManager.shared.user?.account.id] as AnyObject }
        return (info, nil)
    }
}
