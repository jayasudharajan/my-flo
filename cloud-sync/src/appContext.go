package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"
)

//current console app info obj to work with service locator
type appContext struct {
	log        *Logger
	CodeHash   string
	CodeTime   string
	CodeBranch string
	Host       string
	App        string
	Env        string
	Start      time.Time
	interrupt  chan os.Signal
}

func CreateAppContext(log *Logger, codeHash, codeTime, codeBranch string) *appContext {
	a := appContext{
		log:        log.Clone().SetName("appCtx"),
		Start:      time.Now(),
		App:        getEnvOrDefault("APPLICATION_NAME", "flo-moen-auth"),
		Env:        getEnvOrDefault("ENV", getEnvOrDefault("ENVIRONMENT", "local")),
		interrupt:  make(chan os.Signal, 1),
		CodeTime:   codeTime,
		CodeHash:   codeHash,
		CodeBranch: codeBranch,
	}
	if a.CodeHash == "" {
		a.CodeHash = "Unknown"
	}
	if a.CodeBranch == "" {
		a.CodeBranch = "NoBranch"
	}
	a.log.Debug("CreateAppContext: %v code: %v", a.App, a.CodeHash)
	return &a
}

func (a *appContext) SetHost() *appContext {
	a.Host = getHostname()
	a.log.Debug("Host: %v", a.Host)
	return a
}

func (a *appContext) ForceExit() {
	a.log.Debug("ForceExit")
	a.interrupt <- syscall.SIGABRT
}

func (a *appContext) Exit(sig os.Signal) {
	close(a.interrupt)
	a.log.Warn("Exit %v. Uptime was %v", sig, time.Since(a.Start))
	if sig == syscall.SIGABRT {
		os.Exit(-11)
	} else {
		os.Exit(0)
	}
}

func (a *appContext) WaitForSignal() (os.Signal, bool) {
	a.log.Info("WaitForSignal: enter")
	signal.Notify(a.interrupt, os.Interrupt, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL, syscall.SIGABRT)
	sig, ok := <-a.interrupt
	fmt.Println()

	defer a.log.Notice("WaitForSignal: exit %v", sig)
	return sig, ok
}
