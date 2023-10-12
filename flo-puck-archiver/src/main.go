package main

import (
	"context"
	"flag"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/google/subcommands"
)

var _commitSha string
var _commitTime string
var _hostName string
var _start time.Time

func main() {

	_log.Info("main: Starting...")

	_start = time.Now()
	_hostName = getHostname()

	args := os.Args[1:]
	if len(args) > 0 {
		subcommands.Register(subcommands.HelpCommand(), "")
		subcommands.Register(subcommands.CommandsCommand(), "")
		subcommands.Register(&testCmd{_log}, "")

		flag.Parse()
		ctx := context.Background()
		os.Exit(int(subcommands.Execute(ctx)))
	}

	archiver := ArchiverFactoryInstance().createArchiver()
	archiver.Open()

	go archiver.Run()
	go waitForSignal(archiver)

	_log.Info("main: Started")

	for archiver.IsOpen() {
		time.Sleep(time.Second)
	}

	_log.Info("main: Stopped")

	os.Exit(0)
}

func waitForSignal(a *archiver) {
	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM, syscall.SIGINT)

	sig, ok := <-c
	if ok {
		_log.Info("caught %v", sig)
	}
	a.Close()
}
