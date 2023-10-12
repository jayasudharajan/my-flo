package main

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gin-gonic/gin/binding"
)

type WebHandler interface {
	Ping() gin.HandlerFunc
	NewTask() gin.HandlerFunc
	CancelTask() gin.HandlerFunc
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

func (h *webHandler) Ping() gin.HandlerFunc {
	return func(c *gin.Context) {
		rv := map[string]interface{}{
			"date":   time.Now().UTC().Truncate(time.Second).Format(time.RFC3339),
			"app":    h.appInfo.appName,
			"status": "OK",
			"commit": getEnvOrDefault("CI_COMMIT_SHA", h.appInfo.commitSha),
			"branch": getEnvOrDefault("CI_COMMIT_BRANCH", h.appInfo.commitBranch),
			"host":   h.appInfo.hostName,
			"env":    getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local")),
			"debug":  h.log.isDebug,
			"uptime": time.Since(h.appInfo.appStart),
		}
		c.JSON(http.StatusOK, rv)
	}
}

func (h *webHandler) NewTask() gin.HandlerFunc {
	return func(c *gin.Context) {
		var taskDef TaskDefinition

		err := c.ShouldBindBodyWith(&taskDef, binding.JSON)
		if err != nil {
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"message": "Invalid task definition."})
			return
		}

		err = taskDef.Transport.Validate()
		if err != nil {
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"message": err.Error()})
			return
		}

		err = taskDef.Schedule.Validate()
		if err != nil {
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"message": err.Error()})
			return
		}

		body, _ := c.Get(gin.BodyBytesKey)
		h.log.Info("creating task %s - %s", taskDef.Id, string(body.([]byte)))
		err = h.services.scheduler.NewTask(&taskDef)
		if err != nil {
			if err == UniqueConstraintFailed {
				h.log.Info("task %s already exists", taskDef.Id)
				c.AbortWithStatusJSON(http.StatusConflict, gin.H{"message": fmt.Sprintf("Task %s already exists.", taskDef.Id)})
				return
			}
			h.log.Error("error creating task %s - %v", taskDef.Id, err)
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"message": "Something went wrong."})
			return
		}
		h.log.Info("created task with id %s", taskDef.Id)
		c.JSON(http.StatusAccepted, nil)
	}
}

func (h *webHandler) CancelTask() gin.HandlerFunc {
	return func(c *gin.Context) {
		taskId := c.Params.ByName("taskId")
		if taskId == "" {
			c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"message": "Task ID expected"})
			return
		}

		h.log.Info("canceling task with id %s", taskId)
		canceled, err := h.services.scheduler.CancelTask(taskId)
		if err != nil {
			h.log.Error("error canceling task %s - %v", taskId, err)
			c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{"message": "Something went wrong."})
			return
		}

		if !canceled {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{"message": fmt.Sprintf("Task %s does not exist.", taskId)})
			return
		}

		h.log.Info("canceled task with id %s", taskId)
		c.JSON(http.StatusNoContent, nil)
	}
}
