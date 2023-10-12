package main

import (
	"database/sql"
	"fmt"
	"sync"
	"time"

	"github.com/labstack/gommon/log"
)

var LocalesDS ConcurrentMap
var AssetsDS ConcurrentMap
var TypesDS ConcurrentMap

var repo LocalizationRepository

var quit chan int
var ticker *time.Ticker

func InitInMemoryDatastore(db *sql.DB, assetTagsMappings AssetTagsMappings) {
	quit = make(chan int)
	LocalesDS = ConcurrentMap{
		M: make(map[string]interface{}),
		L: sync.RWMutex{},
	}
	AssetsDS = ConcurrentMap{
		M: make(map[string]interface{}),
		L: sync.RWMutex{},
	}
	TypesDS = ConcurrentMap{
		M: make(map[string]interface{}),
		L: sync.RWMutex{},
	}

	repo = LocalizationRepository{
		DB:                db,
		AssetTagsMappings: assetTagsMappings,
	}

	// fetch data from Postgres on start
	go fetchDataFromRelationalDB()

	ticker = time.NewTicker(time.Duration(DbIngestionTimeInterval) * time.Second)

	go func() {
		for {
			select {
			case <-ticker.C:
				fetchDataFromRelationalDB()
			case <-quit:
				ticker.Stop()
				return
			}
		}
	}()
}

func fetchDataFromRelationalDB() {
	log.Debug("fetching assets, locales and type data into in-memory datastore")

	tempLocalesMap := make(map[string]interface{})
	tempAssetsMap := make(map[string]interface{})
	tempTypesMap := make(map[string]interface{})

	allLocales, err := repo.GetAllLocales()
	if err != nil {
		log.Errorf("failed to feed locales data into in-memory datastore, err: %v", err)
	}
	if allLocales != nil {
		for _, locale := range allLocales {
			tempLocalesMap[locale.Id] = locale
			log.Debugf("locale primary key is %s", locale.Id)
			log.Debugf("locale fallback is %s", locale.Fallback)
		}
		LocalesDS.L.Lock()
		LocalesDS.M = tempLocalesMap
		LocalesDS.L.Unlock()
	}

	allAssets, err := repo.GetAllAssets()
	if err != nil {
		log.Errorf("failed to feed assets data into in-memory datastore, err: %v", err)
	}
	if allAssets != nil {
		for _, asset := range allAssets {
			primaryKey := GetAssetPrimaryKey(asset.Name, asset.Type, asset.Locale)
			tempAssetsMap[primaryKey] = asset
			log.Debugf("asset primary key is %s", primaryKey)
			log.Debugf("asset id is %s", asset.Id)
		}
		AssetsDS.L.Lock()
		AssetsDS.M = tempAssetsMap
		AssetsDS.L.Unlock()
	}

	allTypes, err := repo.GetAllTypes()
	if err != nil {
		log.Errorf("failed to feed types data into in-memory datastore, err: %v", err)
	}
	if &allTypes != nil {
		typeItems := allTypes.Items
		if typeItems != nil {
			for _, aType := range typeItems {
				tempTypesMap[aType.Type] = aType
				log.Debugf("type primary key is %s", aType.Type)
			}
			TypesDS.L.Lock()
			TypesDS.M = tempTypesMap
			TypesDS.L.Unlock()
		}
	}

	// clear maps
	tempLocalesMap = nil
	tempAssetsMap = nil
	tempTypesMap = nil
}

// GetAssetPrimaryKey is the function to get the asset prime key
func GetAssetPrimaryKey(assetName string, assetType string, assetLocale string) string {
	return fmt.Sprintf("%s_%s_%s", assetName, assetType, assetLocale)
}
