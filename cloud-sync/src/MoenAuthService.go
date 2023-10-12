package main

import (
	"context"
	"fmt"
	"strings"
)

type MoenAuthService interface {
	GetFloUserId(ctx context.Context, moenFederatedId string) (string, error)
	GetSyncByFloUserId(ctx context.Context, floId string) (string, error)
	GetLinkedLocation(ctx context.Context, floId string) (*SyncLoc, error)
}

type moenAuthService struct {
	log     *Logger
	http    HttpUtil
	baseURL string
}

type MoenAuthServiceConfig struct {
	log         *Logger
	http        HttpUtil
	moenAuthUrl string
}

func CreateMoenAuthService(c *MoenAuthServiceConfig) MoenAuthService {
	return &moenAuthService{
		log:     c.log.CloneAsChild("MoenAuthService"),
		http:    c.http,
		baseURL: c.moenAuthUrl,
	}
}

type SyncUser struct {
	FloId     string `json:"floId,omitempty"`
	FloAccId  string `json:"floAccountId,omitempty"`
	MoenId    string `json:"moenId,omitempty"`
	MoenAccId string `json:"moenAccountId,omitempty"`
}

func (u SyncUser) String() string {
	return tryToJson(u)
}

func (mas *moenAuthService) GetFloUserId(ctx context.Context, moenFederatedId string) (string, error) {
	userResp := SyncUser{}
	err := mas.http.Do(ctx, HTTP_GET, mas.baseURL+"/sync/id?moenId="+moenFederatedId, nil, nil, &userResp)
	if err != nil {
		return "", err
	}
	return userResp.FloId, nil
}

func (mas *moenAuthService) GetSyncByFloUserId(ctx context.Context, floId string) (string, error) {
	userResp := SyncUser{}
	err := mas.http.Do(ctx, HTTP_GET, mas.baseURL+"/sync/id?floId="+floId, nil, nil, &userResp)
	if err != nil {
		return "", err
	}
	return userResp.MoenId, nil
}

func (mas *moenAuthService) GetLinkedLocation(ctx context.Context, floId string) (*SyncLoc, error) {
	if floId == "" {
		return nil, nil
	}
	var (
		url  = fmt.Sprintf("%v//sync/locations?floId=%v", mas.baseURL, floId)
		resp = locMapResp{}
	)
	if e := mas.http.Do(ctx, HTTP_GET, url, nil, nil, &resp); e != nil {
		return nil, e
	} else if len(resp.Items) != 0 {
		if loc := resp.Items[0]; loc != nil && strings.EqualFold(loc.FloId, floId) {
			return loc, nil
		}
	}
	return nil, nil
}

type locMapResp struct {
	//Match   *getLocMatch `json:"match,omitempty"`
	//Page    *skipLimPage `json:"page,omitempty"`
	Items []*SyncLoc `json:"items"`
	//Message string       `json:"message,omitempty"`
}
type SyncLoc struct {
	FloId    string `json:"floId" validate:"uuid4_rfc4122"`
	FloAccId string `json:"floAccountId" validate:"uuid4_rfc4122"`
	MoenId   string `json:"moenId" validate:"uuid4_rfc4122"`
}

func (sl SyncLoc) String() string {
	k := fmt.Sprintf("f:%v,fA:%v,m:%v", sl.FloId, sl.FloAccId, sl.MoenId)
	return strings.ReplaceAll(k, "-", "") //shorter keys to save redis RAM
}
