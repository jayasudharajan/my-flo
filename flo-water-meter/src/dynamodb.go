package main

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/guregu/dynamo"
	"sync/atomic"
)

type dynamoDBSession struct {
	client *dynamo.DB
	prefix string
}

const (
	ENVVAR_DYNAMO_PREFIX = "DYNAMO_TABLE_PREFIX"
	ENVVAR_DYNAMO_REGION = "DYNAMO_REGION"
)

var (
	_dynamo     *dynamoDBSession
	_dynamoInit int32 = 0
)

func DynamoSingleton() (*dynamoDBSession, error) {
	var e error
	if atomic.CompareAndSwapInt32(&_dynamoInit, 0, 1) {
		_dynamo, e = createDynamoSession()
	}
	return _dynamo, e
}

func createDynamoSession() (*dynamoDBSession, error) {
	session, err := session.NewSession()
	if err != nil {
		logError("createDynamoSession: Open Attempt => %v", err.Error())
		return nil, err
	}
	prefix := getEnvOrDefault(ENVVAR_DYNAMO_PREFIX, "dev_")
	region := getEnvOrDefault(ENVVAR_DYNAMO_REGION, "us-west-2")
	return &dynamoDBSession{
		prefix: prefix,
		client: dynamo.New(session, &aws.Config{
			Region: aws.String(region),
			// LogLevel: aws.LogLevel(aws.LogDebugWithHTTPBody),
		}),
	}, nil
}

func (s dynamoDBSession) Ping() error {
	table := s.client.Table(s.getTableName(ARCHIVE_TABLE_NAME))
	_, err := table.Get(ARCHIVE_TABLE_HASH_FIELD, "XYZ").Count()
	return err
}

// GetByRange gets all documents in the specified table that match the range key values
func (s dynamoDBSession) GetByRange(table_name string, id_field string, id_value string, range_field string,
	range_from interface{}, range_to interface{}, out interface{}, projections ...string) error {

	table := s.client.Table(s.getTableName(table_name))
	query := table.Get(id_field, id_value).
		Range(range_field, dynamo.Between, range_from, range_to)
	if len(projections) > 0 {
		query = query.Project(projections...)
	}
	err := query.All(out)
	return err
}

// GetFirst gets the first document (minimum range value) that matches the hash key in the specified table
func (s dynamoDBSession) GetFirst(table_name string, id_field string, id_value string, out interface{}) error {

	table := s.client.Table(s.getTableName(table_name))
	err := table.Get(id_field, id_value).
		Limit(1).
		Order(true).
		One(out)
	return err
}

// BatchUpdate upserts a batch of documents into the specified table
func (s dynamoDBSession) BatchUpdate(table_name string, items ...interface{}) error {
	table := s.client.Table(s.getTableName(table_name))
	wrote, err := table.Batch().Write().Put(items...).Run()
	if wrote != len(items) {
		_log.Debug("BatchUpdate unexpected result size: %d ≠ %d", wrote, len(items))
	}
	return err
}

func (s dynamoDBSession) getTableName(table_name string) string {
	return s.prefix + table_name
}
