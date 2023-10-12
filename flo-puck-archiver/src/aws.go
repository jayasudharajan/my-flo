package main

import (
	"bytes"
	"net/http"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

type S3Handler struct {
	Session *session.Session
	Bucket  string
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
