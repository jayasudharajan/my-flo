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

type archiveCmd struct {
}

func (*archiveCmd) Name() string { return "archive" }
func (*archiveCmd) Synopsis() string {
	return "moves the hourly data from pgsql to its archive location."
}
func (*archiveCmd) Usage() string {
	return `archive`
}

func (p *archiveCmd) SetFlags(f *flag.FlagSet) {
}

func (p *archiveCmd) Execute(_ context.Context, f *flag.FlagSet, _ ...interface{}) subcommands.ExitStatus {

	p.archive()
	return subcommands.ExitSuccess
}

func (p *archiveCmd) archive() error {

	logNotice("Archive task starting")

	reader := DefaultWaterReader().MustOpen()
	writer := CreateArchiveWaterWriter()
	err := writer.Open()
	if err != nil {
		logError("archive failed, %v", err)
		return err
	}

	task := NewArchiveTsdTask(reader, writer, func(key string, ttl time.Duration) (bool, error) {
		return true, nil
	})

	inst, err := task.Spawn()
	if err != nil {
		logError("archive failed, %v", err)
		return err
	}
	inst.Open()

	c := make(chan os.Signal, 1)
	signal.Notify(c, os.Interrupt, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGKILL)

	<-c
	inst.Close()
	return nil
}
