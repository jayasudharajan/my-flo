package main

import (
	"bytes"
	"net/http"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

const S3_REGION = "us-west-2"

type S3Handler struct {
	Session *session.Session
	Bucket  string
}

func InitAwsS3(bucketName string) (*S3Handler, error) {
	sess, err := session.NewSession(&aws.Config{Region: aws.String(S3_REGION)})
	if err != nil {
		return nil, err
	}

	handler := S3Handler{
		Session: sess,
		Bucket:  bucketName,
	}

	return &handler, nil

}

func (h *S3Handler) UploadFile(bucketName string, key string, buffer []byte) error {

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
