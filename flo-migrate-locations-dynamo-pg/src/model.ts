import { StrictSchema } from 'morphism';
import _ from 'lodash';

// ===============================================
// Common
// ===============================================

export enum NoYesUnsure {
  NO = 0,
  YES = 1,
  UNSURE = 3
}

export enum SystemModeName {
  HOME = 'home',
  AWAY = 'away',
  SLEEP = 'sleep'
}

export enum SystemMode {
  HOME = 2,
  AWAY = 3,
  SLEEP = 5
}

// ===============================================
// Dynamo
// ===============================================

export enum LegacyLocationSizeCategory {
  LTE_700 = 0,
  GT_700_LTE_1000,
  GT_1000_LTE_2000,
  GT_2000_LTE_4000,
  GT_4000
}

export enum LegacyLocationType {
  SINGLE_FAMILY_HOME = 'sfh',
  APARTMENT = 'apt',
  CONDO = 'condo',
  IRRIGATION_ONLY = 'irrigation'
}

export enum LegacyBathroomAmenity {
  HOT_TUB = 'Hot Tub',
  SPA = 'Spa',
  BATHTUB ='Bathtub'
}

export enum LegacyKitchenAmenity {
  DISHWASHER = 'Dishwasher',
  WASHING_MACHINE = 'Washer / Dryer',
  REFRIGERATOR_ICE_MAKER = 'Fridge with Ice Maker'
}

export enum LegacyOutdoorAmenity {
  HOT_TUB = 'Hot Tub',
  IRRIGATION = 'Sprinklers',
  SPA = 'Spa',
  SWIMMING_POOL = 'Swimming Pool',
  FOUNTAIN = 'Fountains'
}

interface LegacyLocationProfile {
  expansion_tank: NoYesUnsure;
  tankless: NoYesUnsure;
  galvanized_plumbing: NoYesUnsure;
  water_filtering_system: NoYesUnsure;
  water_shutoff_known: NoYesUnsure;
  hot_water_recirculation: NoYesUnsure;
  whole_house_humidifier: NoYesUnsure;
  location_size_category?: LegacyLocationSizeCategory;
  location_type?: LegacyLocationType;
  bathroom_amenities: LegacyBathroomAmenity[];
  kitchen_amenities: LegacyKitchenAmenity[];
  outdoor_amenities: LegacyOutdoorAmenity[];
}

interface LocationProfile {
  location_type?: string;
  residence_type?: string;
  water_source?: string;
  location_size?: string;
  shower_bath_count?: number;
  toilet_count?: number;
  water_shutoff_known: NoYesUnsure;
  plumbing_type?: string;
  indoor_amenities: string[];
  outdoor_amenities: string[];
  plumbing_applicances: string[];
  home_owners_insurance?: string;
  has_past_water_damage: boolean;
  past_water_damage_claim_amount?: string;
  water_utility?: string;
}

interface AreaRecord {
  id: string;
  name: string;
}

type Integer = number;

export interface DynamoLocation extends Partial<LegacyLocationProfile> {
  account_id: string;
  location_id: string;
  address: string;
  address2?: string;
  city: string;
  state: string;
  country: string;
  postalcode: string;
  timezone: string;
  gallons_per_day_goal: Integer;
  occupants?: Integer;
  stories?: Integer;
  is_profile_complete?: boolean;
  is_using_away_schedule?: boolean;
  profile?: LocationProfile;
  location_name?: string;
  target_system_mode?: SystemModeName;
  revert_scheduled_at?: string;
  revert_mode?: SystemModeName;
  revert_minutes?: number;
  is_irrigation_schedule_enabled?: boolean;
  areas?: AreaRecord[];
  parent_location_id?: string;
  location_class?: string;
  created_at?: string;
  updated_at?: string;
}

export interface DynamoUserLocationRole {
  user_id: string;
  location_id: string;
  roles: string[];
}

// ===============================================
// Postgres
// ===============================================
enum LocationType {
  OTHER = 'other',
  SFH = 'sfh',
  APARTMENT = 'apartment',
  CONDO = 'condo',
  VACATION = 'vacation'
}

enum ResidenceType {
  OTHER = 'other',
  PRIMARY = 'primary',
  RENTAL = 'rental',
  VACATION  = 'vacation'
}

enum WaterSource {
  UTILITY = 'utility',
  WELL = 'well'
}

enum PlumbingType {
  COPPER = 'copper',
  GALVANIZED = 'galvanized'
}

enum IndoorAmenity {
  BATHTUB = 'bathtub',
  HOT_TUB = 'hottub',
  WASHING_MACHINE = 'clotheswasher',
  DISHWASHER = 'dishwasher',
  ICE_MAKER = 'icemaker_ref'
}

enum PlumbingAppliance {
  TANKLESS_WATER_HEATER = 'tankless',
  EXPANSION_TANK = 'exp_tank',
  WHOLE_HOME_FILTRATION = 'home_filter',
  WHOLE_HOME_HUMIDIFIER = 'home_humidifier',
  RECIRCULATION_PUMP = 're_pump',
  WATER_SOFTENER = 'softener',
  PRESSURE_REDUCING_VALVE = 'prv',
  REVERSE_OSMOSIS = 'rev_osmosis'
}

enum OutdoorAmenity {
  POOL = 'pool',
  POOL_AUTO_FILL = 'pool_filter',
  HOT_TUB = 'hottub',
  FOUNTAIN = 'fountain',
  POND = 'pond'
}

enum LocationSize {
  LTE_700_FT = 'lt_700_sq_ft',
  GT_700_FT_LTE_1000_FT = 'lte_1000_sq_ft',
  GT_1000_FT_LTE_2000_FT = 'lte_2000_sq_ft',
  GT_2000_FT_LTE_4000_FT = 'lte_4000_sq_ft',
  GT_4000_FT = 'gt_4000_sq_ft'
}

export interface PostgresLocation {
  id: string;
  parent_location_id?: string | null;
  account_id: string;
  address?: string | null;
  address2?: string | null;
  city?: string | null;
  state?: string | null;
  country?: string| null;
  postal_code?: string | null;
  timezone?: string | null;
  gallons_per_day_goal?: string | null;
  occupants?: Integer | null;
  stories?: Integer | null;
  is_profile_complete: boolean;
  created_at: string | Date;
  updated_at: string | Date;
  home_owners_insurance?: string | null;
  has_past_water_damage?: boolean | null;
  toilet_count?: Integer | null;
  shower_bath_count?: Integer | null;
  nickname?: string | null;
  is_irrigation_schedule_enabled?: boolean | null;
  system_mode_target?: SystemMode | null;
  system_mode_revert_minutes?: Integer | null;
  system_mode_revert_mode?: SystemMode | null;
  system_mode_revert_scheduled_at?: Date | string | null;
  type?: string | null;
  residence_type?: ResidenceType | null;
  water_source?: WaterSource | null;
  location_size?: string | null;
  water_shutoff_known?: NoYesUnsure | null;
  plumbing_type?: string | null;
  indoor_amenities?: string[] | null;
  outdoor_amenities?: string[] | null;
  plumbing_appliances?: string[] | null;
  past_water_damage_claim_amount?: string | null;
  water_utility?: string | null;
  areas?: AreaRecord[] | null;
  location_class?: string | null;
}

export interface PostgresUserLocation {
  user_id: string;
  location_id: string;
  roles: string[];
}

// ===============================================
// Conversion
// ===============================================

export const DynamoToPgLocationSchema: StrictSchema<PostgresLocation, DynamoLocation> = {
  id: 'location_id',
  parent_location_id: 'parent_location_id',
  account_id: 'account_id',
  address: 'address',
  address2: 'address2',
  city: 'city',
  state: (input: DynamoLocation) => {
    return input.state && input.state.toLowerCase();
  },
  country: (input: DynamoLocation) => {
    return input.country && input.country.toLowerCase();
  },
  postal_code: 'postalcode',
  timezone: 'timezone',
  gallons_per_day_goal: 'gallons_per_day_goal',
  occupants: 'occupants',
  stories: 'stories',
  is_profile_complete: (input: DynamoLocation) => {
    return !!input.is_profile_complete;
  },
  created_at: (input: DynamoLocation) => {
    return input.created_at || new Date(0).toISOString();
  },
  updated_at: (input: DynamoLocation) => {
    return input.updated_at || new Date().toISOString();
  },
  home_owners_insurance: 'profile.home_owners_insurance',
  has_past_water_damage: 'profile.has_past_water_damage',
  toilet_count: 'profile.toilet_count',
  shower_bath_count: 'profile.shower_bath_count',
  nickname: 'location_name',
  is_irrigation_schedule_enabled: 'is_irrigation_schedule_enabled',
  system_mode_target: (input: DynamoLocation) => {
    switch (input.target_system_mode) {
      case SystemModeName.HOME:
        return SystemMode.HOME;
      case SystemModeName.AWAY:
        return SystemMode.AWAY;
      case SystemModeName.SLEEP:
        return SystemMode.SLEEP
      default:
        return undefined;
    }
  },
  system_mode_revert_minutes: 'revert_minutes',
  system_mode_revert_mode: (input: DynamoLocation) => {
    switch (input.revert_mode) {
      case SystemModeName.HOME:
        return SystemMode.HOME;
      case SystemModeName.AWAY:
        return SystemMode.AWAY;
      case SystemModeName.SLEEP:
        return SystemMode.SLEEP
      default:
        return undefined;
    }
  },
  system_mode_revert_scheduled_at: 'revert_scheduled_at',
  type: (input: DynamoLocation) => {
    if (input.profile !== undefined && input.profile.location_type !== undefined) {
      return input.profile.location_type;
    }

    switch (input.location_type) {
      case LegacyLocationType.APARTMENT:
        return LocationType.APARTMENT;
      case LegacyLocationType.CONDO:
        return LocationType.CONDO;
      case LegacyLocationType.SINGLE_FAMILY_HOME:
        return LocationType.SFH
      default:
        return undefined;
    }
  },
  residence_type: 'profile.residence_type',
  water_source: 'profile.water_source',
  location_size: (input: DynamoLocation) => {
    if (input.profile && input.profile.location_size) {
      return input.profile.location_size;
    }

    switch (input.location_size_category) {
      case LegacyLocationSizeCategory.LTE_700:
        return LocationSize.LTE_700_FT;
      case LegacyLocationSizeCategory.GT_700_LTE_1000:
        return LocationSize.GT_700_FT_LTE_1000_FT;
      case LegacyLocationSizeCategory.GT_1000_LTE_2000:
        return LocationSize.GT_1000_FT_LTE_2000_FT;
      case LegacyLocationSizeCategory.GT_2000_LTE_4000:
        return LocationSize.GT_2000_FT_LTE_4000_FT;
      case LegacyLocationSizeCategory.GT_4000:
      default:
        return LocationSize.GT_4000_FT;
    }
  },
  water_shutoff_known: (input: DynamoLocation) => {
    return (input.profile && input.profile.water_shutoff_known) || input.water_shutoff_known;
  },
  plumbing_type: (input: DynamoLocation) => {
   if (input.profile !== undefined && input.profile.plumbing_type !== undefined) {
      return input.profile.plumbing_type;
    } else if (input.galvanized_plumbing === NoYesUnsure.YES) {
      return PlumbingType.GALVANIZED;
    } else if (input.galvanized_plumbing === NoYesUnsure.NO) {
      return PlumbingType.COPPER;
    } else {
      return undefined;
    }
  },
  indoor_amenities: (input: DynamoLocation) => {
    if (input.profile !== undefined && !_.isEmpty(input.profile.indoor_amenities)) {
      return input.profile.indoor_amenities;
    }

    const kitchenAmenities = (input.kitchen_amenities || [])
      .map(kitchenAmenity => {
        switch (kitchenAmenity) {
          case LegacyKitchenAmenity.DISHWASHER:
            return IndoorAmenity.DISHWASHER;
          case LegacyKitchenAmenity.REFRIGERATOR_ICE_MAKER:
            return IndoorAmenity.ICE_MAKER;
          case LegacyKitchenAmenity.WASHING_MACHINE:
            return IndoorAmenity.WASHING_MACHINE;
          default:
            return undefined;
        }
      })
      .filter(indoorAmenity => indoorAmenity !== undefined) as IndoorAmenity[];
    const bathroomAmenities = (input.bathroom_amenities || [])
      .map(bathroomAmenity => {
        switch (bathroomAmenity) {
          case LegacyBathroomAmenity.BATHTUB:
            return IndoorAmenity.BATHTUB;
          case LegacyBathroomAmenity.HOT_TUB:
          case LegacyBathroomAmenity.SPA:
            return IndoorAmenity.HOT_TUB;
          default:
            return undefined;
        }
      })
      .filter(indoorAmenity => indoorAmenity !== undefined) as IndoorAmenity[];

    return [...kitchenAmenities, ...bathroomAmenities];
  },
  outdoor_amenities: (input: DynamoLocation) => {
    if (input.profile !== undefined && !_.isEmpty(input.profile.outdoor_amenities)) {
      return input.profile.outdoor_amenities;
    }

    return (input.outdoor_amenities || [])
      .map(outdoorAmenity => {
        switch (outdoorAmenity) {
          case LegacyOutdoorAmenity.SWIMMING_POOL:
            return OutdoorAmenity.POOL;
          case LegacyOutdoorAmenity.FOUNTAIN:
            return OutdoorAmenity.FOUNTAIN;
          case LegacyOutdoorAmenity.SPA:
          case LegacyOutdoorAmenity.HOT_TUB:
            return OutdoorAmenity.HOT_TUB;
          default:
            return undefined;
        }
      })
      .filter(outdoorAmenity => outdoorAmenity !== undefined) as OutdoorAmenity[];
  },
  plumbing_appliances: (input: DynamoLocation) => {
    if (input.profile !== undefined && !_.isEmpty(input.profile.plumbing_applicances)) {
      return input.profile.plumbing_applicances;
    }

    return [
      input.hot_water_recirculation === NoYesUnsure.YES &&
        PlumbingAppliance.RECIRCULATION_PUMP,
      input.water_filtering_system === NoYesUnsure.YES &&
        PlumbingAppliance.WHOLE_HOME_FILTRATION,
      input.tankless === NoYesUnsure.YES &&
        PlumbingAppliance.TANKLESS_WATER_HEATER,
      input.expansion_tank === NoYesUnsure.YES &&
        PlumbingAppliance.EXPANSION_TANK,
      input.whole_house_humidifier === NoYesUnsure.YES &&
        PlumbingAppliance.WHOLE_HOME_HUMIDIFIER
    ]
    .filter(plumbingAppliance => plumbingAppliance) as PlumbingAppliance[];
  },
  past_water_damage_claim_amount: 'profile.past_water_damage_claim_amount',
  water_utility: 'profile.water_utility',
  areas: 'areas',
  location_class: (input: DynamoLocation) => {
    if (input.location_class === 'community') {
      return 'region';
    }
    
    return input.location_class || 'unit';
  }
}

export const DynamoToPgUserLocationSchema: StrictSchema<PostgresUserLocation, DynamoUserLocationRole> = {
  user_id: 'user_id',
  location_id: 'location_id',
  roles: 'roles'
};

export const jsonColumns = ['indoor_amenities', 'outdoor_amenities', 'plumbing_appliances', 'areas', 'roles'];
