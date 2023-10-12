package main

// APIVersion API version
const APIVersion = "v1"

// EmptyString is the empty string value
const EmptyString = ""

// NoneValue is the string none value
const NoneValue = "none"

const AssetsKey = "assets"
const AssetIdKey = "id"
const AssetNameKey = "name"
const AssetTypeKey = "type"
const AssetLocaleKey = "locale"
const AssetValueKey = "value"
const AssetReleasedKey = "released"
const AssetSearchKey = "search"
const CachingdKey = "caching"

const LocalesKey = "locales"
const LocaleIdKey = "id"
const FallbackKey = "fallback"

// NoSuchAssetErrorMsg is no such asset error message
const NoSuchAssetErrorMsg = "assetId_%s doesn't exist"
// NoSuchLocaleErrorMsg is no such locale error message
const NoSuchLocaleErrorMsg = "localeId_%s doesn't exist"
const LocaleIsNotSupportedMsg = "locale %s is not supported"

// AssetAlreadyExistsErrorMsg is the asset already exists error msg
const AssetAlreadyExistsErrorMsg = "assetId_%s already exists"
// LocaleAlreadyExistsErrorMsg is the locale already exists error msg
const LocaleAlreadyExistsErrorMsg = "localeId_%s already exists"

const DefaultOffset = 0
const DefaultLimit = 10