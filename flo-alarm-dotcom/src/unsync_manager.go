package main

import (
	"fmt"
	"time"
)

// UnSyncManager ensure account is unlinked upon request
type UnSyncManager interface {
	// Invoke method bridge IntentInvoker interface for automatic logic routing
	Invoke(ctx InvokeCtx) (interface{}, error)
	Remove(userId, authHead string) error
}

func CreateUnSyncManager(log Log, pgw FloAPI, repo EntityStore) UnSyncManager {
	return &remMan{log, pgw, repo}
}

type remMan struct {
	log   Log
	pubGw FloAPI
	repo  EntityStore
}

func (rm *remMan) Invoke(ctx InvokeCtx) (res interface{}, err error) {
	if err = rm.Remove(ctx.UserId(), ctx.AuthHeader()); err == nil {
		res = map[string]interface{}{} //blank map
	}
	return
}

func (rm *remMan) Remove(userId, authHead string) (err error) {
	start := time.Now()
	rm.log.PushScope("Remove", fmt.Sprintf("u=%v", userId))
	defer rm.log.PopScope()

	var ok bool
	if err = rm.pubGw.LogoutFromToken(authHead); err != nil {
		rm.log.IfErrorF(err, "LogoutFromToken: %v", CleanToken(authHead))
	} else if ok, err = rm.repo.Delete(userId); err != nil {
		rm.log.IfErrorF(err, "repo.Delete")
	} else {
		rm.log.Info("%v. Took=%v", IfTrue(ok, "OK", "NO_RM"), time.Since(start))
	}
	return
}
