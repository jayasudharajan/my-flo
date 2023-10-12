package main

import (
	"context"
	"flag"

	"github.com/google/subcommands"
)

type testCmd struct {
	logger *Logger
}

func (*testCmd) Name() string { return "test" }
func (*testCmd) Synopsis() string {
	return "test dependencies and permissions"
}
func (*testCmd) Usage() string {
	return `test`
}

func (p *testCmd) SetFlags(f *flag.FlagSet) {
}

func (p *testCmd) Execute(_ context.Context, f *flag.FlagSet, _ ...interface{}) subcommands.ExitStatus {

	p.run()
	return subcommands.ExitSuccess
}

func (p *testCmd) run() {
	log := p.logger.CloneAsChild("TestCMD")

	log.Notice("starting")
	failed := false

	archiver := ArchiverFactoryInstance().createArchiver()

	s3 := archiver.s3
	if err := s3.UploadFile("cli-test-file", []byte("hello world")); err != nil {
		p.logger.Error("s3 error: %v\n", err)
		failed = true
	}
	log.Notice("done, success = %v", !failed)
}
