package main

import (
	"bytes"
	"errors"
	"io"
	"net/http"

	"github.com/aws/aws-sdk-go/service/s3/s3manager"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
)

const S3_REGION = "us-west-2"

type S3Handler struct {
	Session    *session.Session
	Downloader *s3manager.Downloader
	Bucket     string
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

func (h *S3Handler) DownloadStream(destination io.WriterAt, bucket string, key string) (int64, error) {
	if destination == nil {
		return 0, errors.New("destination nil")
	}
	if len(bucket) == 0 {
		return 0, errors.New("bucket empty")
	}
	if len(key) == 0 {
		return 0, errors.New("key empty")
	}

	return h.Downloader.Download(destination,
		&s3.GetObjectInput{
			Bucket: aws.String(bucket),
			Key:    aws.String(key),
		})
}
