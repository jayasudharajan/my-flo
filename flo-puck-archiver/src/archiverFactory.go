package main

import (
	"os"
	"strconv"
	"sync"
)

type archiverFactory struct {
	logger *Logger
}

var _factoryOnce sync.Once
var _factoryInstance *archiverFactory

func ArchiverFactoryInstance() *archiverFactory {
	_factoryOnce.Do(func() {
		_factoryInstance = &archiverFactory{logger: _log}
	})
	return _factoryInstance
}

func (f archiverFactory) createArchiver() *archiver {
	log := f.logger.CloneAsChild("createArchiver")
	log.Info("creating S3 session")
	s3 := f.initS3()
	log.Info("successfully created S3 session: %v", s3.Bucket)

	log.Info("creating pgsql sessions")
	pg, readpg := f.initPgSql(envVarPgConnectionString, envVarPgReadConnectionString)
	log.Info("successfully created pgsql sessions")

	a := newArchiver(f.logger, s3, pg, readpg)

	if c, err := strconv.Atoi(getEnvOrDefault(envVarArchiveRecordsOlderThan, "")); err == nil && c > 0 {
		a.archiveCutoffDays = c
	}

	if l, err := strconv.Atoi(getEnvOrDefault(envVarArchiveMaxLimit, "")); err == nil && l > 0 {
		a.archiveDaysLimit = l
	}

	return a
}

func (f archiverFactory) initS3() *S3Handler {
	s3, err := CreateS3Session(getEnvOrDefault(envVarAwsRegion, defaultAwsRegion),
		getEnvOrExit(envVarS3Bucket))
	if err != nil {
		f.logger.Fatal("error creating s3 session - %v", err)
		os.Exit(3)
	}
	return s3
}

func (f archiverFactory) initPgSql(mainEnvVar, readEnvVar string) (*PgSqlDb, *PgSqlDb) {
	mainCn := getEnvOrExit(mainEnvVar)
	pgSql, err := OpenPgSqlDb(mainCn)
	if err != nil {
		f.logger.Fatal("error connecting to pg - %v", err)
		os.Exit(2)
	}
	readCn := getEnvOrDefault(readEnvVar, mainCn)
	if readCn == mainCn {
		return pgSql, pgSql
	}

	readPgSql, err := OpenPgSqlDb(readCn)
	if err != nil {
		f.logger.Fatal("error connecting to read pg - %v", err)
		os.Exit(2)
	}
	return pgSql, readPgSql
}
