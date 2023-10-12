package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/pkg/errors"
)

type MudTaskRepository interface {
	InsertTask(ctx context.Context, t *Task) (sql.Result, error)
	GetTasks(ctx context.Context, filter TaskFilter) ([]*Task, error)
	GetDefaultThresholds(ctx context.Context, accountId *string, deviceMake string) (*ThresholdDefaults, error)
	UpdateTask(ctx context.Context, t *Task) (sql.Result, error)
}

type mudTaskRepository struct {
	log   *Logger
	pgSql *PgSqlDb
}

func CreateMudTaskRepository(log *Logger, pgSql *PgSqlDb) MudTaskRepository {
	return &mudTaskRepository{
		log:   log.CloneAsChild("mudTaskRepository"),
		pgSql: pgSql,
	}
}

func (m *mudTaskRepository) InsertTask(ctx context.Context, t *Task) (sql.Result, error) {
	result, err := m.pgSql.Exec(ctx, `
		INSERT INTO mud_task (id, mac_address, type, status, created_at, updated_at) 
		VALUES ($1, $2, $3, $4, $5, $6)
	`, t.Id, t.MacAddress, t.Type, t.Status, t.CreatedAt, t.UpdatedAt)

	if err != nil {
		return nil, errors.Wrap(err, "InsertTask: query failed")
	}

	return result, nil
}

func (m *mudTaskRepository) UpdateTask(ctx context.Context, t *Task) (sql.Result, error) {
	result, err := m.pgSql.Exec(ctx, `
		UPDATE mud_task SET mac_address = $1, type = $2, status = $3, updated_at = $4 
		WHERE id = $5
	`, t.MacAddress, t.Type, t.Status, time.Now(), t.Id)

	if err != nil {
		return nil, errors.Wrap(err, "UpdateTask: query failed")
	}
	if rows, _ := result.RowsAffected(); rows < 1 {
		return result, errors.Wrapf(err, "UpdateTask: Task not found id: %v", t.Id)
	}
	return result, nil
}

func (m *mudTaskRepository) GetTasks(ctx context.Context, filter TaskFilter) ([]*Task, error) {
	sqlStr := `
		SELECT id, mac_address, type, status, created_at, updated_at
		FROM mud_task
	`
	whereSql, params, _ := m.buildWhereQuery(&filter)
	rows, err := m.pgSql.Query(ctx, sqlStr+whereSql, params...)
	if err != nil {
		return nil, errors.Wrap(err, "GetTasks: query failed")
	}
	defer rows.Close()

	tasks := make([]*Task, 0)
	for rows.Next() {
		var t Task
		err = rows.Scan(&t.Id, &t.MacAddress, &t.Type, &t.Status, &t.CreatedAt, &t.UpdatedAt)
		if err != nil {
			return nil, err
		}
		tasks = append(tasks, &t)
	}

	return tasks, nil
}

func (m *mudTaskRepository) buildWhereQuery(filter *TaskFilter) (whereSql string, params []interface{}, err error) {
	params = make([]interface{}, 0)

	// type filter
	whereSql = "WHERE type = $1"
	paramCount := 1
	params = append(params, filter.Type)

	// macAddress filter
	if len(filter.MacAddress) > 0 {
		paramCount++
		whereSql = whereSql + fmt.Sprintf(" AND mac_address = $%v", paramCount)
		params = append(params, filter.MacAddress)
	}

	// status filter - multiple values
	if len(filter.Status) > 0 {
		statusWhere := make([]string, 0)
		for _, s := range filter.Status {
			paramCount++
			statusWhere = append(statusWhere, fmt.Sprintf("status = $%v", paramCount))
			params = append(params, s)
		}

		whereSql = whereSql + " AND (" + strings.Join(statusWhere, " OR ") + ")"
	}
	return
}

// GetDefaultThresholds gets the default tresholds based on account id and device make
func (m *mudTaskRepository) GetDefaultThresholds(ctx context.Context, accountId *string, deviceMake string) (*ThresholdDefaults, error) {
	var params []interface{}
	sqlStr := `
		SELECT account_id, threshold_values_json, start_minute, end_minute, "order", repeat_json, created_at, updated_at
		FROM mud_threshold_defaults 
		WHERE make = $1
	`
	params = append(params, deviceMake)
	if accountId != nil {
		sqlStr = sqlStr + "AND account_id = $2"
		params = append(params, *accountId)
	} else {
		sqlStr = sqlStr + "AND account_id is NULL"
	}
	rows, err := m.pgSql.Query(ctx, sqlStr, params...)
	if err != nil {
		return nil, errors.Wrap(err, "GetDefaultThresholds: query failed")
	}
	defer rows.Close()
	if rows.Next() {
		def := ThresholdDefaults{}
		var jsonAsString string
		var repeatJsonString string
		err = rows.Scan(&def.AccountId, &jsonAsString, &def.StartMinute, &def.EndMinute, &def.Order, &repeatJsonString, &def.CreatedAt, &def.UpdatedAt)
		if err != nil {
			return nil, err
		}

		repeatData := Repeat{}
		err = json.Unmarshal([]byte(repeatJsonString), &repeatData)
		if err != nil {
			return nil, errors.Wrapf(err, "GetDefaultThresholds: error deserializing json %v.", repeatJsonString)
		}
		def.DefaultValues = &jsonAsString
		def.Repeat = repeatData
		return &def, nil
	}

	return nil, nil
}
