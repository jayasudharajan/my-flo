package main

import (
	"context"
	"sync/atomic"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sqs"
)

const (
	SQS_MAX_MESSAGES int64 = 10
	SQS_TIMEOUT      int64 = 20
)

type SQSProcessor interface {
	ProcessMessage(ctx context.Context, m []byte)
}

type SQSReader struct {
	log       *Logger
	config    *SQSReaderConfig
	sqs       *sqs.SQS
	processor SQSProcessor
	queueURL  string
	isOpen    int32
}

type SQSReaderConfig struct {
	log          *Logger
	sqsQueueName string
	session      *session.Session
	processor    SQSProcessor
}

func CreateSQSReader(c *SQSReaderConfig) *SQSReader {
	svc := sqs.New(c.session)
	queueNameData, err := svc.GetQueueUrl(&sqs.GetQueueUrlInput{QueueName: aws.String(c.sqsQueueName)})
	if err != nil {
		logError("startSqsReader: unable to get queue url. %v %v", c.sqsQueueName, err.Error())
		signalExit()
	}

	if queueNameData == nil || queueNameData.QueueUrl == nil || len(queueNameData.String()) == 0 {
		logError("startSqsReader: queue url is nil/empty. %v", c.sqsQueueName)
		signalExit()
	}

	return &SQSReader{
		log:       c.log.CloneAsChild("SQSReader"),
		config:    c,
		processor: c.processor,
		sqs:       svc,
		queueURL:  *queueNameData.QueueUrl,
	}
}

func (r *SQSReader) pollSQS(ctx context.Context) error {
	r.log.Info("pollSQS: Started")
	for {
		if atomic.LoadInt32(&r.isOpen) != 1 {
			r.log.Warn("pollSQS: polling canceled")
			return nil
		}

		i := &sqs.ReceiveMessageInput{
			QueueUrl:            &r.queueURL,
			MaxNumberOfMessages: aws.Int64(SQS_MAX_MESSAGES),
			WaitTimeSeconds:     aws.Int64(SQS_TIMEOUT),
		}
		output, err := r.sqs.ReceiveMessageWithContext(ctx, i)
		if err != nil {
			r.log.Error("pollSQS: failed to fetch sqs messages. %v", err.Error())
			return err
		}

		for _, message := range output.Messages {
			if atomic.LoadInt32(&r.isOpen) != 1 {
				r.log.Warn("pollSQS: polling canceled while processing messages")
				return nil
			}
			if message.Body == nil {
				r.log.Warn("pollSQS: received empty message body from SQS")
			} else {
				m := []byte(*message.Body)
				r.processor.ProcessMessage(ctx, m)
				r.log.Trace("pollSQS: processed message %v", *message.MessageId)
			}

			d := sqs.DeleteMessageInput{
				QueueUrl:      aws.String(r.queueURL),
				ReceiptHandle: message.ReceiptHandle,
			}
			if _, err := r.sqs.DeleteMessageWithContext(ctx, &d); err != nil {
				r.log.Warn("pollSQS: error removing message %v %v", *message.MessageId, err.Error())
			} else {
				r.log.Trace("pollSQS: deleted message %v", *message.MessageId)
			}
		}
	}
}

func (r *SQSReader) Ping(ctx context.Context) error {
	var (
		req = sqs.GetQueueAttributesInput{
			AttributeNames: []*string{aws.String("All")},
			QueueUrl:       aws.String(r.queueURL),
		}
		_, e = r.sqs.GetQueueAttributesWithContext(ctx, &req)
	)
	r.log.IfErrorF(e, "sqsPing")
	return e
}

func (r *SQSReader) Open(ctx context.Context) {
	if atomic.CompareAndSwapInt32(&r.isOpen, 0, 1) {
		r.log.Debug("Open: SQSReader begin")
		err := RetryIfErrorLimitAttempts(ctx, r.pollSQS, time.Second*5, 3, r.log)
		if err != nil {
			r.log.Error("Open: error polling SQS - %v", err)
		}
	} else {
		r.log.Warn("Open: already opened")
	}
}

func (r *SQSReader) Close(ctx context.Context) {
	if atomic.CompareAndSwapInt32(&r.isOpen, 1, 0) {
		r.log.Debug("Close: SQSReader closed")
	} else {
		r.log.Warn("Close: SQSReader already closed")
	}
}
