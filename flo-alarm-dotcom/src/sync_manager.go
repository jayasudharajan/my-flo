package main

import (
	"fmt"
	"strings"
)

// SyncManager generate sync intent response and notification payload
type SyncManager interface {
	// Invoke method bridge IntentInvoker interface for automatic logic routing
	Invoke(ctx InvokeCtx) (interface{}, error)
	Discover(userId, authHead string) (*SyncPayload, error)
}

func CreateSyncManager(log Log, pubGw FloAPI) SyncManager {
	return &syncMan{log, pubGw}
}

type syncMan struct {
	log   Log
	pubGw FloAPI
}

// Invoke method bridge IntentInvoker interface for automatic logic routing
func (sm *syncMan) Invoke(ctx InvokeCtx) (interface{}, error) {
	sm.log = ctx.Log() //swap instance logger
	sm.log.PushScope("Invoke")
	defer sm.log.PopScope()

	res, e := sm.Discover(ctx.UserId(), ctx.AuthHeader())
	if e != nil { //custom err conversion to home graph domain exceptions
		switch er := e.(type) {
		case *HttpErr:
			switch er.Code {
			case 401:
				e = CreateHgError("relinkRequired", er)
			case 403:
				e = CreateHgError("securityRestriction", er)
			}
		}
	}
	return res, e
}

type SyncPayload struct {
	UserId  string      `json:"agentUserId"`
	Devices []*HgDevice `json:"devices"`
}

const (
	manufacturer  = "Moen"
	brand         = "Flo by Moen"
	swsTypePrefix = "flo_device_"
	swdTypePrefix = "puck_"
	swsName       = "Smart Water Shutoff"
	swdName       = "Smart Water Detector"
)

func (sm *syncMan) Discover(userId, authHead string) (*SyncPayload, error) {
	sm.log.PushScope("Disco", fmt.Sprintf("u=%v", userId))
	defer sm.log.PopScope()

	if locs, e := sm.pubGw.UserLocations(userId, authHead); e != nil {
		sm.log.IfErrorF(e, "pubGw.UserLocations(...) jwt=", JwtScrub(authHead))
		return nil, e
	} else {
		var (
			res = SyncPayload{UserId: userId}
			ids = make([]string, 0)
		)
		for _, loc := range locs { //check all locations
			if loc != nil && len(loc.Devices) > 0 {
				for _, fd := range loc.Devices { //flo device
					dms := CreateDeviceMappers(sm.ensureDeviceLoc(fd, loc), nil)
					if len(dms) == 0 {
						sm.log.Trace("deviceMapper.ToHgDevice: %v | IGNORED", fd.Id)
						continue
					}
					for _, dm := range dms {
						if hd, _ := sm.mapDevice(dm); hd != nil {
							res.Devices = append(res.Devices, hd)
							ids = append(ids, hd.Id)
						}
					}
				}
			}
		}
		sm.log.Info("OK -> devices %v", ids)
		return &res, nil
	}
}

func (sm *syncMan) mapDevice(dm DeviceMapper) (hd *HgDevice, er error) {
	if hd, er = dm.ToHgDevice(); hd != nil {
		sm.log.Trace("deviceMapper.ToHgDevice: OK %v", dm.Id())
	} else if er != nil {
		ll := IfLogLevel(strings.Contains(er.Error(), "not supported"), LL_INFO, LL_WARN)
		sm.log.Log(ll, "deviceMapper.ToHgDevice: %v | %v", dm.Id(), er)
	} else {
		sm.log.Trace("deviceMapper.ToHgDevice: %v | IGNORED", dm.Id())
	}
	return
}

func (sm *syncMan) ensureDeviceLoc(fd *Device, loc *Location) *Device {
	if fd.Location == nil {
		fd.Location = &Location{}
	}
	if fd.Location.Id == "" {
		fd.Location.Id = loc.Id
	}
	if fd.Location.Nickname == "" {
		fd.Location.Nickname = loc.Nickname
	}
	return fd
}
