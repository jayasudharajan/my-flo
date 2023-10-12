package stores

import (
	"errors"

	"flotechnologies.com/flo-resource-event/src/commons/datefilter"
	"flotechnologies.com/flo-resource-event/src/commons/utils"
	"flotechnologies.com/flo-resource-event/src/resourceevent"
	"flotechnologies.com/flo-resource-event/src/storages/sql"
	"github.com/google/uuid"
)

const (
	ENVVAR_PGDB_CN = "FLO_PGDB_CN"
)

type resourceEventStore struct {
	pg  *sql.PgSqlDb
	log *utils.Logger
}

type ResourceEventStore interface {
	Ping() error
	InsertResourceEvent(resourceEvent resourceevent.ResourceEvent) error
	GetAllByAccountId(accountId uuid.UUID, dateFilter datefilter.DateFilter) ([]resourceevent.ResourceEvent, error)
}

func (es *resourceEventStore) Ping() error {
	if es == nil {
		return errors.New("binding source nil")
	}
	_, e := es.pg.ExecNonQuery(`select account_id from resource_event limit 0;`)
	return es.log.IfErrorF(e, "Ping")
}

func CreateResourceEventStore(log *utils.Logger) ResourceEventStore {
	es := resourceEventStore{
		log: log.CloneAsChild("resourceEventDB"),
	}
	var e error
	if cn := utils.GetEnvOrDefault(ENVVAR_PGDB_CN, ""); cn == "" {
		es.log.Fatal("CreateResourceEventStore: missing %v", ENVVAR_PGDB_CN)
		return nil
	} else if es.pg, e = sql.OpenPgSqlDb(cn); e != nil {
		es.log.IfFatalF(e, "CreateResourceEventStore")
	}

	return &es
}

func (es *resourceEventStore) InsertResourceEvent(re resourceevent.ResourceEvent) error {
	const sql = `INSERT INTO resource_event (created,account_id,resource_id,resource_type,resource_action,
		resource_name,user_name,user_id,ip_address,client_id,user_agent,event_data) 
		VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
		ON CONFLICT (user_id, created, resource_id)
		DO NOTHING;`

	if _, e := es.pg.Connection.Exec(sql, re.Created, re.AccountId,
		re.ResourceId, re.ResourceType, re.ResourceAction,
		re.ResourceName, re.UserName, re.UserId, re.IpAddress,
		re.ClientId, re.UserAgent, re.EventData); e != nil {
		return es.log.IfErrorF(e, "InsertResourceEvent: (PG) %v", re.AccountId)
	}

	return nil
}

func (es *resourceEventStore) GetAllByAccountId(accountId uuid.UUID, dateFilter datefilter.DateFilter) ([]resourceevent.ResourceEvent, error) {
	selectSqlQuery := `SELECT created,account_id,resource_id,resource_type,resource_action,
	resource_name,user_name,user_id,ip_address,client_id,user_agent,event_data FROM resource_event 
	where account_id=$1 AND created BETWEEN $2 AND $3
	ORDER BY created DESC;`

	if rows, err := es.pg.Query(selectSqlQuery, accountId, dateFilter.From, dateFilter.To); err != nil {
		return nil, err
	} else {
		defer rows.Close()

		data := []resourceevent.ResourceEvent{}
		for rows.Next() {
			re := resourceevent.ResourceEvent{}
			if err := rows.Scan(&re.Created, &re.AccountId, &re.ResourceId, &re.ResourceType,
				&re.ResourceAction, &re.ResourceName, &re.UserName, &re.UserId, &re.IpAddress, &re.ClientId,
				&re.UserAgent, &re.EventData); err != nil {
				es.log.Error(err.Error())
			} else {
				data = append(data, re)
			}
		}
		return data, nil
	}
}
