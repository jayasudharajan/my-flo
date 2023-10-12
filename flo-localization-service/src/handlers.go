package main

import (
	"database/sql"
	"fmt"
	"net/http"
	"regexp"
	"strconv"
	"strings"
	"text/template"
	"time"

	"github.com/labstack/echo"
	"github.com/labstack/gommon/log"
	"github.com/swaggo/gin-swagger/swaggerFiles"
	"github.com/swaggo/swag"
)

const offsetParam = "offset"
const limitParam = "limit"
const defaultLimit = 10
const maxLimit = 1000
const defaultOffset = 0
const assetFieldIsEmptyErrorMsg = "asset %s field can not be empty"

// TODO: consult with a team on the complete list of the media/delivery types
var defaultValidTypes = map[string]bool{
	"sms":     true,
	"push":    true,
	"display": true,
	"email":   true,
	"phone":   true,
	"voice":   true,
}

// CreateAssetHandler godoc
// @Summary creates new asset
// @Description This endpoint creates an asset. Asset is a unique record of name, type, locale, e.g. low_pressure_alert, sms, en-us.
// @Description Asset is considered to be ready for production use if its released flag is set to true (it is defaulted to false).
// @Description Each asset can be tagged. Name, type, locale and value are the mandatory properties. Released, tags are optional.
// @Description All other properties provided will be ignored. Multiple tags can be applied to the asset. The response is an echo
// @Description of provided properties of the request body plus created time. updated time and an asset id. The returned asset id is uuid formatted.
// @Tags localization
// @Accept  json
// @Produce  json
// @Param asset body Asset true "create asset"
// @Success 201 {object} Asset
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /assets [post]
func (lsh LocalizationServiceHandler) CreateAssetHandler(c echo.Context) error {
	var err error

	var asset Asset
	err = c.Bind(&asset)
	if err != nil {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("failed to bind request body, err: %s", err.Error()))
	}

	if asset.Name == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf(assetFieldIsEmptyErrorMsg, AssetNameKey))
	}

	if asset.Type == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf(assetFieldIsEmptyErrorMsg, AssetTypeKey))
	}

	if asset.Locale == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf(assetFieldIsEmptyErrorMsg, AssetLocaleKey))
	}

	if asset.Value == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf(assetFieldIsEmptyErrorMsg, AssetValueKey))
	}

	assetTypes, err := lsh.getAllTypes()
	if err != nil {
		return sendErrorResponse(c, http.StatusInternalServerError,
			err.Error())
	}

	if _, ok := assetTypes[asset.Type]; !ok {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("%s is not supported %s parameter", asset.Type, AssetTypeKey))
	}

	asset.Locale, err = NormalizeLocale(asset.Locale)
	if err != nil {
		return sendErrorResponse(c, http.StatusBadRequest, err.Error())
	}

	id, err := GenerateUuid()
	if err != nil {
		return sendErrorResponse(c, http.StatusInternalServerError, "failed to generate uuid")
	}
	asset.Id = id
	assetFinal, err := lsh.SqlRepo.CreateNewAsset(asset)
	if err != nil {
		if err.Error() == fmt.Sprintf(AssetAlreadyExistsErrorMsg, id) {
			return sendErrorResponse(c, http.StatusConflict,
				fmt.Sprintf("asset with name %s, type %s, locale %s already exists", asset.Name, asset.Type,
					asset.Locale))
		}
		if err.Error() == fmt.Sprintf(LocaleIsNotSupportedMsg, asset.Locale) {
			return sendErrorResponse(c, http.StatusBadRequest, err.Error())
		}
		return sendErrorResponse(c, http.StatusInternalServerError,
			fmt.Sprintf("failed to create new asset of name %s, type %s, locale %s, err: %v",
				asset.Name, asset.Type, asset.Locale, err))
	}

	return c.JSON(http.StatusCreated, assetFinal)
}

// UpdateAssetHandler godoc
// @Summary updates an asset
// @Description This endpoint updates an asset by its id and provided json body. Id, created are the immutable fields.
// @Tags localization
// @Accept  json
// @Param id path string true "asset id"
// @Param asset body Asset true "update asset"
// @Success 204
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /assets/:id [post]
func (lsh LocalizationServiceHandler) UpdateAssetHandler(c echo.Context) error {
	assetParamId := c.Param(AssetIdKey)
	if assetParamId == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf(assetFieldIsEmptyErrorMsg, AssetIdKey))
	}

	if !isValidAssetId(assetParamId) {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("asset %s path param value is not a uuid format", AssetIdKey))
	}

	var assetFieldsToUpdate map[string]interface{}

	err := c.Bind(&assetFieldsToUpdate)
	if err != nil {
		return sendErrorResponse(c, http.StatusBadRequest, fmt.Sprintf("failed to bind request body, err: %s",
			err.Error()))
	}

	assetIdInterface, ok := assetFieldsToUpdate[AssetIdKey]
	if !ok {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("asset %s has to be provided in the request body", AssetIdKey))
	}

	assetId := assetIdInterface.(string)
	if assetId == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest, fmt.Sprintf("asset %s field can not be empty",
			AssetIdKey))
	}

	if assetParamId != assetId {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("asset %s field has to be equal to %s asset param", AssetIdKey, AssetIdKey))
	}

	delete(assetFieldsToUpdate, AssetIdKey)

	for k := range assetFieldsToUpdate {
		if _, ok := lsh.MutableAssetFields[k]; !ok {
			return sendErrorResponse(c, http.StatusBadRequest,
				fmt.Sprintf("field %s is immutable", k))
		}
	}

	err = lsh.SqlRepo.UpdateAsset(assetFieldsToUpdate, assetId)
	if err != nil {
		noSuchAssetMsg := fmt.Sprintf(NoSuchAssetErrorMsg, assetId)
		if err.Error() == noSuchAssetMsg {
			return sendErrorResponse(c, http.StatusNotFound,
				fmt.Sprintf(noSuchAssetMsg))
		}
		// TODO: breaks the loosely coupling of json body fields
		localeId := assetFieldsToUpdate[AssetLocaleKey].(string)
		if err.Error() == fmt.Sprintf(LocaleIsNotSupportedMsg, localeId) {
			return sendErrorResponse(c, http.StatusBadRequest, err.Error())
		}
		return sendErrorResponse(c, http.StatusInternalServerError,
			fmt.Sprintf("failed to update asset of id %s, err: %v", assetId, err))
	}

	return c.NoContent(http.StatusNoContent)
}

// GetAssetByIdHandler godoc
// @Summary gets localized asset by id
// @Description This endpoint gets localized asset by id, id has to be uuid formatted
// @Tags localization
// @Accept  json
// @Produce  json
// @Param id path string true "asset id"
// @Success 200 {object} Asset
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /assets/:id [get]
func (lsh LocalizationServiceHandler) GetAssetByIdHandler(c echo.Context) error {
	assetParamId := c.Param(AssetIdKey)
	if assetParamId == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("asset %s path param can not be empty", AssetIdKey))
	}

	if !isValidAssetId(assetParamId) {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf(fmt.Sprintf("asset %s path param value is not a uuid format", AssetIdKey),
				AssetIdKey))
	}

	asset, err := lsh.SqlRepo.GetAsset(assetParamId)
	if err != nil {
		notFoundErrMsg := fmt.Sprintf(NoSuchAssetErrorMsg, assetParamId)
		if err.Error() == notFoundErrMsg {
			return sendErrorResponse(c, http.StatusNotFound, notFoundErrMsg)
		}
		return sendErrorResponse(c, http.StatusInternalServerError,
			fmt.Sprintf("failed to get assetId_%s, err: %v", assetParamId, err))
	}
	return c.JSON(http.StatusOK, asset)
}

// GetFilteredAssetsHandler godoc
// @Summary gets localized assets
// @Description This endpoint gets filtered (if any filters provided) paginated localized assets. Default values for pagination are: 0 for offset, 10 for limit.
// @Tags localization
// @Accept  json
// @Produce  json
// @Param name query string false "filter by name"
// @Param type query string false "filter by type"
// @Param locale query string false "filter by locale"
// @Param released query bool false "filter by released flag"
// @Param search query string false "fuzzy search within asset name column, e.g. search=valve"
// @Param offset query int false "pagination offset"
// @Param limit query int false "pagination limit"
// @Success 200 {object} Assets
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /assets [get]
func (lsh LocalizationServiceHandler) GetFilteredAssetsHandler(c echo.Context) error {
	var err error
	var limit int
	var offset int

	offsetStr := c.QueryParam(offsetParam)
	if offsetStr == EmptyString {
		offset = defaultOffset
	} else {
		offset, err = strconv.Atoi(offsetStr)
		if err != nil {
			return sendErrorResponse(c, http.StatusBadRequest,
				fmt.Sprintf("parameter %s has to be a number", offsetParam))
		}
	}

	limitStr := c.QueryParam(limitParam)
	if limitStr == EmptyString {
		limit = defaultLimit
	} else {
		limit, err = strconv.Atoi(limitStr)
		if err != nil {
			return sendErrorResponse(c, http.StatusBadRequest,
				fmt.Sprintf("parameter %s has to be a number", limitParam))
		}
	}

	if limit > maxLimit {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("parameter %s has to be less or equal to %d", limitParam, maxLimit))
	}

	filters := make(map[string]interface{})

	assetLocaleParam := c.QueryParam(AssetLocaleKey)
	if assetLocaleParam != EmptyString {
		assetLocale, err := NormalizeLocale(assetLocaleParam)
		if err != nil {
			return sendErrorResponse(c, http.StatusBadRequest, err.Error())
		}
		filters[AssetLocaleKey] = assetLocale
	}
	assetType := c.QueryParam(AssetTypeKey)
	if assetType != EmptyString {
		filters[AssetTypeKey] = assetType
	}
	assetName := c.QueryParam(AssetNameKey)
	if assetName != EmptyString {
		filters[AssetNameKey] = assetName
	}
	assetReleased := c.QueryParam(AssetReleasedKey)
	if assetReleased != EmptyString {
		filters[AssetReleasedKey] = assetReleased
	}

	fuzzySearch := make(map[string]string)
	search := c.QueryParam(AssetSearchKey)
	if search != EmptyString {
		// TODO: come up with the convention for searching within different columns, right now, it's hardcoded to name
		fuzzySearch["name"] = search
	}

	assets, err := lsh.SqlRepo.GetAssets(filters, fuzzySearch, offset, limit)

	return c.JSON(http.StatusOK, assets)
}

// DeleteAssetHandler godoc
// @Summary deletes localized asset by id
// @Description This endpoint deletes localized asset by id, id has to be uuid formatted
// @Tags localization
// @Accept  json
// @Param id path string true "asset id"
// @Success 204 {object} Asset
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /assets/:id [delete]
func (lsh LocalizationServiceHandler) DeleteAssetHandler(c echo.Context) error {
	assetParamId := c.Param(AssetIdKey)
	if assetParamId == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("asset %s path param can not be empty", AssetIdKey))
	}

	if !isValidAssetId(assetParamId) {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("asset %s path param value is not a uuid format", AssetIdKey))
	}

	err := lsh.SqlRepo.DeleteAsset(assetParamId)
	if err != nil {
		notFoundErrMsg := fmt.Sprintf(NoSuchAssetErrorMsg, assetParamId)
		if err.Error() == notFoundErrMsg {
			return sendErrorResponse(c, http.StatusNotFound, notFoundErrMsg)
		}
		return sendErrorResponse(c, http.StatusInternalServerError,
			fmt.Sprintf(fmt.Sprintf("failed to delete record of %s %s", AssetIdKey, assetParamId)))
	}

	return c.NoContent(http.StatusNoContent)
}

func (lsh LocalizationServiceHandler) getAllTypes() (map[string]bool, error) {
	// get all types
	assetTypes := make(map[string]bool)
	TypesDS.L.RLock()
	typesI := TypesDS.M
	TypesDS.L.RUnlock()
	if typesI != nil && len(typesI) > 0 {
		for k := range typesI {
			assetTypes[k] = true
		}
	} else {
		log.Debugf("there are no types in cache, fetching from Postgres")
		offset := 0
		maxLim := maxLimit
		types, err := lsh.SqlRepo.GetAllTypesFiltered(&offset, &maxLim)
		if err != nil {
			return nil, err
		}
		for _, t := range types.Items {
			assetTypes[t.Type] = true
		}
	}
	if len(assetTypes) == 0 {
		log.Debugf("there are no types in cache or Postgres, fall to default values %v", defaultValidTypes)
		assetTypes = defaultValidTypes
	}
	return assetTypes, nil
}

// Lsh is the global variable for Localization Service Handler
var Lsh LocalizationServiceHandler

func InitLocalizationServiceHandlers(db *sql.DB, mutableAssetFields map[string]bool, mutableLocaleFields map[string]bool,
	assetTagsMappings AssetTagsMappings) {
	Lsh = LocalizationServiceHandler{
		SqlRepo: &LocalizationRepository{
			DB: db,
		},
		MutableAssetFields:  mutableAssetFields,
		MutableLocaleFields: mutableLocaleFields,
		AssetTagsMappings:   assetTagsMappings,
	}
}

type LocalizationServiceHandler struct {
	SqlRepo             *LocalizationRepository
	MutableLocaleFields map[string]bool
	MutableAssetFields  map[string]bool
	AssetTagsMappings   AssetTagsMappings
}

// CreateLocaleHandler godoc
// @Summary creates new locale
// @Description This endpoint creates a locale. Locale is in the format of ll-cc (ll is language, cc is country),
// @Description e.g. en-us. The id of the locale is the locale itself. Locale is considered to be ready for production
// @Description use if its released flag is set to true. Each locale has a fallback
// @Tags localization
// @Accept  json
// @Produce  json
// @Param locale body Locale true "create locale"
// @Success 201 {object} ResponseOnCreatingNewLocale
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /locales [post]
func (lsh LocalizationServiceHandler) CreateLocaleHandler(c echo.Context) error {
	var err error

	var locale Locale
	err = c.Bind(&locale)
	if err != nil {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("failed to bind request body, err: %s", err.Error()))
	}

	if locale.Id == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("locale %s field can not be empty", LocaleIdKey))
	}

	locale.Id, err = NormalizeLocale(locale.Id)
	if err != nil {
		return sendErrorResponse(c, http.StatusBadRequest, err.Error())
	}

	if locale.Fallback == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("locale %s field can not be empty", FallbackKey))
	}

	err = lsh.SqlRepo.CreateNewLocale(locale)
	if err != nil {
		if err.Error() == fmt.Sprintf(LocaleAlreadyExistsErrorMsg, locale.Id) {
			return sendErrorResponse(c, http.StatusConflict,
				fmt.Sprintf("locale with id %s, fallback %s already exists", locale.Id, locale.Fallback))
		}
		return sendErrorResponse(c, http.StatusInternalServerError,
			fmt.Sprintf("failed to create new locale of id %s, fallback %s, err: %v",
				locale.Id, locale.Fallback, err))
	}

	return c.NoContent(http.StatusCreated)
}

// UpdateLocaleHandler godoc
// @Summary updates locale
// @Description This endpoint updates a locale by its id and provided json body. Id, created are the immutable fields.
// @Tags localization
// @Accept  json
// @Param id path string true "locale id"
// @Param locale body Locale true "update locale"
// @Success 204
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /locales/:id [post]
func (lsh LocalizationServiceHandler) UpdateLocaleHandler(c echo.Context) error {
	localeParamId := c.Param(LocaleIdKey)
	if localeParamId == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("locale %s path param can not be empty", LocaleIdKey))
	}

	var localeFieldsToUpdate map[string]interface{}

	err := c.Bind(&localeFieldsToUpdate)
	if err != nil {
		return sendErrorResponse(c, http.StatusBadRequest, fmt.Sprintf("failed to bind request body, err: %s",
			err.Error()))
	}

	localeIdInterface, ok := localeFieldsToUpdate[LocaleIdKey]
	if !ok {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("locale %s has to be provided in the request body", LocaleIdKey))
	}

	notNormalizedLocaleId := localeIdInterface.(string)
	if notNormalizedLocaleId == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest, fmt.Sprintf("locale %s field can not be empty",
			LocaleIdKey))
	}
	if localeParamId != notNormalizedLocaleId {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("locale %s field has to be equal to %s locale param", LocaleIdKey, LocaleIdKey))
	}

	localeId, err := NormalizeLocale(notNormalizedLocaleId)
	if err != nil {
		return sendErrorResponse(c, http.StatusBadRequest, err.Error())
	}

	delete(localeFieldsToUpdate, LocaleIdKey)

	for k := range localeFieldsToUpdate {
		if _, ok := lsh.MutableLocaleFields[k]; !ok {
			return sendErrorResponse(c, http.StatusBadRequest,
				fmt.Sprintf("field %s is immutable", k))
		}
	}

	err = lsh.SqlRepo.UpdateLocale(localeFieldsToUpdate, localeId)
	if err != nil {
		noSuchLocaleMsg := fmt.Sprintf(NoSuchLocaleErrorMsg, localeId)
		if err.Error() == noSuchLocaleMsg {
			return sendErrorResponse(c, http.StatusNotFound,
				fmt.Sprintf(noSuchLocaleMsg))
		}
		return sendErrorResponse(c, http.StatusInternalServerError,
			fmt.Sprintf("failed to update localeId_%s, err: %v", localeId, err))
	}

	return c.NoContent(http.StatusNoContent)
}

// GetLocaleByIdHandler godoc
// @Summary gets locale by id
// @Description This endpoint gets locale by id
// @Tags localization
// @Accept  json
// @Produce  json
// @Param id path string true "locale id"
// @Success 200 {object} Locale
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /locales/:id [get]
func (lsh LocalizationServiceHandler) GetLocaleByIdHandler(c echo.Context) error {
	localeParamId := c.Param(LocaleIdKey)
	if localeParamId == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("locale %s path param can not be empty", LocaleIdKey))
	}

	localeId, err := NormalizeLocale(localeParamId)
	if err != nil {
		return sendErrorResponse(c, http.StatusBadRequest, err.Error())
	}

	locale, err := lsh.SqlRepo.GetLocale(localeId)
	if err != nil {
		notFoundErrMsg := fmt.Sprintf(NoSuchLocaleErrorMsg, localeId)
		if err.Error() == notFoundErrMsg {
			return sendErrorResponse(c, http.StatusNotFound, notFoundErrMsg)
		}
		return sendErrorResponse(c, http.StatusInternalServerError,
			fmt.Sprintf("failed to get localeId_%s, err: %v", localeParamId, err))
	}
	return c.JSON(http.StatusOK, locale)
}

// GetFilteredLocalesHandler godoc
// @Summary gets locales
// @Description This endpoint gets filtered (if any filters provided) paginated locales. Default values for pagination are: 0 for offset, 10 for limit.
// @Tags localization
// @Accept  json
// @Produce  json
// @Param fallback query string false "filter by fallback"
// @Param released query bool false "filter by released flag"
// @Param offset query int false "pagination offset"
// @Param limit query int false "pagination limit"
// @Success 200 {object} Locales
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /locales [get]
func (lsh LocalizationServiceHandler) GetFilteredLocalesHandler(c echo.Context) error {
	var err error
	var limit int
	var offset int

	offsetStr := c.QueryParam(offsetParam)
	if offsetStr == EmptyString {
		offset = defaultOffset
	} else {
		offset, err = strconv.Atoi(offsetStr)
		if err != nil {
			return sendErrorResponse(c, http.StatusBadRequest,
				fmt.Sprintf("parameter %s has to be a number", offsetParam))
		}
	}

	limitStr := c.QueryParam(limitParam)
	if limitStr == EmptyString {
		limit = defaultLimit
	} else {
		limit, err = strconv.Atoi(limitStr)
		if err != nil {
			return sendErrorResponse(c, http.StatusBadRequest,
				fmt.Sprintf("parameter %s has to be a number", limitParam))
		}
	}

	if limit > maxLimit {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("parameter %s has to be less or equal to %d", limitParam, maxLimit))
	}

	filters := make(map[string]interface{})

	localeFallback := c.QueryParam(FallbackKey)
	if localeFallback != EmptyString {
		filters[FallbackKey] = localeFallback
	}

	localeReleased := c.QueryParam(AssetReleasedKey)
	if localeReleased != EmptyString {
		filters[AssetReleasedKey] = localeReleased
	}

	locales, err := lsh.SqlRepo.GetLocales(filters, offset, limit)

	return c.JSON(http.StatusOK, locales)
}

// DeleteLocaleHandler godoc
// @Summary deletes locale by id
// @Description This endpoint deletes locale by id
// @Tags localization
// @Accept  json
// @Param id path string true "locale id"
// @Success 204 {object} Locale
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /locales/:id [delete]
func (lsh LocalizationServiceHandler) DeleteLocaleHandler(c echo.Context) error {
	localeParamId := c.Param(LocaleIdKey)
	if localeParamId == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf("locale %s path param can not be empty", LocaleIdKey))
	}

	localeId, err := NormalizeLocale(localeParamId)
	if err != nil {
		return sendErrorResponse(c, http.StatusBadRequest, err.Error())
	}

	err = lsh.SqlRepo.DeleteLocale(localeId)
	if err != nil {
		notFoundErrMsg := fmt.Sprintf(NoSuchLocaleErrorMsg, localeId)
		if err.Error() == notFoundErrMsg {
			return sendErrorResponse(c, http.StatusNotFound, notFoundErrMsg)
		}
		return sendErrorResponse(c, http.StatusInternalServerError,
			fmt.Sprintf(fmt.Sprintf("failed to delete record of %s %s", LocaleIdKey, localeId)))
	}

	return c.NoContent(http.StatusNoContent)
}

const cachingOff = "off"
const queryParamIsEmptyErrMsg = "query param %s can not be empty"
const failedToRetrieveAssetErrMsg = "failed to retrieve an asset for requested name %s, type %s, locale %s, also tried locale fallback %s and default locale fallback %s"
const retrievingAssetWithFallbackWarnMsg = "retrieving an asset with fallback locale %s for requested asset name %s, type %s, asset locale %s"

// GetLocalizedAssetHandler godoc
// @Summary gets localized transformed asset
// @Description This endpoint gets localized asset filtered by asset name, asset delivery type and asset locale.
// @Description It can transform an asset value if it's stored as a template (simple find and replace). Find and replace
// @Description values for an asset value have to be passed in as query parameters with a special args. prepend to manifest
// @Description itself as find and replace one.
// @Description Not implemented: If the asset has templated values but replacement query params have not been provided it will return 404.
// @Description For immediate non-cached data use caching=off query param
// @Tags localization
// @Accept  json
// @Produce  json
// @Param name path string true "asset name"
// @Param type path string true "asset type"
// @Param locale path string true "asset locale"
// @Param args.* path string false "find and replace param for the localized value"
// @Param caching path string false "caching flag"
// @Success 200 {object} Localized
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /localized [get]
func (lsh LocalizationServiceHandler) GetLocalizedAssetHandler(c echo.Context) error {
	const argsPrepend = "args."
	const argsSplit = "."

	queryParams := c.QueryParams()

	findAndReplaceValues := make(map[string]string)

	assetName := EmptyString
	assetType := EmptyString
	assetLocale := EmptyString
	caching := EmptyString

	localized := Localized{}
	localized.Ttl = 60

	for k, v := range queryParams {
		value := v[0]
		switch k {
		case AssetNameKey:
			assetName = value
		case AssetTypeKey:
			assetType = value
		case AssetLocaleKey:
			assetLocale = value
		case CachingdKey:
			caching = value
		default:
			// filters, do the args. parsing
			if !strings.Contains(k, argsPrepend) {
				return sendErrorResponse(c, http.StatusBadRequest,
					fmt.Sprintf("%s is unexpected query param", k))
			}
			filterKeySplit := strings.Split(k, argsSplit)
			filterKey := filterKeySplit[1]
			if len(filterKeySplit) != 2 {
				return sendErrorResponse(c, http.StatusBadRequest,
					fmt.Sprintf("%s is unexpected query param, can not have two dots in the query param", k))
			}
			findAndReplaceValues[filterKey] = value

			localized.Ttl = 0
		}
	}

	// validate
	if assetName == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf(queryParamIsEmptyErrMsg, AssetNameKey))
	}
	if assetLocale == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf(queryParamIsEmptyErrMsg, AssetLocaleKey))
	}
	if assetType == EmptyString {
		return sendErrorResponse(c, http.StatusBadRequest,
			fmt.Sprintf(queryParamIsEmptyErrMsg, AssetTypeKey))
	}

	var err error
	var locale Locale
	var asset Asset

	LocalesDS.L.Lock()
	localeI := LocalesDS.M[assetLocale]
	log.Debugf("number of locales in cache %d", len(LocalesDS.M))
	if localeI != nil {
		locale = localeI.(Locale)
	}
	LocalesDS.L.Unlock()
	log.Debugf("assetLocale is %s", assetLocale)
	log.Debugf("fallback locale is %s", locale.Fallback)

	asset = getAssetFromCache(assetName, assetType, assetLocale, locale.Fallback)
	if &asset != nil {
		log.Debugf("assetId is %s", asset.Id)
	}

	notFoundErrMsg := fmt.Sprintf(failedToRetrieveAssetErrMsg, assetName, assetType, assetLocale, locale.Fallback, FallbackLocale)

	if caching == cachingOff || &locale == nil || &asset == nil {
		log.Infof("caching is %s or locale is nil or asset is nil", cachingOff)
		locale, err = lsh.SqlRepo.GetLocale(assetLocale)
		if err != nil {
			if err.Error() == fmt.Sprintf(LocaleIsNotSupportedMsg, assetLocale) {
				return sendErrorResponse(c, http.StatusBadRequest, err.Error())
			}
			return sendErrorResponse(c, http.StatusInternalServerError, err.Error())
		}

		assets, err := lsh.getAssetsFromDb(c, assetName, assetType, assetLocale, locale.Fallback)
		if err != nil {
			return sendErrorResponse(c, http.StatusInternalServerError, err.Error())
		}

		if len(assets.Items) == 0 {
			return sendErrorResponse(c, http.StatusNotFound, notFoundErrMsg)
		}
		asset = assets.Items[0]
	}

	if asset.Id == EmptyString {
		return sendErrorResponse(c, http.StatusNotFound, notFoundErrMsg)
	}

	assetValue := asset.Value
	transformedLocalizedValue := transformLocalizedValue(assetValue, findAndReplaceValues)

	localized.Id = asset.Id
	localized.Name = asset.Name
	localized.Type = asset.Type
	localized.Locale = asset.Locale
	localized.LocalizedValue = transformedLocalizedValue

	return c.JSON(http.StatusOK, localized)
}

// GetLocalizedAssetsInBulkHandler godoc
// @Summary gets one or more localized transformed assets
// @Description This endpoint gets localized assets filtered by asset name, asset delivery type and asset locale
// @Description (each individual filter is baked in items of request body).
// @Description It can transform an asset value if it's stored as a template (simple find and replace). Find and replace
// @Description values for an asset value have to be passed as an args property of the request body of the item.
// @Description Not implemented: If the asset has templated values but replacement query params have not been provided it will return 404.
// @Description For immediate non-cached data use caching=off query param
// @Tags localization
// @Accept  json
// @Produce  json
// @Param asset body LocalizedRequestItems true "create asset"
// @Param caching path string false "caching flag"
// @Success 200 {object} Localized
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /localized [post]
func (lsh LocalizationServiceHandler) GetLocalizedAssetsInBulkHandler(c echo.Context) error {

	var err error
	var localizedRequestItems LocalizedRequestItems

	caching := c.QueryParam(CachingdKey)

	bindErrorMsg := "failed to bind request body"
	err = c.Bind(&localizedRequestItems)
	if err != nil {
		log.Errorf("%s, err: %v", bindErrorMsg, err)
		return c.JSON(http.StatusBadRequest, ErrorResponse{
			StatusCode: http.StatusBadRequest,
			Message:    bindErrorMsg,
		})
	}

	// TODO: make one DB query instead, io operation in a loop is bad
	var localizedSlice []interface{}
	var errorObjs []interface{}
	for _, localizedRequest := range localizedRequestItems.Items {
		var errorObj map[string]string
		var locale Locale
		var asset Asset

		assetLocale := localizedRequest.Locale
		assetName := localizedRequest.Name
		assetType := localizedRequest.Type

		LocalesDS.L.Lock()
		localeI := LocalesDS.M[assetLocale]
		if localeI != nil {
			locale = localeI.(Locale)
		}
		LocalesDS.L.Unlock()

		asset = getAssetFromCache(assetName, assetType, assetLocale, locale.Fallback)
		if &asset != nil {
			log.Debugf("assetId is %s", asset.Id)
		}

		errorNotFoundObj := getErrorObj(assetName, fmt.Sprintf(failedToRetrieveAssetErrMsg, assetName, assetType,
			assetLocale, locale.Fallback, FallbackLocale))

		if caching == cachingOff || &locale == nil || &asset == nil {
			locale, err := lsh.SqlRepo.GetLocale(assetLocale)
			if err != nil {
				if err.Error() == fmt.Sprintf(LocaleIsNotSupportedMsg, assetLocale) {
					errorObj = getErrorObj(assetName, fmt.Sprintf(LocaleIsNotSupportedMsg, assetLocale))
				} else {
					return sendErrorResponse(c, http.StatusInternalServerError, err.Error())
				}
			}
			fallback := FallbackLocale
			if &locale != nil {
				fallback = locale.Fallback
			}
			assets, err := lsh.getAssetsFromDb(c, assetName, assetType, assetLocale, fallback)
			if err != nil {
				return sendErrorResponse(c, http.StatusInternalServerError, err.Error())
			}
			if len(assets.Items) == 0 {
				errorObj = errorNotFoundObj
			}
			asset = assets.Items[0]
		}

		if asset.Id == EmptyString {
			errorObj = errorNotFoundObj
		}

		if errorObj != nil {
			errorObjs = append(errorObjs, errorObj)
		} else {
			assetValue := asset.Value
			args := stringify(localizedRequest.Args)
			transformedLocalizedValue := transformLocalizedValue(assetValue, args)

			localized := Localized{}
			localized.Id = asset.Id
			localized.Name = asset.Name
			localized.Type = asset.Type
			localized.Locale = asset.Locale
			localized.LocalizedValue = transformedLocalizedValue
			localizedSlice = append(localizedSlice, localized)
		}
	}

	localizedItems := LocalizedItems{}
	localizedItems.Items = localizedSlice
	localizedItems.Errors = errorObjs
	localizedItems.Meta = LocalizedMeta{
		ErrorsCount: len(errorObjs),
		ItemsCount:  len(localizedSlice),
		Total:       len(errorObjs) + len(localizedSlice),
	}

	return c.JSON(http.StatusOK, localizedItems)
}

func getErrorObj(assetName string, notFoundErrMsg string) map[string]string {
	errorObj := make(map[string]string)
	errorObj["name"] = assetName
	errorObj["error"] = notFoundErrMsg
	return errorObj
}

func (lsh LocalizationServiceHandler) getAssetsFromDb(c echo.Context, assetName string, assetType string, assetLocale string,
	fallbackLocale string) (Assets, error) {
	var err error
	var assets Assets

	var lenOfAssetsItems = 0
	count := 0
	for lenOfAssetsItems == 0 && count < 3 {
		tempLocale := assetLocale
		if count == 1 {
			// retry to get assets with locale fallback
			log.Debugf(retrievingAssetWithFallbackWarnMsg, fallbackLocale, assetName, assetType, assetLocale)
			tempLocale = fallbackLocale
		}
		if count == 2 {
			// retry to get assets with default locale fallback which is expected to be to en-us
			log.Debugf(retrievingAssetWithFallbackWarnMsg, FallbackLocale, assetName, assetType, assetLocale)
			tempLocale = FallbackLocale
		}

		assets, err = lsh.SqlRepo.GetAssets(map[string]interface{}{
			AssetNameKey:     assetName,
			AssetTypeKey:     assetType,
			AssetLocaleKey:   tempLocale,
			AssetReleasedKey: true,
		}, nil, 0, 1)
		if err != nil {
			return Assets{}, err
		}
		lenOfAssetsItems = len(assets.Items)
		count++
	}
	return assets, nil
}

func getAssetFromCache(assetName string, assetType string, assetLocale string, fallbackLocale string) Asset {

	var assetI interface{}
	var asset Asset

	count := 0
	for assetI == nil && count < 3 {
		tempLocale := assetLocale
		if count == 1 {
			// retry to get assets with locale fallback
			log.Debugf(retrievingAssetWithFallbackWarnMsg, fallbackLocale, assetName, assetType, assetLocale)
			tempLocale = fallbackLocale
		}
		if count == 2 {
			// retry to get assets with default locale fallback which is expected to be to en-us
			log.Debugf(retrievingAssetWithFallbackWarnMsg, FallbackLocale, assetName, assetType, assetLocale)
			tempLocale = FallbackLocale
		}

		AssetsDS.L.Lock()
		assetPrimeKey := GetAssetPrimaryKey(assetName, assetType, tempLocale)
		assetI = AssetsDS.M[assetPrimeKey]
		log.Debugf("number of assets in cache %d", len(AssetsDS.M))
		AssetsDS.L.Unlock()
		count++
	}

	if assetI != nil {
		asset = assetI.(Asset)
	}

	return asset
}

func transformLocalizedValue(textToTransform string, findAndReplaceValues map[string]string) string {
	updatedText := textToTransform
	for k, v := range findAndReplaceValues {
		strToReplace := composeStringToReplace(k)
		updatedText = strings.ReplaceAll(updatedText, strToReplace, v)
	}
	return updatedText
}

func composeStringToReplace(v string) string {
	return fmt.Sprintf("{$%s}", v)
}

func stringify(input map[string]interface{}) map[string]string {
	result := make(map[string]string)
	for k, v := range input {
		result[k] = fmt.Sprintf("%v", v)
	}
	return result
}

// PingHandler godoc
// @Summary validates if the service is up
// @Description check the health status of the service (web server and db connection), lists its build data (commit sha, commit name, build date)
// @Tags localization
// @Accept  json
// @Produce  json
// @Success 200 {array} Ping
// @Failure 500 {object} ErrorResponse
// @Router /ping [get]
func PingHandler(c echo.Context) (err error) {
	if err = DB.Ping(); err != nil {
		return c.JSON(http.StatusInternalServerError, ErrorResponse{
			StatusCode: http.StatusInternalServerError,
			Message:    "connection to DB has been lost",
		})
	}

	epochInt := 0
	if len(BuildDate) > 0 && BuildDate != NoneValue {
		epochInt, err = strconv.Atoi(BuildDate)
		if err != nil {
			epochInt = 0
		}
	}

	return c.JSON(http.StatusOK, Ping{
		Status:      http.StatusOK,
		Service:     ServiceName,
		CommitName:  CommitName,
		CommitSHA:   CommitSHA,
		BuildDate:   time.Unix(int64(epochInt), 0).UTC().Format(time.RFC3339),
		Environment: Env,
		Timestamp:   time.Now().UTC().Truncate(time.Minute).Format(time.RFC3339),
	})
}

// TODO: it's a temporary solution until dep modules are fixed
//  the intent was to use https://github.com/swaggo/echo-swagger project but it has a dependency on echo/v4 package
//  dep currently has a bug around modules, but it's probably going to be worked on https://github.com/golang/dep/issues/2139#issuecomment-489500969

// Config stores echoSwagger configuration variables.
type Config struct {
	//The url pointing to API definition (normally swagger.json or swagger.yaml). Default is `doc.json`.
	URL string
}

// URL presents the url pointing to API definition (normally swagger.json or swagger.yaml).
func URL(url string) func(c *Config) {
	return func(c *Config) {
		c.URL = url
	}
}

// SwaggerHandler wraps swaggerFiles.Handler and returns echo.HandlerFunc
var SwaggerHandler = EchoWrapHandler()

// EchoWrapHandler wraps `http.Handler` into `echo.HandlerFunc`.
func EchoWrapHandler(confs ...func(c *Config)) echo.HandlerFunc {

	handler := swaggerFiles.Handler

	config := &Config{
		URL: "doc.json",
	}

	for _, c := range confs {
		c(config)
	}

	// create a template with name
	t := template.New("swagger_index.html")
	index, _ := t.Parse(indexTempl)

	type pro struct {
		Host string
	}

	var re = regexp.MustCompile(`(.*)(index\.html|doc\.json|favicon-16x16\.png|favicon-32x32\.png|/oauth2-redirect\.html|swagger-ui\.css|swagger-ui\.css\.map|swagger-ui\.js|swagger-ui\.js\.map|swagger-ui-bundle\.js|swagger-ui-bundle\.js\.map|swagger-ui-standalone-preset\.js|swagger-ui-standalone-preset\.js\.map)[\?|.]*`)

	return func(c echo.Context) error {
		var matches []string
		if matches = re.FindStringSubmatch(c.Request().RequestURI); len(matches) != 3 {

			return c.String(http.StatusNotFound, "404 page not found")
		}
		path := matches[2]
		prefix := matches[1]
		handler.Prefix = prefix

		switch path {
		case "index.html":

			index.Execute(c.Response().Writer, config)
		case "doc.json":
			doc, _ := swag.ReadDoc()
			c.Response().Write([]byte(doc))
		default:
			handler.ServeHTTP(c.Response().Writer, c.Request())

		}

		return nil
	}
}

const indexTempl = `<!-- HTML for static distribution bundle build -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Swagger UI</title>
  <link href="https://fonts.googleapis.com/css?family=Open+Sans:400,700|Source+Code+Pro:300,600|Titillium+Web:400,600,700" rel="stylesheet">
  <link rel="stylesheet" type="text/css" href="./swagger-ui.css" >
  <link rel="icon" type="image/png" href="./favicon-32x32.png" sizes="32x32" />
  <link rel="icon" type="image/png" href="./favicon-16x16.png" sizes="16x16" />
  <style>
    html
    {
        box-sizing: border-box;
        overflow: -moz-scrollbars-vertical;
        overflow-y: scroll;
    }
    *,
    *:before,
    *:after
    {
        box-sizing: inherit;
    }
    body {
      margin:0;
      background: #fafafa;
    }
  </style>
</head>
<body>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="position:absolute;width:0;height:0">
  <defs>
    <symbol viewBox="0 0 20 20" id="unlocked">
          <path d="M15.8 8H14V5.6C14 2.703 12.665 1 10 1 7.334 1 6 2.703 6 5.6V6h2v-.801C8 3.754 8.797 3 10 3c1.203 0 2 .754 2 2.199V8H4c-.553 0-1 .646-1 1.199V17c0 .549.428 1.139.951 1.307l1.197.387C5.672 18.861 6.55 19 7.1 19h5.8c.549 0 1.428-.139 1.951-.307l1.196-.387c.524-.167.953-.757.953-1.306V9.199C17 8.646 16.352 8 15.8 8z"></path>
    </symbol>
    <symbol viewBox="0 0 20 20" id="locked">
      <path d="M15.8 8H14V5.6C14 2.703 12.665 1 10 1 7.334 1 6 2.703 6 5.6V8H4c-.553 0-1 .646-1 1.199V17c0 .549.428 1.139.951 1.307l1.197.387C5.672 18.861 6.55 19 7.1 19h5.8c.549 0 1.428-.139 1.951-.307l1.196-.387c.524-.167.953-.757.953-1.306V9.199C17 8.646 16.352 8 15.8 8zM12 8H8V5.199C8 3.754 8.797 3 10 3c1.203 0 2 .754 2 2.199V8z"/>
    </symbol>
    <symbol viewBox="0 0 20 20" id="close">
      <path d="M14.348 14.849c-.469.469-1.229.469-1.697 0L10 11.819l-2.651 3.029c-.469.469-1.229.469-1.697 0-.469-.469-.469-1.229 0-1.697l2.758-3.15-2.759-3.152c-.469-.469-.469-1.228 0-1.697.469-.469 1.228-.469 1.697 0L10 8.183l2.651-3.031c.469-.469 1.228-.469 1.697 0 .469.469.469 1.229 0 1.697l-2.758 3.152 2.758 3.15c.469.469.469 1.229 0 1.698z"/>
    </symbol>
    <symbol viewBox="0 0 20 20" id="large-arrow">
      <path d="M13.25 10L6.109 2.58c-.268-.27-.268-.707 0-.979.268-.27.701-.27.969 0l7.83 7.908c.268.271.268.709 0 .979l-7.83 7.908c-.268.271-.701.27-.969 0-.268-.269-.268-.707 0-.979L13.25 10z"/>
    </symbol>
    <symbol viewBox="0 0 20 20" id="large-arrow-down">
      <path d="M17.418 6.109c.272-.268.709-.268.979 0s.271.701 0 .969l-7.908 7.83c-.27.268-.707.268-.979 0l-7.908-7.83c-.27-.268-.27-.701 0-.969.271-.268.709-.268.979 0L10 13.25l7.418-7.141z"/>
    </symbol>
    <symbol viewBox="0 0 24 24" id="jump-to">
      <path d="M19 7v4H5.83l3.58-3.59L8 6l-6 6 6 6 1.41-1.41L5.83 13H21V7z"/>
    </symbol>
    <symbol viewBox="0 0 24 24" id="expand">
      <path d="M10 18h4v-2h-4v2zM3 6v2h18V6H3zm3 7h12v-2H6v2z"/>
    </symbol>
  </defs>
</svg>
<div id="swagger-ui"></div>
<script src="./swagger-ui-bundle.js"> </script>
<script src="./swagger-ui-standalone-preset.js"> </script>
<script>
window.onload = function() {
  // Build a system
  const ui = SwaggerUIBundle({
    url: "{{.URL}}",
    dom_id: '#swagger-ui',
    validatorUrl: null,
    presets: [
      SwaggerUIBundle.presets.apis,
      SwaggerUIStandalonePreset
    ],
    plugins: [
      SwaggerUIBundle.plugins.DownloadUrl
    ],
    layout: "StandaloneLayout"
  })
  window.ui = ui
}
</script>
</body>
</html>`

func (lsh LocalizationServiceHandler) CreateNewTagHandler(c echo.Context) error {
	// TODO:

	return nil
}

func (lsh LocalizationServiceHandler) AddTagToAssetOfParticularTypeHandler(c echo.Context) error {
	// TODO:

	return nil
}

func (lsh LocalizationServiceHandler) GetAllTagsHandler(c echo.Context) error {
	// TODO:

	return nil
}

func (lsh LocalizationServiceHandler) TagAssetHandler(c echo.Context) error {
	// TODO:

	return nil
}

func (lsh LocalizationServiceHandler) DeleteTagHandler(c echo.Context) error {
	// TODO: implement

	return nil
}

// GetAllTypesHandler godoc
// @Summary gets types
// @Description This endpoint gets filtered (if any filters provided) paginated types. Default values for pagination are: 0 for offset, 10 for limit.
// @Tags localization
// @Produce  json
// @Param caching query bool false "caching=off forces the handler to go directly to database"
// @Param offset query int false "pagination offset"
// @Param limit query int false "pagination limit"
// @Success 200 {object} Types
// @Success 200 {object} TypeItems
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Failure 500 {object} ErrorResponse
// @Router /types [get]
func (lsh LocalizationServiceHandler) GetAllTypesHandler(c echo.Context) (err error) {
	caching := c.QueryParam(CachingdKey)
	if caching == cachingOff {
		var limit *int
		var offset *int

		offsetStr := c.QueryParam(offsetParam)
		if offsetStr != EmptyString {
			offset = new(int)
			*offset, err = strconv.Atoi(offsetStr)
			if err != nil {
				return sendErrorResponse(c, http.StatusBadRequest,
					fmt.Sprintf("parameter %s has to be a number", offsetParam))
			}
		}

		limitStr := c.QueryParam(limitParam)
		if limitStr != EmptyString {
			limit = new(int)
			*limit, err = strconv.Atoi(limitStr)
			if err != nil {
				return sendErrorResponse(c, http.StatusBadRequest,
					fmt.Sprintf("parameter %s has to be a number", limitParam))
			}
		}

		if limit == nil && offset == nil {
			types, err := lsh.SqlRepo.GetAllTypes()
			if err != nil {
				return sendErrorResponse(c, http.StatusInternalServerError,
					err.Error())
			}
			return c.JSON(http.StatusOK, types)
		} else {

			if *limit > maxLimit {
				return sendErrorResponse(c, http.StatusBadRequest,
					fmt.Sprintf("parameter %s has to be less or equal to %d", limitParam, maxLimit))
			}

			types, err := lsh.SqlRepo.GetAllTypesFiltered(offset, limit)
			if err != nil {
				return sendErrorResponse(c, http.StatusInternalServerError,
					err.Error())
			}
			return c.JSON(http.StatusOK, types)
		}
	} else {
		TypesDS.L.RLock()
		typesI := TypesDS.M
		TypesDS.L.RUnlock()
		if typesI == nil {
			return sendErrorResponse(c, http.StatusInternalServerError,
				"cached types map is nil")
		} else {
			var types []Type
			for _, t := range typesI {
				types = append(types, t.(Type))
			}
			if types == nil {
				// if there is no data in cache get all the types from DB directly
				types, err := lsh.SqlRepo.GetAllTypes()
				if err != nil {
					return sendErrorResponse(c, http.StatusInternalServerError,
						err.Error())
				}
				return c.JSON(http.StatusOK, types)
			}
			return c.JSON(http.StatusOK, TypeItems{
				Items: types,
			})
		}
	}
}

func sendErrorResponse(c echo.Context, statusCode int, errMsg string) error {
	log.Error(errMsg)
	return c.JSON(statusCode, ErrorResponse{
		StatusCode: statusCode,
		Message:    errMsg,
	})
}

func isValidAssetId(assetId string) bool {
	return AssetIdRegex.MatchString(assetId)
}
