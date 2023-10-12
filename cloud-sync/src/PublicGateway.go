package main

import (
	"context"
	"fmt"
)

type PublicGateway interface {
	GetLocationById(ctx context.Context, locationId string, requestId string) (*Location, error)
	GetDevice(ctx context.Context, did, mac string) (*Device, error)
}

type publicGateway struct {
	log     *Logger
	http    HttpUtil
	baseURL string
	auth    *StringPairs
}

type PublicGatewayConfig struct {
	log         *Logger
	http        HttpUtil
	baseURL     string
	floAPIToken string
}

func CreatePublicGateway(c *PublicGatewayConfig) PublicGateway {
	return &publicGateway{
		log:     c.log.CloneAsChild("PublicGateway"),
		http:    c.http,
		baseURL: c.baseURL,
		auth: &StringPairs{
			Name:  AUTH_HEADER,
			Value: c.floAPIToken,
		},
	}
}

func (pg *publicGateway) GetLocationById(ctx context.Context, locationId string, requestId string) (*Location, error) {
	if locationId == "" {
		return nil, &HttpErr{400, "locationId required", false, nil}
	}
	var (
		url          = fmt.Sprintf("%v/api/v2/locations/%v", pg.baseURL, locationId)
		locationResp = Location{}
		heads        = []StringPairs{*pg.auth}
	)
	if requestId != "" {
		heads = append(heads, StringPairs{Name: "x-request-id", Value: requestId})
	}
	if err := pg.http.Do(ctx, HTTP_GET, url, nil, nil, &locationResp, heads...); err != nil {
		return nil, pg.logErr(err, "GetLocationById: locId=%v reqId=%v", locationId, requestId)
	}
	return &locationResp, nil
}

func (pg *publicGateway) getDeviceUrl(did, mac string) string {
	path := _loggerSbPool.Get()
	defer _loggerSbPool.Put(path)

	path.WriteString(pg.baseURL)
	path.WriteString("/api/v2/devices")
	if did != "" {
		path.WriteString("/")
		path.WriteString(did)
	} else {
		path.WriteString("?macAddress=")
		path.WriteString(mac)
	}
	return path.String()
}

func (pg *publicGateway) GetDevice(ctx context.Context, did, mac string) (*Device, error) {
	if did == "" && mac == "" {
		return nil, &HttpErr{400, "did or mac required", false, nil}
	}
	var (
		dev = Device{}
		url = pg.getDeviceUrl(did, mac)
	)
	if e := pg.http.Do(ctx, HTTP_GET, url, nil, nil, &dev, *pg.auth); e != nil {
		return nil, pg.logErr(e, "GetDevice: %v %v", did, mac)
	}
	return &dev, nil
}

func (pg *publicGateway) logErr(e error, msg string, args ...interface{}) error {
	ll := LL_ERROR
	if he, ok := e.(*HttpErr); ok && he.Code < 500 {
		msg += " [http %v] "
		args = append(args, he.Code)
		ll = LL_WARN
		if he.Code == 400 || he.Code == 404 {
			ll = LL_NOTICE
		}
	}
	pg.log.Log(ll, msg+" | %v", append(args, e)...)
	return e
}
