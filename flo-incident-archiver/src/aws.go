package main

import (
	"bytes"
	"fmt"
	"net/http"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/aws/aws-sdk-go/service/s3"
)

type IcdLog struct {
	DeviceId   string `dynamodbav:"icd_id"`
	MacAddress string `dynamodbav:"device_id"`
}

type S3Handler struct {
	Session *session.Session
	Bucket  string
}

type DynamoDbHandler struct {
	Session *session.Session
	Table   string
}

func CreateS3Session(region string, bucketName string) (*S3Handler, error) {
	sess := session.Must(session.NewSession(aws.NewConfig().
		WithMaxRetries(3).
		WithRegion(region)),
	)

	handler := S3Handler{
		Session: sess,
		Bucket:  bucketName,
	}

	return &handler, nil
}

func (h *S3Handler) UploadFile(key string, buffer []byte) error {

	_, err := s3.New(h.Session).PutObject(&s3.PutObjectInput{
		Bucket:               aws.String(h.Bucket),
		Key:                  aws.String(key),
		ACL:                  aws.String("private"),
		Body:                 bytes.NewReader(buffer),
		ContentLength:        aws.Int64(int64(len(buffer))),
		ContentType:          aws.String(http.DetectContentType(buffer)),
		ContentDisposition:   aws.String("attachment"),
		ServerSideEncryption: aws.String("AES256"),
	})

	return err
}

func CreateDynamoDbSession(region string, table string) (*DynamoDbHandler, error) {
	sess := session.Must(session.NewSession(aws.NewConfig().
		WithMaxRetries(3).
		WithRegion(region)),
	)

	handler := DynamoDbHandler{
		Session: sess,
		Table:   table,
	}

	return &handler, nil
}

func (h *DynamoDbHandler) QueryMacAddress(deviceId string) (string, error) {
	svc := dynamodb.New(h.Session)
	input := &dynamodb.QueryInput{
		ExpressionAttributeValues: map[string]*dynamodb.AttributeValue{
			":id": {
				S: aws.String(deviceId),
			},
		},
		KeyConditionExpression: aws.String("icd_id = :id"),
		TableName:              aws.String(h.Table),
	}
	result, err := svc.Query(input)
	if err != nil {
		return "", fmt.Errorf("aws: QueryMacAddress: error querying dynamodb - %v", err)
	}

	if *result.Count == 0 {
		return "", nil
	}

	var icdLogEntries []IcdLog
	err = dynamodbattribute.UnmarshalListOfMaps(result.Items, &icdLogEntries)

	if err != nil {
		return "", fmt.Errorf("aws: QueryMacAddress: error unmarshaling result - %v", err)
	}

	return icdLogEntries[0].MacAddress, nil
}
