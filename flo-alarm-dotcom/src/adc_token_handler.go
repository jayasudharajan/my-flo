package main

import (
	"github.com/gin-gonic/gin"
	"strings"
	"time"
)

type AdcTokenHandler interface {
	CliIdCheckMidWare(c *gin.Context)

	GetPubPEM(c *gin.Context)
	GetPubJWK(c *gin.Context)
	GetAdcReqToken(c *gin.Context)
	GetAdcPushToken(c *gin.Context)
}

func CreateAdcTokenHandler(svc ServiceLocator) AdcTokenHandler {
	return &atkHandler{svc}
}

type atkHandler struct {
	svc ServiceLocator
}

func (ah *atkHandler) CliIdCheckMidWare(c *gin.Context) {
	if cli := ah.clientId(c); cli == "" {
		var (
			sl   = ah.svc.Context(c)
			log  = sl.LocateName("Log").(Log)
			ws   = sl.SingletonName("WebServer").(WebServer)
			code = 404
		)
		log.PushScope("CliChkr")
		defer log.PopScope()

		if auth := c.Request.Header.Get(AUTH_HEADER); auth != "" {
			code = 403
		}
		ws.HttpError(c, code, "client_id required in JWT or query string", nil)
	} else {
		c.Next()
	}
}

func (ah *atkHandler) clientId(c *gin.Context) string {
	if objCli, found := c.Get("client_id"); !found || objCli == nil {
		cli := c.Request.URL.Query().Get("client_id")
		if cli == "" { //attempt to pull from JWT
			if auth := c.Request.Header.Get(AUTH_HEADER); auth != "" {
				if raw, e := JwtDecode(auth); e == nil && raw != nil && len(raw.Body) > 0 {
					if id, ok := raw.Body["client_body"]; ok && id != nil {
						if cli, ok = id.(string); !ok {
							return ""
						}
					}
				}
			}
		}
		if cli != "" {
			adc := ah.svc.Context(c).LocateName("AdcEnv").(AdcEnv)
			if cfg := adc.Get(cli); cfg != nil {
				c.Set("client_id", cli)
				return cli
			}
		}
	} else if cli, ok := objCli.(string); ok {
		return cli
	}
	return ""
}

func (ah *atkHandler) GetPubPEM(c *gin.Context) {
	var (
		sl    = ah.svc.Context(c)
		ws    = sl.SingletonName("WebServer").(WebServer)
		atk   = sl.LocateName("AdcTokenManager").(AdcTokenManager)
		o2Cli = ah.clientId(c)
	)
	if buf, e := atk.PublicRawPem(o2Cli); e != nil {
		ws.HttpThrow(c, e)
	} else if len(buf) == 0 {
		ws.HttpError(c, 501, "Not Implemented", nil)
	} else {
		c.Data(200, "text/plain", buf)
	}
}

func (ah *atkHandler) GetPubJWK(c *gin.Context) {
	var (
		sl    = ah.svc.Context(c)
		ws    = sl.SingletonName("WebServer").(WebServer)
		atk   = sl.LocateName("AdcTokenManager").(AdcTokenManager)
		o2Cli = ah.clientId(c)
	)
	if jwk, e := atk.PublicJWK(o2Cli); e != nil {
		ws.HttpThrow(c, e)
	} else if jwk == nil {
		ws.HttpError(c, 501, "Not Implemented", nil)
	} else {
		c.JSON(200, jwk)
	}
}

func (ah *atkHandler) GetAdcReqToken(c *gin.Context) {
	var (
		sl    = ah.svc.Context(c)
		ws    = sl.SingletonName("WebServer").(WebServer)
		atk   = sl.LocateName("AdcTokenManager").(AdcTokenManager)
		o2Cli = ah.clientId(c)
	)
	if res, e := atk.CustomToken(o2Cli); e != nil {
		ws.HttpThrow(c, e)
	} else if res == nil {
		ws.HttpError(c, 404, "Not Found", nil)
	} else {
		c.JSON(201, res)
	}
}

func (ah *atkHandler) GetAdcPushToken(c *gin.Context) {
	var (
		sl      = ah.svc.Context(c)
		ws      = sl.SingletonName("WebServer").(WebServer)
		atk     = sl.LocateName("AdcTokenManager").(AdcTokenManager)
		syncStr = c.Request.URL.Query().Get("sync")
		sync    = strings.EqualFold(syncStr, "true")
		o2Cli   = ah.clientId(c)
	)
	if res, e := atk.PushToken(o2Cli, sync); e != nil {
		ws.HttpThrow(c, e)
	} else if res == nil {
		ws.HttpError(c, 404, "Not Found", nil)
	} else {
		code := 200
		if sync || time.Since(res.IatDt()) <= time.Second*10 {
			code = 201
		}
		c.JSON(code, res)
	}
}
