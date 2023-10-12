package main

import (
	"fmt"
	"net/http/httptest"
	"strings"

	"github.com/labstack/echo/v4"
)

// EchoTesConfig is the echo configuration for testing purposes
type EchoTesConfig struct {
	Params     map[string]string
	Headers    map[string]string
	Path       string
	HttpMethod string
	Body       string
}

// MockContext mocks echo context
func MockContext(echoTestConfig EchoTesConfig) (*echo.Context, *httptest.ResponseRecorder) {

	responseRecorder := httptest.NewRecorder()

	e := echo.New()

	request := httptest.NewRequest(echoTestConfig.HttpMethod, fmt.Sprintf("/%s", APIVersion),
		strings.NewReader(echoTestConfig.Body))

	context := e.NewContext(request, responseRecorder)

	context.SetPath(echoTestConfig.Path)

	if echoTestConfig.Headers != nil {
		for k, v := range echoTestConfig.Headers {
			request.Header.Set(k, v)
		}
	}

	if echoTestConfig.Params != nil {
		var names []string
		var values []string
		for k, v := range echoTestConfig.Params {
			names = append(names, k)
			values = append(values, v)
		}
		context.SetParamNames(names...)
		context.SetParamValues(values...)
	}

	return &context, responseRecorder
}
