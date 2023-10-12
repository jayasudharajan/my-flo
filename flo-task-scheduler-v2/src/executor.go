package main

import (
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"strings"
	"sync/atomic"
	"time"

	"github.com/confluentinc/confluent-kafka-go/kafka"
	"github.com/pkg/errors"
)

type Executor interface {
	Open()
	Close()
}

type ExecutorKafkaConfig struct {
	kafkaConnection *KafkaConnection
	groupId         string
	topic           string
}

type executor struct {
	log               *Logger
	kafkaConfig       *ExecutorKafkaConfig
	kafkaSubscription *KafkaSubscription
	taskRepository    TaskRepository
	httpClient        *http.Client
	isOpen            int32
}

func CreateTaskExecutor(log *Logger, kafkaConfig *ExecutorKafkaConfig, taskRepository TaskRepository, httpClient *http.Client) Executor {
	return &executor{
		log:            log.CloneAsChild("executor"),
		kafkaConfig:    kafkaConfig,
		taskRepository: taskRepository,
		httpClient:     httpClient,
	}
}

func (e *executor) Open() {
	if atomic.CompareAndSwapInt32(&e.isOpen, 0, 1) {
		e.log.Debug("Open: begin")
		err := retryIfError(e.subscribe, time.Second*5, 3, e.log)
		if err != nil {
			e.log.Error("Open: error subscribing to kafka topic - %v", err)
		}
	} else {
		e.log.Warn("Open: already opened")
	}
}

func (e *executor) Close() {
	if atomic.CompareAndSwapInt32(&e.isOpen, 1, 0) {
		e.log.Debug("Close: begin")
		if e.kafkaSubscription != nil {
			e.kafkaSubscription.Close()
			e.kafkaSubscription = nil
		}
		e.log.Info("Close: OK")
	} else {
		e.log.Warn("Close: already closed")
	}
}

func (e *executor) subscribe() error {
	defer panicRecover(e.log, "subscribe: %p", e)

	if atomic.LoadInt32(&e.isOpen) != 1 {
		return errors.New("subscribe: not opened")
	}

	subscription, err := e.kafkaConfig.kafkaConnection.Subscribe(e.kafkaConfig.groupId, []string{e.kafkaConfig.topic}, e.consumeTask)
	if err != nil {
		return errors.Wrapf(err, "subscribe: subscription to %s failed - %v", e.kafkaConfig.topic)
	}

	if e.kafkaSubscription != nil {
		e.kafkaSubscription.Close()
	}

	e.kafkaSubscription = subscription
	e.log.Info("subscribe: subscription to %s ok!", e.kafkaConfig.topic)
	return nil
}

func (e *executor) consumeTask(m *kafka.Message) {
	defer panicRecover(e.log, "consumeTask: %s", m.Key)

	var t Task
	err := json.Unmarshal(m.Value, &t)
	if err != nil {
		e.log.Error("consumeTask: error while deserializing task: %s - %v", m.Value, err)
		return
	}

	e.log.Info("consumeTask: processing task %s", t.Id)

	e.log.Debug("consumeTask: updating task status to %d", TS_InProgress)
	err = e.updateTaskStatus([]string{t.Id}, TS_InProgress)
	if err != nil {
		e.log.Warn("consumeTask: error updating task status to %d - %v", TS_InProgress, err)
	}

	e.log.Debug("consumeTask: executing task %s", t.Id)
	err = e.executeTask(&t)
	// TODO: if task schedule is Cron -> update NextExecution.

	taskStatus := TS_Completed
	if err != nil {
		e.log.Error("consumeTask: error executing task %s - %v", t.Id, err)
		taskStatus = TS_Failed
	} else {
		e.log.Debug("consumeTask: executed task %s", t.Id)
	}

	e.log.Debug("consumeTask: updating task %s status to %d", t.Id, taskStatus)
	err = e.updateTaskStatus([]string{t.Id}, taskStatus)
	if err != nil {
		e.log.Warn("consumeTask: error updating task %s status to %d - %v", t.Id, taskStatus, err)
	}

	e.log.Info("consumeTask: finished processing task %s", t.Id)
}

func (e *executor) executeTask(t *Task) error {
	switch t.Definition.Transport.Type {
	case TT_Kafka:
		return e.executeKafkaTask(t)
	case TT_Http:
		return e.executeHttpTask(t)

	default:
		return fmt.Errorf("executeTask: unsupported transport type %s", t.Definition.Transport.Type)
	}
}

func (e *executor) executeKafkaTask(t *Task) error {
	var kafkaTransport KafkaTransport
	err := decode(t.Definition.Transport.Payload, &kafkaTransport)
	if err != nil {
		return errors.Wrapf(err, "executeKafkaTask: error decoding kafka transport %v for task %s", t.Definition.Transport.Payload, t.Id)
	}

	e.log.Debug("executeKafkaTask: task %s - publishing message to topic %s: ", t.Id, kafkaTransport.Topic, kafkaTransport.Message)
	err = retryIfError(
		func() error {
			return e.kafkaConfig.kafkaConnection.PublishBytes(kafkaTransport.Topic, []byte(kafkaTransport.Message), nil)
		},
		500*time.Millisecond,
		3,
		e.log,
	)

	if err != nil {
		return errors.Wrapf(err, "executeKafkaTask: error publishing message to kafka - %s", kafkaTransport.Message)
	}
	e.log.Debug("executeKafkaTask: task %s - published message to topic %s: ", t.Id, kafkaTransport.Topic, kafkaTransport.Message)
	return nil
}

func (e *executor) executeHttpTask(t *Task) error {
	var err error
	var httpTransport HttpTransport
	err = decode(t.Definition.Transport.Payload, &httpTransport)
	if err != nil {
		return errors.Wrapf(err, "executeHttpTask: error decoding http transport %v for task %s", t.Definition.Transport.Payload, t.Id)
	}

	e.log.Debug("executeHttpTask: task %s - executing request %s %s", t.Id, httpTransport.Method, httpTransport.Url)
	retryIfError(
		func() error {
			var body io.Reader
			if httpTransport.Body != nil {
				body = strings.NewReader(*httpTransport.Body)
			}
			req, errAux := http.NewRequest(httpTransport.Method, httpTransport.Url, body)
			if errAux != nil {
				err = errors.Wrapf(errAux, "executeHttpTask: error creating request for task %s - method: %s, url: %s", t.Id, httpTransport.Method, httpTransport.Url)
				return nil // No retry
			}

			contentType := e.getContentType(&httpTransport)
			if contentType != nil {
				req.Header.Add("Content-Type", *contentType)
			}

			res, errAux := e.httpClient.Do(req)
			if errAux != nil || res.StatusCode >= http.StatusInternalServerError {
				return errors.Wrapf(errAux, "executeHttpTask: error executing request for task %s - %s %s", t.Id, httpTransport.Method, httpTransport.Url)
			}
			if res.StatusCode >= http.StatusBadRequest {
				resBody := e.readBody(res, t.Id)
				err = fmt.Errorf("executeHttpTask: error executing request for task %s - %s %s -> status %d | %v", t.Id, httpTransport.Method, httpTransport.Url, res.StatusCode, resBody)
				return nil // No retry
			}
			return nil
		},
		500*time.Millisecond,
		3,
		e.log,
	)

	if err != nil {
		return err
	}
	e.log.Debug("executeHttpTask: task %s - executed request %s %s", httpTransport.Method, httpTransport.Url)
	return nil
}

func (e *executor) readBody(res *http.Response, taskId string) *string {
	body, err := ioutil.ReadAll(res.Body)
	if err != nil {
		e.log.Warn("readBody: error reading response body for task %s http response", taskId)
		return nil
	}
	bodyStr := string(body)
	return &bodyStr
}

func (e *executor) getContentType(httpTransport *HttpTransport) *string {
	if httpTransport.ContentType != nil {
		return httpTransport.ContentType
	}

	if httpTransport.Body != nil {
		contentType := http.DetectContentType([]byte(*httpTransport.Body))
		return &contentType
	}

	return nil
}

func (e *executor) updateTaskStatus(taskIds []string, status TaskStatus) error {
	return retryIfError(
		func() error {
			return e.taskRepository.UpdateTaskStatus(taskIds, status)
		},
		250*time.Millisecond,
		3,
		e.log,
	)
}
