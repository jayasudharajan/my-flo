package main

import (
	"github.com/gin-gonic/gin"
	"strings"
	"time"
)

type EntityHandler interface {
	UsrIdChkMidWare(c *gin.Context)

	GetUser(c *gin.Context)
	DeleteUser(c *gin.Context)
	SyncInviteUser(c *gin.Context)
	UpdateUserDevices(c *gin.Context)
}

func CreateEntityHandler(svc ServiceLocator) EntityHandler {
	return &entHandler{svc}
}

type entHandler struct {
	svc ServiceLocator
}

func (eh *entHandler) UsrIdChkMidWare(c *gin.Context) {
	if _, e := eh.userIdFromPath(c); e != nil {
		ws := eh.svc.Context(c).SingletonName("WebServer").(WebServer)
		ws.HttpThrow(c, e)
	} else {
		c.Next()
	}
}

func (eh *entHandler) userIdFromPath(c *gin.Context) (string, error) {
	userId := c.Params.ByName("userId")
	if len(userId) != 36 || strings.Count(userId, "-") != 4 {
		return "", &HttpErr{400, "Bad Request: invalid userId", nil}
	} else {
		return userId, nil
	}
}

type lnkUsrResp struct {
	UserId   string          `json:"flo_user_id"`
	ClientId string          `json:"flo_client_id"`
	Updated  time.Time       `json:"updated,omitempty"`
	Created  time.Time       `json:"created,omitempty"`
	Devices  []*LinkedDevice `json:"devices,omitempty"`
}

func (eh *entHandler) GetUser(c *gin.Context) {
	var (
		sl      = eh.svc.Context(c)
		ws      = sl.SingletonName("WebServer").(WebServer)
		entRep  = sl.LocateName("EntityStore").(EntityStore)
		devRep  = sl.LocateName("DeviceStore").(DeviceStore)
		userId  = c.Params.ByName("userId")
		sync    = strings.EqualFold(c.Request.URL.Query().Get("sync"), "true")
		devices []*LinkedDevice
	)
	if u, e := entRep.Get(userId, sync); e != nil {
		ws.HttpThrow(c, e)
	} else if devices, e = devRep.GetByUserId(userId, sync); e != nil {
		ws.HttpThrow(c, e)
	} else {
		c.JSON(200, &lnkUsrResp{
			UserId:   u.UserId,
			ClientId: u.ClientId,
			Updated:  u.Updated,
			Created:  u.Created,
			Devices:  devices,
		})
	}
}

func (eh *entHandler) DeleteUser(c *gin.Context) {
	var (
		sl     = eh.svc.Context(c)
		repo   = sl.LocateName("EntityStore").(EntityStore)
		userId = c.Params.ByName("userId")
	)
	if ok, e := repo.Delete(userId); e != nil {
		ws := sl.SingletonName("WebServer").(WebServer)
		ws.HttpThrow(c, e)
	} else if ok {
		c.JSON(200, nil)
	} else {
		c.JSON(404, &HttpErr{404, "Not found", nil})
	}
}

func (eh *entHandler) SyncInviteUser(c *gin.Context) {
	var (
		sl     = eh.svc.Context(c)
		ws     = sl.SingletonName("WebServer").(WebServer)
		repo   = sl.LocateName("EntityStore").(EntityStore)
		man    = sl.LocateName("EntityNotifyManager").(EntityNotifyManager)
		userId = c.Params.ByName("userId")
	)
	if usr, e := repo.Get(userId, false); e != nil {
		ws.HttpThrow(c, e)
	} else if usr != nil {
		if e = man.SyncInvite(usr); e != nil {
			ws.HttpThrow(c, e)
		} else {
			c.JSON(202, nil)
		}
	} else {
		c.JSON(404, &HttpErr{404, "User Not found", nil})
	}
}

func (eh *entHandler) UpdateUserDevices(c *gin.Context) {
	var (
		sl     = eh.svc.Context(c)
		ws     = sl.SingletonName("WebServer").(WebServer)
		repo   = sl.LocateName("DeviceStore").(DeviceStore)
		notify = sl.LocateName("StatNotifyManager").(StatNotifyManager)
		userId = c.Params.ByName("userId")
	)
	if devs, e := repo.GetByUserId(userId, false); e != nil {
		ws.HttpThrow(c, e)
	} else if len(devs) != 0 {
		errs := make([]error, 0)
		for _, device := range devs {
			if er := notify.ReportState(device.Mac); er != nil {
				errs = append(errs, er)
			}
		}
		if e = wrapErrors(errs); e != nil {
			ws.HttpThrow(c, e)
		} else {
			c.JSON(200, devs)
		}
	} else {
		c.JSON(404, &HttpErr{404, "Devices Not found", nil})
	}
}
