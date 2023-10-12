package main

import (
	"github.com/labstack/gommon/log"
	"regexp"
)

// AssetIdRegex is the localized asset id regex
var AssetIdRegex *regexp.Regexp

// CompileLocalizationServiceRegexes compiles localization service regexes
func CompileLocalizationServiceRegexes() {
	var err error
	AssetIdRegex, err = regexp.Compile("^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[8|9|a|b][a-f0-9]{3}-[a-f0-9]{12}$")
	if err != nil {
		log.Errorf("failed to compile localization service locale id regex, err: %v", err)
	}
}
