package main

import (
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sns"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"
)

type SnsHandler struct {
	session *session.Session
	sns     *sns.SNS
}

type SnsClient interface {
	Publish(topic string, message string) error
	Ping(topic string) error
}

func CreateSnsClient(region string, maxRetries int) (SnsClient, error) {
	cfg := aws.NewConfig().WithRegion(region)
	if maxRetries > 0 {
		cfg = cfg.WithMaxRetries(maxRetries)
	}
	sess, err := session.NewSession(cfg)
	if err != nil {
		return nil, err
	}
	tracing.WrapInstaawssdk(sess, tracing.Instana)

	sns := sns.New(sess)
	return &SnsHandler{sess, sns}, nil
}

func (s *SnsHandler) Publish(topic string, message string) error {
	_, err := s.sns.Publish(&sns.PublishInput{
		TopicArn: &topic,
		Message:  &message,
	})
	return err
}

func (s *SnsHandler) Ping(topic string) error {
	input := sns.GetTopicAttributesInput{TopicArn: &topic}
	if _, e := s.sns.GetTopicAttributes(&input); e != nil {
		return e
	} else {
		return nil
	}
}
