package utils

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
)

type gwPingResp struct {
	Date time.Time `json:"date"`
	App  string    `json:"app"`
}

func TestHttpUtilDo(t *testing.T) {
	h := CreateHttpUtil("", _log, time.Second*5)
	doCheck(t, h)
	doCheck(t, h.WithLogs())
}

func doCheck(t *testing.T, h *HttpUtil) {
	var (
		pong = gwPingResp{}
		err  = h.Do("GET", "https://api-gw.meetflo.com/api/v2/ping", nil, nil, &pong)
	)
	assert.Nil(t, err, "Error is not nil: %v", err)
	assert.Greater(t, pong.Date.Year(), 2000, "Pong year is invalid: %v", pong.Date)
	assert.NotEmpty(t, pong.App, "Pong app is empty")
}

func TestHttpUtilDo_Error(t *testing.T) {
	h := CreateHttpUtil("", _log, time.Second*5)
	doCheckErr(t, h)
	doCheckErr(t, h.WithLogs())
}

func doCheckErr(t *testing.T, h *HttpUtil) {
	var (
		res = map[string]interface{}{}
		uri = "https://api-gw.meetflo.com/api/v2/accounts/" + uuid.New().String()
		err = h.Do("GET", uri, nil, nil, &res)
	)
	assert.NotNil(t, err, "Error is nil")
	assert.Equal(t, 0, len(res), "res obj not empty")
	assert.Contains(t, err.Error(), "access token")
	assert.Contains(t, err.Error(), "invalid")
	switch e := err.(type) {
	case *HttpErr:
		assert.Equal(t, 401, e.Code, "Error code %v is not 401", e.Code)
		assert.NotEmpty(t, e.Message, "error msg is empty")
		break
	default:
		assert.Fail(t, "Type should be *HttpErr but %v", e)
		break
	}
}
