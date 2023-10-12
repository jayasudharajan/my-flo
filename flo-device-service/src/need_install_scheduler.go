package main

import (
	"context"
	"time"

	"github.com/labstack/gommon/log"
	"github.com/robfig/cron/v3"
)

const ENVVAR_NEED_INSTALL_CRON_SCHEDULE = "FLO_NEED_INSTALL_CRON_SCHEDULE"

type NeedInstallScheduler struct {
	olsh    *OnboardingLogServiceHandler
	cronJob *cron.Cron
}

func CreateNeedInstallScheduler() *NeedInstallScheduler {
	s := NeedInstallScheduler{
		olsh: &Olsh,
	}
	return &s
}

func (sc *NeedInstallScheduler) initJob(ctx context.Context) {
	log.Info("Create new cron")
	c := cron.New()
	cronExp := getEnvOrDefault(ENVVAR_NEED_INSTALL_CRON_SCHEDULE, "*/5 * * * *")

	if cid, e := c.AddFunc(cronExp, func() { sc.olsh.UpdateNeedsInstallHandler(context.Background()) }); e != nil {
		log.Errorf("Open: bad cronExp %v=%v", e, ENVVAR_NEED_INSTALL_CRON_SCHEDULE, cronExp)
	} else {
		sc.cronJob = c
		log.Infof("Open: cronJob #%v | %v=%v", cid, ENVVAR_NEED_INSTALL_CRON_SCHEDULE, cronExp)
		sc.cronJob.Start()
		go func() {
			ctx := context.Background()
			time.Sleep(time.Second * 5) //fake trigger now
			sc.olsh.UpdateNeedsInstallHandler(ctx)
		}()
	}
}
