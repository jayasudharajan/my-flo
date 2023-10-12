package main

import (
	"context"
	"encoding/json"
)

type pubGwRequestDispatcher struct {
	url             string
	method          string
	authHeader      *StringPairs
	requestIDHeader *StringPairs
	requestBody     *json.RawMessage
	http            HttpUtil
	log             *Logger
}

func (d pubGwRequestDispatcher) Dispatch(ctx context.Context) (json.RawMessage, error) {
	var (
		response = json.RawMessage{}
		body     = make([]byte, 0)
	)
	if d.requestBody != nil {
		body = *d.requestBody
	}
	if err := d.http.Do(ctx, d.method, d.url, body, nil, &response, *d.authHeader, *d.requestIDHeader); err != nil {
		d.log.Error("makeRequest: error %v", err.Error())
		return nil, err
	}
	return response, nil
}

type PublicGatewayDispatcherConfig struct {
	method      string
	url         string
	requestBody *json.RawMessage
	requestID   string
}

type PublicGatewayDispatcherFactory struct {
	log        *Logger
	http       HttpUtil
	authHeader *StringPairs
}
type PublicGatewayDispatcherFactoryConfig struct {
	log       *Logger
	authToken string
	http      HttpUtil
}

func CreatePublicGatewayDispatcherFactory(c *PublicGatewayDispatcherFactoryConfig) *PublicGatewayDispatcherFactory {
	return &PublicGatewayDispatcherFactory{
		log:  c.log.CloneAsChild("PublicGatewayDispatcherFactory"),
		http: c.http,
		authHeader: &StringPairs{
			Name:  AUTH_HEADER,
			Value: c.authToken,
		},
	}
}

func (f *PublicGatewayDispatcherFactory) New(c *PublicGatewayDispatcherConfig) Dispatcher {
	return &pubGwRequestDispatcher{
		log:        f.log.CloneAsChild("PubGwDispatcher"),
		http:       f.http,
		authHeader: f.authHeader,
		requestIDHeader: &StringPairs{
			Name:  "x-request-id",
			Value: c.requestID,
		},
		requestBody: c.requestBody,
		url:         c.url,
		method:      c.method,
	}
}
