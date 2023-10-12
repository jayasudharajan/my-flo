package main

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"sync/atomic"
	"time"

	"github.com/google/uuid"
	tracing "gitlab.com/ctangfbwinn/flo-insta-tracing"

	"github.com/confluentinc/confluent-kafka-go/kafka"
)

const TOPIC_ACTIVITIES = "entity-activity-v1"

type ActivityMonitor interface {
	Open()
	Close()
	Ping(ctx context.Context) error
}

type activityMonitor struct {
	log        *Logger
	kConn      *KafkaConnection
	kTopic     string
	kGroup     string
	kSub       *KafkaSubscription
	tkExch     TokenExchange
	getAccSync func() AccountSync //do not cache, pull per msg processed
	state      int32              //0=closed, 1=opened
	appCx      *appContext
	deDuper    KeyPerDuration
}

func CreateActivityMonitor(
	log *Logger,
	kConn *KafkaConnection,
	tkExch TokenExchange,
	appCx *appContext,
	getAccSync func() AccountSync) ActivityMonitor {

	ddFlush := time.Duration(5) * time.Minute
	if d, e := time.ParseDuration(getEnvOrDefault("FLO_KAFKA_DEDUPLICATE_TTL", "")); e == nil {
		if d < time.Minute {
			ddFlush = time.Minute
		} else {
			ddFlush = d
		}
	}
	return &activityMonitor{
		kConn:      kConn,
		kTopic:     getEnvOrDefault("FLO_KAFKA_TOPIC_ACTIVITIES", TOPIC_ACTIVITIES),
		kGroup:     getEnvOrDefault("FLO_KAFKA_GROUP_ID", "flo-moen-auth-local"),
		appCx:      appCx,
		tkExch:     tkExch,
		getAccSync: getAccSync,
		log:        log.CloneAsChild("EntActMon"),
		deDuper:    CreateKeyPerDuration(ddFlush),
	}
}

// Ping probe kafka
func (a *activityMonitor) Ping(ctx context.Context) error {
	if atomic.LoadInt32(&a.state) == 0 {
		return a.log.Warn("Ping: state==0 (closed)")
	} else if e := a.kConn.Producer.GetFatalError(); e != nil {
		return a.log.IfErrorF(e, "Ping: producer")
	} else if a.kSub == nil || a.kSub.Consumer == nil {
		return a.log.Warn("Ping: subscriber is nil")
	} else if _, e = a.kSub.Consumer.GetMetadata(&a.kTopic, false, 3000); e != nil {
		return a.log.IfErrorF(e, "Ping: consumer")
	} else {
		return nil
	}
}

func (a *activityMonitor) Open() {
	if atomic.CompareAndSwapInt32(&a.state, 0, 1) {
		RetryIfError(a.subscribe, time.Second*15, a.log)
		a.log.Info("Opened")
	}
}

func (a *activityMonitor) Close() {
	if atomic.CompareAndSwapInt32(&a.state, 1, 0) {
		if a.kSub != nil {
			a.kSub.Close()
			a.kSub = nil
		}
		a.log.Info("Closed")
	}
}

func (a *activityMonitor) groupName() string {
	var (
		k        = strings.ReplaceAll(uuid.New().String(), "-", "")
		hostSwap = false
	)
	if a.appCx != nil && len(a.appCx.Host) > 1 {
		if s, e := mh3(strings.ToLower(a.appCx.Host)); e == nil {
			k = fmt.Sprintf("%s+%s", s, k[0:4]) //ensure RAND
			hostSwap = true
		}
	}
	name := fmt.Sprintf("%s:%s", a.kGroup, k)
	a.log.Debug("groupName: %v | using_host=%v", name, hostSwap)
	return name
}

func (a *activityMonitor) subscribe() error {
	if atomic.LoadInt32(&a.state) == 1 {
		if sub, e := a.kConn.Subscribe(a.groupName(), []string{a.kTopic}, a.consume); e != nil {
			return a.log.IfWarnF(e, "subscribe topic=%q group=%q", a.kTopic, a.kGroup)
		} else {
			if a.kSub != nil {
				a.kSub.Close()
			}
			a.kSub = sub
		}
	}
	return nil
}

func (a *activityMonitor) parse(msg *kafka.Message) *EntityEventEnvelope {
	if ml := len(msg.Value); ml < 64 || msg.Value[0] != '{' || msg.Value[ml-1] != '}' {
		return nil //skip
	}
	if hash, e := mh3(fmt.Sprintf("%s|%s", msg.Key, msg.Value)); e == nil {
		if !a.deDuper.Check(hash, time.Second*30) {
			a.log.Trace("consume: SKIP %s", msg.Value)
			return nil //skip duplicate
		}
	}
	evt := EntityEventEnvelope{}
	if e := json.Unmarshal(msg.Value, &evt); e != nil {
		a.log.IfErrorF(e, "consume: unmarshal")
		return nil
	} else {
		return &evt
	}
}

func (a *activityMonitor) consume(msg *kafka.Message) {
	evt := a.parse(msg)
	if evt == nil {
		return
	}

	ctx, sp := tracing.InstaKafkaCtxExtractWithSpan(msg, "")
	defer sp.Finish()

	switch typ := strings.ToLower(evt.Type); typ {
	case "location":
		switch action := strings.ToLower(evt.Action); action {
		case "deleted":
			a.locationRemoved(ctx, evt) //remove link entry & trigger unlink events in Kafka
		}
	case "user":
		switch action := strings.ToLower(evt.Action); action {
		case "updated", "linked", "unlinked": //mainly used to clear local (in-memory cache only)
			a.userLinking(ctx, action, evt)
		case "deleted": //should trigger deep account cleanup with removal of all linked data
			a.userRemoved(ctx, evt)
		}
	}
}

func (a *activityMonitor) locationRemoved(ctx context.Context, evt *EntityEventEnvelope) {
	ent := FloEntity{}
	if e := jsonMap(evt.Item, &ent); e != nil {
		a.log.IfWarnF(e, "locationRemoved: %v", evt.Action)
		return
	} else if ent.Id == "" {
		return
	}
	if sync := a.getAccSync(); sync != nil {
		sync.OnFloLocRemoved(ctx, &ent)
	}
}

func (a *activityMonitor) userLinking(ctx context.Context, action string, evt *EntityEventEnvelope) {
	ent := LinkEvent{}
	if strings.Contains(action, "link") {
		if e := jsonMap(evt.Item, &ent); e != nil {
			a.log.IfWarnF(e, "userLinking: %v", evt.Action)
			return
		} else if ent.User == nil && ent.External.Id == "" {
			return
		}
	} else { //user update etc, mock event
		ent.User = evt.Item
	}
	if sync := a.getAccSync(); sync != nil {
		sync.UserCacheClean(&ent)
	}
	if action == "unlinked" && ent.External.Id != "" {
		if strings.EqualFold(ent.External.Vendor, "moen") && strings.EqualFold(ent.External.Type, "user") {
			if e := a.tkExch.RemoveUser(ctx, ent.External.Id, true); e == nil {
				a.log.Debug("CACHE_FLUSH (local) %s %s %s", ent.External.Vendor, ent.External.Type, ent.External.Id)
			}
		}
	}
}

func (a *activityMonitor) userRemoved(ctx context.Context, evt *EntityEventEnvelope) {
	ent := FloEntity{}
	if e := jsonMap(evt.Item, &ent); e != nil {
		a.log.IfWarnF(e, "userRemoved: %v", evt.Action)
		return
	} else if ent.Id == "" {
		return
	}
	a.log.Debug("FLO_USER_RM %s", ent.Id)
	if sync := a.getAccSync(); sync != nil {
		sync.OnFloUserRemoved(ctx, &ent)        //should trigger unlink
		go a.userRemoveCleanup(ctx, sync, &ent) //double cleanup to ensure if unlink fail
	}
}

func (a *activityMonitor) userRemoveCleanup(ctx context.Context, sync AccountSync, ent *FloEntity) {
	defer panicRecover(a.log, "userRemoveCleanup: %v", ent)
	if sd, e := sync.GetSyncData(ctx, &SyncLookup{FloId: ent.Id}); e == nil && sd != nil { //attempt token cleanup ASAP
		if e = a.tkExch.RemoveUser(ctx, sd.MoenId, false); e == nil {
			a.log.Info("CACHE_FLUSH (all) %s %s %s", "moen", "user", sd.MoenId)
		}
	}
	time.Sleep(time.Second * 10)               //flush cache after 10s anyway
	sync.UserCacheClean(&LinkEvent{User: ent}) //delay cleanup
}
