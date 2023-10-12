import { StrictSchema } from 'morphism';
import _ from 'lodash';


// ===============================================
// Dynamo
// ===============================================

export enum UnitSystem {
  IMPERIAL_US = 'imperial_us',
  METRIC_KPA = 'metric_kpa'
}

export enum AccountType {
  PERSONAL = 'personal',
  ENTERPRISE = 'enterprise'
}

export interface DynamoUser {
  id: string;
  email: string;
  password?: string;
  source?: string;
  is_active?: boolean;
  is_system_user?: boolean;
  is_super_user?: boolean;
  account_id?: string;
}

export interface DynamoUserDetail {
  user_id: string;
  firstname?: string;
  middlename?: string;
  lastname?: string;
  prefixname?: string;
  suffixname?: string;
  unit_system?: UnitSystem; // Measurement unit prefence (e.g. metric vs freedom units)
  phone_mobile?: string;
  locale?: string;
  enabled_features?: string[];
}

export interface DynamoAccount {
  id: string;
  owner_user_id: string;
  type_v2?: AccountType; // For personal vs MUD accounts,
}

// ===============================================
// Postgres
// ===============================================

export interface PostgresUser {
  id: string;
  email: string;
  password: string;
  source?: string | null;
  is_active: boolean;
  is_system_user: boolean;
  is_super_user: boolean;
  account_id?: string | null;
}

export interface PostgresUserDetail {
  user_id: string;
  firstname?: string | null;
  middlename?: string | null;
  lastname?: string | null;
  prefixname?: string | null;
  suffixname?: string | null;
  unit_system?: UnitSystem | null; // Measurement unit prefence (e.g. metric vs freedom units)
  phone_mobile?: string | null;
  locale?: string | null;
  enabled_features?: string[] | null;
}

export interface PostgresAccount {
  id: string;
  owner_user_id: string;
  type: AccountType; // For personal vs MUD accounts,
}

// ===============================================
// Conversion
// ===============================================

export const DynamoToPgUserSchema: StrictSchema<PostgresUser, DynamoUser> = {
  id: 'id',
  email: 'email',
  password: (input: DynamoUser) => {
    return _.isEmpty(input.password) ? '' : input.password as string;
  },
  source: 'source',
  is_active: (input: DynamoUser) => {
    return !!input.is_active;
  },
  is_system_user: (input: DynamoUser) => {
    return !!input.is_system_user;
  },
  is_super_user: (input: DynamoUser) => {
    return !!input.is_super_user;
  },
  account_id: 'account_id',
}

export const DynamoToPgUserDetailSchema: StrictSchema<PostgresUserDetail, DynamoUserDetail> = {
  user_id: 'user_id',
  firstname: 'firstname',
  middlename: 'middlename',
  lastname: 'lastname',
  prefixname: 'prefixname',
  suffixname: 'suffixname',
  unit_system: 'unit_system',
  phone_mobile: 'phone_mobile',
  locale: 'locale',
  enabled_features: 'enabled_features',
};

export const DynamoToPgAccountSchema: StrictSchema<PostgresAccount, DynamoAccount> = {
  id: 'id',
  owner_user_id: 'owner_user_id',
  type: (input: DynamoAccount) => {
    return !input.type_v2 ? AccountType.PERSONAL : input.type_v2;
  },
};

export const jsonColumns = ['enabled_features'];