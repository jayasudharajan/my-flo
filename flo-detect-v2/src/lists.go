package main

import (
	"encoding/json"
	"net/http"
	"strings"
	"sync"
	"time"
)

const ENVVAR_LIST_LOCALE = "FLO_LIST_LOCALE"
const LIST_FLODETECT_PREDICTED = "flodetect_predicted"
const LIST_FLODETECT_FEEDBACK = "flodetect_predicted_feedback"

var _localeList []string
var _localeDefault string
var _lookupListMutex *sync.Mutex
var _listLookup map[string]ListItem

func init() {
	_lookupListMutex = new(sync.Mutex)
	localCsv := strings.TrimSpace(strings.ToLower(getEnvOrDefault(ENVVAR_LIST_LOCALE, "en")))
	_localeList = parseLangList(localCsv)
	if len(_localeList) == 0 {
		_localeList = []string{"en"}
	}
	_localeDefault = _localeList[0]
	if len(_localeDefault) == 0 {
		_localeDefault = "en"
	}
}

func startListsWorker() {
	// Load at start
	loadLists()

	// Run in background
	go func() {
		x := time.NewTicker(time.Minute)

		for {
			<-x.C
			loadLists()
		}
	}()
}

func loadLists() {
	lists := []string{
		LIST_FLODETECT_PREDICTED,
		LIST_FLODETECT_FEEDBACK,
	}

	delta := make(map[string]ListItem)

	for _, listItem := range lists {
		for _, loc := range _localeList {
			items, _ := getApiList(listItem, loc)
			if len(items) > 0 {
				for _, i := range items {
					delta[strings.ToLower(listItem+":"+i.Key+":"+i.Lang)] = i
				}
			}
		}
	}

	_lookupListMutex.Lock()
	_listLookup = delta
	_lookupListMutex.Unlock()

	logDebug("loadLists: loaded %v list items. lists = %v lang = %v", len(delta), lists, _localeList)
}

func getListValue(name string, key string, lang string) (string, bool) {
	if len(name) == 0 || len(key) == 0 {
		return "bad_name_key", false
	}

	if len(lang) < 2 {
		lang = _localeDefault
	}

	// Get current MAP reference
	_lookupListMutex.Lock()
	current := _listLookup
	_lookupListMutex.Unlock()

	// Exact match
	exact := strings.ToLower(name + ":" + key + ":" + lang)
	v := current[exact]
	if len(v.LongDisplay) > 0 {
		return v.LongDisplay, true
	}

	// Fallback to LANG only
	if len(lang) > 3 {
		langOnly := strings.Split(lang, "-")[0]
		exactLang := strings.ToLower(name + ":" + key + ":" + langOnly)
		v := current[exactLang]
		if len(v.LongDisplay) > 0 {
			return v.LongDisplay, true
		}
	}

	defLang := strings.ToLower(name + ":" + key + ":" + _localeDefault)
	v = current[defLang]
	if len(v.LongDisplay) > 0 {
		return v.LongDisplay, true
	}

	return "key-not-found-" + key, false
}

func getApiList(name string, lang string) ([]ListItem, error) {
	url := _apiUrl + "/api/v2/lists/" + name + "?lang=" + lang
	r, e := http.Get(url)
	if e != nil {
		logWarn("getApiList: unable to retrieve list. %v %v %v", name, lang, e.Error())
		return nil, e
	}

	rv := ListResponse{}
	e = json.NewDecoder(r.Body).Decode(&rv)
	if e != nil {
		logWarn("getApiList: unable to deserialize response. %v %v %v", name, lang, e.Error())
		return nil, e
	}

	logDebug("getApiList: %v item(s) for %v", len(rv.Items), url)
	return rv.Items, nil
}

type ListResponse struct {
	Items []ListItem `json:"items"`
}

type ListItem struct {
	Key          string                 `json:"key"`
	Lang         string                 `json:"lang"`
	ShortDisplay string                 `json:"shortDisplay"`
	LongDisplay  string                 `json:"longDisplay"`
	Data         map[string]interface{} `json:"data"`
}
