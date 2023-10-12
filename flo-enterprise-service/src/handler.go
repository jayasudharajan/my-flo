package main

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

type WebHandler interface {
	Ping() gin.HandlerFunc
	SyncDevice() gin.HandlerFunc
}

type webHandler struct {
	log      *Logger
	appInfo  *AppInfo
	services *Services
}

func CreateWebHandler(log *Logger, appInfo *AppInfo, services *Services) WebHandler {
	return &webHandler{
		log:      log.CloneAsChild("handler"),
		appInfo:  appInfo,
		services: services,
	}
}

func (h *webHandler) SyncDevice() gin.HandlerFunc {
	return func(c *gin.Context) {
		macAddress := c.Params.ByName("macAddress")
		if macAddress == "" {
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"message": "MacAddress expected"})
			return
		}
		h.log.Info("starting sync process for device with macAddress %s", macAddress)
		err := h.services.syncService.SyncDevice(c, macAddress, OptionalBool{HasValue: false})
		if err != nil {
			switch err.errorType {
			case INTERNAL_ERROR:
				c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"message": err.Error()})
				return
			case DEVICE_NOT_FOUND:
				c.AbortWithStatusJSON(http.StatusNotFound, gin.H{"message": err.Error()})
				return
			case DEVICE_IS_NOT_ENTERPRISE:
				c.JSON(http.StatusNoContent, nil)
				return
			case DEVICE_IS_NOT_SHUTOFF:
				c.JSON(http.StatusNoContent, nil)
				return
			}
		}
		h.log.Info("device %d was queued to be synced", macAddress)
		c.JSON(http.StatusAccepted, map[string]interface{}{
			"macAddress": macAddress,
		})
	}
}

func (h *webHandler) Ping() gin.HandlerFunc {
	return func(c *gin.Context) {
		rv := map[string]interface{}{
			"date":       time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
			"app":        h.appInfo.appName,
			"status":     "OK",
			"commit":     getEnvOrDefault("CI_COMMIT_SHA", h.appInfo.commitSha),
			"commitTime": getEnvOrDefault("CI_COMMIT_BRANCH", h.appInfo.commitTime),
			"host":       h.appInfo.hostName,
			"env":        getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local")),
			"debug":      h.log.isDebug,
			"uptime":     time.Since(h.appInfo.appStart),
		}
		c.JSON(http.StatusOK, rv)
	}
}
