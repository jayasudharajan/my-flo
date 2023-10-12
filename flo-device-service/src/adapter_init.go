package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/hashicorp/go-retryablehttp"
	instana "github.com/instana/go-sensor"
	"github.com/labstack/gommon/log"
)

type ClientCredential struct {
	ClientId     string `json:"client_id"`
	ClientSecret string `json:"client_secret"`
	GrantType    string `json:"grant_type"`
}

var token = EmptyString

var httpClient *retryablehttp.Client

func InitializeFloHttpClient() (err error) {
	ctx := context.Background()

	httpClient = retryablehttp.NewClient()
	httpClient.RetryWaitMin = time.Duration(HttpRetryWaitMin) * time.Millisecond
	httpClient.RetryWaitMax = time.Duration(HttpRetryWaitMax) * time.Millisecond
	httpClient.RetryMax = HttpMaxRetryNum
	httpClient.Backoff = retryablehttp.LinearJitterBackoff
	httpClient.HTTPClient.Transport = PanicWrapRoundTripper("AdapterHttpClient", instana.RoundTripper(_instana, httpClient.HTTPClient.Transport))

	accessToken, err := getApiAccessToken(ctx)
	if err != nil {
		log.Errorf("failed to get api access token, err: %v", err)
	}
	token = fmt.Sprintf("Bearer %s", accessToken)
	log.Debugf("initialized with auth token: %s", token)
	return nil
}

func getApiAccessToken(ctx context.Context) (string, error) {
	var accessToken map[string]interface{}
	relativeAuthPath := "/api/v1/oauth2/token"
	accessTokenKey := "access_token"
	body := ClientCredential{
		ClientId:     HttpClientId,
		ClientSecret: HttpClientSecret,
		GrantType:    "client_credentials",
	}
	bodyJson, err := json.Marshal(body)
	if err != nil {
		return EmptyString, err
	}
	resp, err := makeHttpRequest(ctx, http.MethodPost, relativeAuthPath, string(bodyJson), nil)
	if err != nil {
		return EmptyString, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return EmptyString, fmt.Errorf("unsuccessful request to %s, status code %d", relativeAuthPath, resp.StatusCode)
	}

	jsonT, err := io.ReadAll(resp.Body)
	if err != nil {
		return EmptyString, err
	}
	if err = json.Unmarshal(jsonT, &accessToken); err != nil {
		return EmptyString, err
	}
	token := EmptyString
	tokenI := accessToken[accessTokenKey]
	if tokenI != nil {
		token = tokenI.(string)
	} else {
		return EmptyString, fmt.Errorf("missing %s in response from %s call", accessTokenKey, relativeAuthPath)
	}
	return token, nil
}
