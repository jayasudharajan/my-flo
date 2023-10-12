package main

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/labstack/gommon/log"
	"github.com/lib/pq"
)

const totalRowsBaseSQL = `
	SELECT COUNT(*) as count
	FROM %s`

const totalLocalesSQL = `
	SELECT COUNT(*) as count
	FROM locales`

const totalTypesSQL = `
	SELECT COUNT(*) as count
	FROM types`

const insertAssetSQL = ` 
	INSERT INTO assets (
		id,
		name,
		type,
		locale,
		released,
        value,
        tags,
		updated
	) SELECT $1,$2,$3,$4,$5,$6,$7,$8
	WHERE EXISTS (SELECT 1 FROM locales WHERE id=CAST($4 AS VARCHAR))
    RETURNING id, name, type, locale, released, value, tags, created, updated;`

const insertLocaleSQL = `
	INSERT INTO locales (
        id,
	    fallback,
        released,
	    updated
	) VALUES ($1,$2,$3,$4)
`

const checkIfLocaleExistsSQL = `SELECT EXISTS (SELECT 1 FROM locales WHERE id=$1)`

const getAllAssetsSQL = `SELECT * FROM assets`

const getAllLocalesSQL = `SELECT * FROM locales`

const getAllTypesFilteredSQL = `SELECT * FROM types OFFSET $1 LIMIT $2`

const getAllTypesSQL = `SELECT * FROM types`

const getAssetByIdSQL = `SELECT * FROM assets WHERE id=$1`

const getLocaleByIdSQL = `SELECT * FROM locales WHERE id=$1`

const deleteAssetByIdSQL = `DELETE FROM assets WHERE id=$1`

const deleteLocaleByIdSQL = `DELETE FROM locales WHERE id=$1`

const partialColumnSearchQueryWithWhereStringSQL = `WHERE %s ILIKE '%s'`

const partialColumnSearchQueryStringSQL = `%s ILIKE '%s'`

func compilePartialColumnSearchQueryWithWhereString(column string, partialStr string) string {
	v := strings.Join([]string{"%", partialStr, "%"}, EmptyString)
	partialQuery := fmt.Sprintf(partialColumnSearchQueryWithWhereStringSQL, column, v)
	return partialQuery
}

func compilePartialColumnSearchQueryString(column string, partialStr string) string {
	v := strings.Join([]string{"%", partialStr, "%"}, EmptyString)
	partialQuery := fmt.Sprintf(partialColumnSearchQueryStringSQL, column, v)
	return partialQuery
}

func compileGetTotalCountQuery(table string, filters []string, fuzzySearchFilters map[string]string) string {
	selectQuery := fmt.Sprintf(totalRowsBaseSQL, table)
	var columnValues []string
	filtersLength := len(filters)
	whereClause := EmptyString
	if filtersLength != 0 {
		for i, f := range filters {
			pair := fmt.Sprintf("%s=$%d", f, i+1)
			columnValues = append(columnValues, pair)
		}
		whereClause = fmt.Sprintf("WHERE %s", strings.Join(columnValues, " AND "))
	}
	var partialSearchQueries []string
	var partialSearchQueriesClause = EmptyString
	if fuzzySearchFilters != nil && len(fuzzySearchFilters) > 0 {
		for c, f := range fuzzySearchFilters {
			partialSearchQ := compilePartialColumnSearchQueryWithWhereString(c, f)
			if filtersLength > 0 {
				partialSearchQ = compilePartialColumnSearchQueryString(c, f)
			}
			partialSearchQueries = append(partialSearchQueries, partialSearchQ)
		}
		partialSearchQueriesClause = strings.Join(partialSearchQueries, " AND ")
		if filtersLength > 0 {
			partialSearchQueriesClause = fmt.Sprintf(" AND %s", partialSearchQueriesClause)
		}
	}
	result := fmt.Sprintf("%s %s %s", selectQuery, whereClause, partialSearchQueriesClause)
	return result
}

func compileGetAllRowsQuery(table string, filters []string, fuzzySearchFilters map[string]string, orderBy string, isLimitOffset bool) string {
	selectFromTableClause := fmt.Sprintf("SELECT * FROM %s", table)
	var columnValues []string
	filtersLength := len(filters)
	whereClause := EmptyString
	if filtersLength != 0 {
		for i, f := range filters {
			pair := fmt.Sprintf("%s=$%d", f, i+1)
			columnValues = append(columnValues, pair)
		}
		whereClause = fmt.Sprintf("WHERE %s", strings.Join(columnValues, " AND "))
	}
	var partialSearchQueries []string
	var partialSearchQueriesClause = EmptyString
	if fuzzySearchFilters != nil && len(fuzzySearchFilters) > 0 {
		for c, f := range fuzzySearchFilters {
			partialSearchQ := compilePartialColumnSearchQueryWithWhereString(c, f)
			if filtersLength > 0 {
				partialSearchQ = compilePartialColumnSearchQueryString(c, f)
			}
			partialSearchQueries = append(partialSearchQueries, partialSearchQ)
		}
		partialSearchQueriesClause = strings.Join(partialSearchQueries, " AND ")
		if filtersLength > 0 {
			partialSearchQueriesClause = fmt.Sprintf(" AND %s", partialSearchQueriesClause)
		}
	}
	result := fmt.Sprintf("%s %s %s", selectFromTableClause, whereClause, partialSearchQueriesClause)
	if isLimitOffset {
		offsetPlaceHolder := fmt.Sprintf("$%d", len(filters)+1)
		limitPlaceHolder := fmt.Sprintf("$%d", len(filters)+2)
		result = fmt.Sprintf("%s %s %s %s OFFSET %s LIMIT %s", selectFromTableClause, whereClause, partialSearchQueriesClause, orderBy, offsetPlaceHolder, limitPlaceHolder)
	}
	return result
}

func compileUpdateQuery(table, idKey string, columnsToUpdate []string) string {
	updateTable := fmt.Sprintf("UPDATE %s", table)
	var columnsWithValues []string
	for i, f := range columnsToUpdate {
		pair := fmt.Sprintf("%s=$%d", f, i+1)
		columnsWithValues = append(columnsWithValues, pair)
	}
	setColumns := fmt.Sprintf("SET %s", strings.Join(columnsWithValues, ", "))

	return fmt.Sprintf("%s %s WHERE %s=$%d", updateTable, setColumns, idKey, len(columnsToUpdate)+1)
}

func (r *LocalizationRepository) GetAllTypesFiltered(offsetInput *int, limitInput *int) (types Types, err error) {
	offset := DefaultOffset
	if offsetInput != nil {
		offset = *offsetInput
	}

	limit := DefaultLimit
	if limitInput != nil {
		if *limitInput <= DefaultLimit {
			limit = *limitInput
		}
	}

	rows, err := r.DB.Query(getAllTypesFilteredSQL, offset, limit)
	if err != nil {
		log.Errorf("query %s has failed, err: %v", getAllTypesFilteredSQL, err)
		return types, err
	}
	var tempTypes []Type
	for rows.Next() {
		var aType Type
		aType, err = scanToType(rows.Scan)
		tempTypes = append(tempTypes, aType)
	}

	const unknownTotal = -1
	total, err := r.GetTotalRows(totalTypesSQL, nil)
	if err != nil {
		total = unknownTotal
	}

	types = Types{}
	types.Meta = Meta{
		Total:  total,
		Offset: offset,
		Limit:  limit,
	}
	types.Items = tempTypes

	if &types == nil {
		return Types{}, nil
	}

	return types, nil
}

func (r *LocalizationRepository) GetAllTypes() (types TypeItems, err error) {
	types = TypeItems{
		Items: make([]Type, 0),
	}
	rows, err := r.DB.Query(getAllTypesSQL)
	if err != nil {
		return types, fmt.Errorf("query %s has failed, err: %v", getAllTypesSQL, err)
	}
	var tempTypes []Type
	for rows.Next() {
		var aType Type
		aType, err = scanToType(rows.Scan)
		if err != nil {
			return types, err
		}
		tempTypes = append(tempTypes, aType)
	}

	types.Items = tempTypes

	return types, nil
}

func scanToType(scan scanFunc) (Type, error) {

	var aType Type
	var aTypeType sql.NullString
	var aTypeDescription sql.NullString
	var aTypeCreated sql.NullString
	var aTypeUpdated sql.NullString

	err := scan(
		&aTypeType,
		&aTypeDescription,
		&aTypeCreated,
		&aTypeUpdated,
	)
	if err != nil {
		return Type{}, err
	}

	aType.Type = aTypeType.String
	aType.Description = aTypeDescription.String

	tc, err := time.Parse(time.RFC3339, aTypeCreated.String)
	if err != nil {
		log.Errorf(conversionTimeErrMsg, err)
	}
	aType.Created = tc

	tu, err := time.Parse(time.RFC3339, aTypeUpdated.String)
	if err != nil {
		log.Errorf(conversionTimeErrMsg, err)
	}
	aType.Updated = tu

	return aType, nil
}

// LocalizationRepository is the localization repository
type LocalizationRepository struct {
	DB                *sql.DB
	AssetTagsMappings AssetTagsMappings
}

const rollbackLocaleDataErrMsg = "failed to rollback %s locale data, err: %v"

// CreateNewLocale creates new locale
func (r *LocalizationRepository) CreateNewLocale(locale Locale) error {
	t := time.Now().UTC().Format(time.RFC3339)

	_, err := r.DB.Exec(insertLocaleSQL, locale.Id, locale.Fallback, locale.Released, t)
	if pgerr, ok := err.(*pq.Error); ok {
		if pgerr.Code == duplicateKeyErrorCode {
			return fmt.Errorf(LocaleAlreadyExistsErrorMsg, locale.Id)
		}
	}

	if err != nil {
		return err
	}
	return nil
}

// UpdateLocale updates locale properties in the locales table.
func (r *LocalizationRepository) UpdateLocale(localeFields map[string]interface{}, localeId string) (err error) {

	const updatedKey = "updated"

	var columns []string
	var values []interface{}

	// start compiling update query with updated ts
	updated, ok := localeFields[updatedKey]
	if !ok {
		updated = time.Now().UTC().Format(time.RFC3339)
	}
	values = append(values, updated)
	columns = append(columns, updatedKey)

	for k, v := range localeFields {
		values = append(values, v)
		columns = append(columns, k)
	}

	// in order to have consistent ordering, adding localeId to tail
	values = append(values, localeId)

	updateQuery := compileUpdateQuery(LocalesKey, LocaleIdKey, columns)

	res, err := r.DB.Exec(updateQuery, values...)
	// if no rows have been updated
	if res != nil {
		count, _ := res.RowsAffected()
		if count == 0 {
			return fmt.Errorf(NoSuchLocaleErrorMsg, localeId)
		}
	}
	if err != nil {
		return fmt.Errorf("failed to update %s locale fields, err: %v", localeId, err)
	}
	return nil
}

// GetLocales returns multiple locales filtered
func (r *LocalizationRepository) GetLocales(filters map[string]interface{}, offset int, limit int) (locales Locales, err error) {
	const unknownTotal = -1
	total, err := r.GetTotalRows(totalLocalesSQL, nil)
	if err != nil {
		total = unknownTotal
	}
	meta := Meta{
		Total:  total,
		Offset: offset,
		Limit:  limit,
	}
	locales.Meta = meta

	var items []Locale
	var filterKeys []string
	var filtersValues []interface{}
	for k, v := range filters {
		filterKeys = append(filterKeys, k)
		filtersValues = append(filtersValues, v)
	}

	// tail offset and limit
	filtersValues = append(filtersValues, offset)
	filtersValues = append(filtersValues, limit)

	q := compileGetAllRowsQuery("locales", filterKeys, nil, "ORDER BY id ASC", true)
	rows, err := r.DB.Query(q, filtersValues...)
	if err != nil {

		return Locales{}, fmt.Errorf("query %s has failed, err: %v", q, err)
	}
	for rows.Next() {
		var locale Locale
		locale, err = scanToLocale(rows.Scan)
		items = append(items, locale)
	}
	if items == nil {
		items = []Locale{}
	}
	locales.Items = items
	return locales, nil
}

func (r *LocalizationRepository) GetAllLocales() (locales []Locale, err error) {
	rows, err := r.DB.Query(getAllLocalesSQL)
	if err != nil {
		return locales, fmt.Errorf("query %s has failed, err: %v", getAllLocalesSQL, err)
	}
	for rows.Next() {
		var locale Locale
		locale, err = scanToLocale(rows.Scan)
		locales = append(locales, locale)
	}
	if locales == nil {
		return make([]Locale, 0), nil
	}
	return locales, nil
}

// GetLocale returns one locale queried by locale Id if it exists.
func (r *LocalizationRepository) GetLocale(localeId string) (locale Locale, err error) {
	row := r.DB.QueryRow(getLocaleByIdSQL, localeId)

	if row == nil {
		return Locale{}, fmt.Errorf("something went wrong while retrieving localeId_%s, row is nil", localeId)
	}

	locale, err = scanToLocale(row.Scan)

	if err != nil {
		if err == sql.ErrNoRows {
			return Locale{}, fmt.Errorf(NoSuchLocaleErrorMsg, localeId)
		}
		return Locale{}, err
	}

	return locale, nil
}

// DeleteLocale deletes locale record from locales table.
func (r *LocalizationRepository) DeleteLocale(localeId string) (err error) {
	res, err := r.DB.Exec(deleteLocaleByIdSQL, localeId)
	if err != nil {
		log.Errorf("failed to delete %s locale data, err: %v", localeId, err)
		if err != nil {
			log.Errorf(rollbackLocaleDataErrMsg, localeId, err)
		}
	}
	count, _ := res.RowsAffected()
	// if no rows has been deleted
	if count == 0 {
		return fmt.Errorf(NoSuchLocaleErrorMsg, localeId)
	}
	return nil
}

func scanToLocale(scan scanFunc) (Locale, error) {

	var locale Locale
	// golang sql Scan shits the bed on null values, therefore gophers have to deal with it:
	var localeId sql.NullString
	var localeFallback sql.NullString
	var localeReleased sql.NullBool
	var localeCreated sql.NullString
	var localeUpdated sql.NullString

	err := scan(
		&localeId,
		&localeFallback,
		&localeReleased,
		&localeCreated,
		&localeUpdated,
	)
	if err != nil {
		return Locale{}, err
	}

	locale.Id = localeId.String
	locale.Fallback = localeFallback.String
	locale.Released = localeReleased.Bool

	tc, err := time.Parse(time.RFC3339, localeCreated.String)
	if err != nil {
		log.Errorf(conversionTimeErrMsg, err)
	}
	locale.Created = tc

	tu, err := time.Parse(time.RFC3339, localeUpdated.String)
	if err != nil {
		log.Errorf(conversionTimeErrMsg, err)
	}
	locale.Updated = tu

	return locale, nil
}

const rollbackAssetDataErrMsg = "failed to rollback %s asset data, err: %v"
const conversionTimeErrMsg = "failed to convert time, err: %v"
const duplicateKeyErrorCode = "23505"

// CreateNewAsset creates new asset
func (r *LocalizationRepository) CreateNewAsset(asset Asset) (Asset, error) {
	t := time.Now().UTC().Format(time.RFC3339)
	rows, err := r.DB.Query(insertAssetSQL, asset.Id, asset.Name, asset.Type, asset.Locale, asset.Released, asset.Value, pq.Array(asset.Tags), t)
	if pqErr, ok := err.(*pq.Error); ok {
		if pqErr.Code == duplicateKeyErrorCode {
			return Asset{}, fmt.Errorf(AssetAlreadyExistsErrorMsg, asset.Id)
		}
	}
	var result Asset
	if rows != nil {
		for rows.Next() {
			result, err = scanToAsset(rows.Scan)
		}
	}
	if err != nil {
		return Asset{}, err
	}
	if result.Id == EmptyString && result.Locale == EmptyString {
		return Asset{}, fmt.Errorf(LocaleIsNotSupportedMsg, asset.Locale)
	}
	return result, nil
}

// UpdateAsset updates asset properties in the assets table
func (r *LocalizationRepository) UpdateAsset(assetFields map[string]interface{}, assetId string) (err error) {

	if localeId, ok := assetFields[AssetLocaleKey]; ok {
		locale := localeId.(string)
		isSupported, err := r.IsSupportedLocale(locale)
		if err != nil {
			return err
		}
		if !isSupported {
			return fmt.Errorf(LocaleIsNotSupportedMsg, locale)
		}
	}

	const updatedKey = "updated"

	var columns []string
	var values []interface{}

	// start compiling update query with updated ts
	updated, ok := assetFields[updatedKey]
	if !ok {
		updated = time.Now().UTC().Format(time.RFC3339)
	}
	values = append(values, updated)
	columns = append(columns, updatedKey)

	for k, v := range assetFields {
		values = append(values, v)
		columns = append(columns, k)
	}

	// in order to have consistent ordering, adding assetId to tail
	values = append(values, assetId)

	updateQuery := compileUpdateQuery(AssetsKey, AssetIdKey, columns)

	res, err := r.DB.Exec(updateQuery, values...)
	// if no rows have been updated
	if res != nil {
		count, _ := res.RowsAffected()
		if count == 0 {
			return fmt.Errorf(NoSuchAssetErrorMsg, assetId)
		}
	}
	if err != nil {
		return fmt.Errorf("failed to update %s asset fields, err: %v", assetId, err)
	}
	return nil
}

// GetAssets returns multiple assets filtered
func (r *LocalizationRepository) GetAssets(filters map[string]interface{}, fuzzySearchFilters map[string]string,
	offset int, limit int) (Assets, error) {
	var err error
	assets := Assets{}

	var items []Asset
	var filterKeys []string
	var filtersValues []interface{}
	for k, v := range filters {
		filterKeys = append(filterKeys, k)
		filtersValues = append(filtersValues, v)
	}

	tq := compileGetTotalCountQuery("assets", filterKeys, fuzzySearchFilters)
	log.Debugf("TOTAL QUERY: %s", tq)
	total, err := r.GetTotalRows(tq, filtersValues)
	if err != nil {
		log.Errorf("failed to get total rows for the queried assets, err: %v", err)
		total = len(items)
	}
	meta := Meta{
		Total:  total,
		Offset: offset,
		Limit:  limit,
	}
	assets.Meta = meta

	// tail offset and limit
	filtersValues = append(filtersValues, offset)
	filtersValues = append(filtersValues, limit)

	q := compileGetAllRowsQuery("assets", filterKeys, fuzzySearchFilters, "ORDER BY name ASC", true)
	log.Debugf("QUERY: %s", q)
	rows, err := r.DB.Query(q, filtersValues...)
	if err != nil {
		return Assets{}, fmt.Errorf("query %s has failed, err: %v", q, err)
	}
	for rows.Next() {
		var asset Asset
		asset, err = scanToAsset(rows.Scan)
		items = append(items, asset)
	}
	if items == nil {
		items = []Asset{}
	}

	assets.Items = items

	return assets, nil
}

// GetAllAssets gets all assets
func (r *LocalizationRepository) GetAllAssets() (assets []Asset, err error) {
	rows, err := r.DB.Query(getAllAssetsSQL)
	if err != nil {
		return assets, fmt.Errorf("query %s has failed, err: %v", getAllAssetsSQL, err)
	}
	for rows.Next() {
		var asset Asset
		asset, err = scanToAsset(rows.Scan)
		assets = append(assets, asset)
	}
	if assets == nil {
		return make([]Asset, 0), nil
	}
	return assets, nil
}

// GetAsset returns one asset queried by asset Id if it exists
func (r *LocalizationRepository) GetAsset(assetId string) (asset Asset, err error) {
	row := r.DB.QueryRow(getAssetByIdSQL, assetId)

	if row == nil {
		return Asset{}, fmt.Errorf("something went wrong while retrieving assetId_%s, row is nil", assetId)
	}

	asset, err = scanToAsset(row.Scan)

	if err != nil {
		if err == sql.ErrNoRows {
			return Asset{}, fmt.Errorf(NoSuchAssetErrorMsg, assetId)
		}
		return Asset{}, err
	}

	return asset, nil
}

// DeleteAsset deletes asset record from assets table.
func (r *LocalizationRepository) DeleteAsset(assetId string) (err error) {
	res, err := r.DB.Exec(deleteAssetByIdSQL, assetId)
	if err != nil {
		log.Errorf("failed to delete %s asset data, err: %v", assetId, err)
		if err != nil {
			log.Errorf(rollbackAssetDataErrMsg, assetId, err)
		}
	}
	count, _ := res.RowsAffected()
	// if no rows has been deleted
	if count == 0 {
		return fmt.Errorf(NoSuchAssetErrorMsg, assetId)
	}
	return nil
}

// IsSupportedLocale checks if the provided locale is supported by the service
func (r *LocalizationRepository) IsSupportedLocale(localeId string) (bool, error) {

	var result bool

	row := r.DB.QueryRow(checkIfLocaleExistsSQL, localeId)

	if row == nil {
		return false, fmt.Errorf("something went wrong while retrieving localeId_%s, row is nil", localeId)
	}

	err := row.Scan(&result)

	if err != nil {
		return false, err
	}

	return result, nil
}

// GetTotalRows gets total rows
func (r *LocalizationRepository) GetTotalRows(query string, filters []interface{}) (int, error) {
	var count int
	var err error
	statementName := "total rows count statement"
	if filters == nil {
		stmt, err := r.DB.Prepare(query)
		if err != nil {
			return 0, fmt.Errorf("failed to prepare %s for %s, err: %v", statementName, query, err)
		}
		err = stmt.QueryRow().Scan(&count)
		stmt.Close()
	} else {
		err = r.DB.QueryRow(query, filters...).Scan(&count)
	}
	if err != nil {
		return 0, fmt.Errorf("failed to get/scan total rows into count var, err: %v", err)
	}
	return count, nil
}

type scanFunc func(...interface{}) error

func scanToAsset(scan scanFunc) (Asset, error) {

	var asset Asset
	var assetId sql.NullString
	var assetName sql.NullString
	var assetType sql.NullString
	var assetLocale sql.NullString
	var assetValue sql.NullString
	var assetReleased sql.NullBool
	var assetTags []string
	var assetCreated sql.NullString
	var assetUpdated sql.NullString

	err := scan(
		&assetId,
		&assetName,
		&assetType,
		&assetLocale,
		&assetReleased,
		&assetValue,
		pq.Array(&assetTags),
		&assetCreated,
		&assetUpdated,
	)
	if err != nil {
		return Asset{}, err
	}

	asset.Id = assetId.String
	asset.Name = assetName.String
	asset.Type = assetType.String
	asset.Locale = assetLocale.String
	asset.Released = assetReleased.Bool
	asset.Tags = assetTags
	asset.Value = assetValue.String

	tc, err := time.Parse(time.RFC3339, assetCreated.String)
	if err != nil {
		log.Errorf(conversionTimeErrMsg, err)
	}
	asset.Created = tc

	tu, err := time.Parse(time.RFC3339, assetUpdated.String)
	if err != nil {
		log.Errorf(conversionTimeErrMsg, err)
	}
	asset.Updated = tu

	return asset, nil
}
