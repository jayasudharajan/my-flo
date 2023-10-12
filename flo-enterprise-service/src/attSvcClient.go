package main

import (
	"context"
	"enterprise-service/excel"
	"fmt"
	"net/url"
)

type AttSvcClient struct {
	uri        *url.URL
	authKey    string
	httpClient *httpUtil
	logger     *Logger
}

type AttSvcBulkUploadRow struct {
	EndConsumerId             string
	EndConsumerFullName       string
	EndConsumerEmail          string
	EndConsumerPhone          string
	EndConsumerBillingAddress string
	EndConsumerBillingCity    string
	EndConsumerBillingState   string
}

const (
	ENVVAR_ATT_API_URL = "ATT_API_URL"
	ENVVAR_ATT_API_KEY = "ATT_API_KEY"
)

func CreateATTClient(httpClient *httpUtil, logger *Logger) (*AttSvcClient, error) {
	childLogger := logger.CloneAsChild("attSvcClient")
	baseUri, e := url.Parse(getEnvOrExit(ENVVAR_ATT_API_URL))
	if e != nil {
		return nil, childLogger.Fatal("invalid %v (%v)", ENVVAR_ATT_API_URL, baseUri)
	}

	key := getEnvOrDefault(ENVVAR_ATT_API_KEY, "")
	if len(key) < 1 {
		childLogger.Warn("empty variable %v", ENVVAR_ATT_API_KEY)
	}

	return &AttSvcClient{
		uri:        baseUri,
		authKey:    key,
		httpClient: httpClient,
		logger:     childLogger,
	}, nil
}

func (c *AttSvcClient) BulkDeviceUpload(ctx context.Context, fileName string, data map[string]AttSvcBulkUploadRow) (err error) {
	auth := StringPairs{
		Name:  AUTH_HEADER,
		Value: c.authKey,
	}
	wb := excel.CreateWb()

	sheetData := make([][]string, 0)
	sheetData = append(sheetData, []string{"ICCID", "End Consumer ID", "End Consumer Name", "Contact Email", "Contact Phone",
		"Billing Address Line 1", "Billing Address City", "Billing Address State/Region"})
	for iccid, row := range data {
		sheetData = append(sheetData, []string{iccid, row.EndConsumerId, row.EndConsumerFullName, row.EndConsumerEmail, row.EndConsumerPhone,
			row.EndConsumerBillingAddress, row.EndConsumerBillingCity, row.EndConsumerBillingState})
	}
	excel.AddSheet(wb, "Devices", sheetData)
	reader := excel.ToReader(wb)

	err = c.httpClient.Upload(ctx, fmt.Sprintf("%s/%s", c.uri, "/provision/api/v1/batchupdates/files/upload"), "uploadFile", fmt.Sprintf("%v.xlsx", fileName), reader, auth)
	return
}
