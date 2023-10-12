package main

import (
	"database/sql/driver"
	"encoding/json"

	"github.com/lib/pq"
	"github.com/pkg/errors"
)

type TaskRepository interface {
	InsertTask(t *Task) error
	GetDueTasks() ([]*Task, error)
	UpdateTaskStatus(taskIds []string, status TaskStatus) error
	CancelTask(taskId string) (bool, error)
}

type taskRepository struct {
	log   *Logger
	pgSql *PgSqlDb
}

// Sentinel error. Not the best thing to do but works for now.
var UniqueConstraintFailed = errors.New("Unique constraint failed.")

func CreateTaskRepository(log *Logger, pgSql *PgSqlDb) TaskRepository {
	return &taskRepository{
		log:   log.CloneAsChild("repository"),
		pgSql: pgSql,
	}
}

func (r *taskRepository) InsertTask(t *Task) error {
	_, err := r.pgSql.Exec(`
		INSERT INTO task (id, definition, status, next_execution, created_at, updated_at) 
		VALUES ($1, $2, $3, $4, $5, $6)
	`, t.Id, t.Definition, t.Status, t.NextExecutionTime, t.CreatedAt, t.UpdatedAt)

	if err != nil {
		pqErr := err.(*pq.Error)
		if pqErr.Code == "23505" {
			return UniqueConstraintFailed
		}
		return errors.Wrap(err, "InsertTask: query failed")
	}

	return nil
}

func (r *taskRepository) GetDueTasks() ([]*Task, error) {
	rows, err := r.pgSql.Query(`
		SELECT id, definition, status, next_execution, created_at, updated_at
		FROM task
		WHERE 
			status = $1 AND 
			next_execution <= NOW()
	`, TS_Pending)

	if err != nil {
		return nil, errors.Wrap(err, "GetDueTasks: query failed")
	}

	tasks := make([]*Task, 0)
	for rows.Next() {
		var t Task
		err = rows.Scan(&t.Id, &t.Definition, &t.Status, &t.NextExecutionTime, &t.CreatedAt, &t.UpdatedAt)
		if err != nil {
			return nil, err
		}
		tasks = append(tasks, &t)
	}

	return tasks, nil
}

func (r *taskRepository) UpdateTaskStatus(taskIds []string, status TaskStatus) error {
	_, err := r.pgSql.Exec(`
		UPDATE task 
		SET 
			status = $1,
			updated_at = NOW()
		WHERE id = ANY($2)
	`, status, pq.Array(taskIds))

	if err != nil {
		return errors.Wrap(err, "UpdateTaskStatus: query failed")
	}
	return nil
}

func (r *taskRepository) CancelTask(taskId string) (bool, error) {
	res, err := r.pgSql.Exec(`
		UPDATE task 
		SET 
			status = $1,
			updated_at = NOW()
		WHERE id = $2 AND status = $3
	`, TS_Canceled, taskId, TS_Pending)

	if err != nil {
		return false, errors.Wrap(err, "CancelTask: query failed")
	}

	rowsAffected, err := res.RowsAffected()
	if err != nil {
		return false, errors.Wrap(err, "CancelTask: error getting affected rows")
	}

	return rowsAffected > 0, nil
}

func (v *TaskDefinition) Value() (driver.Value, error) {
	if v == nil {
		return []byte("{}"), nil
	}
	return json.Marshal(v)
}

func (v *TaskDefinition) Scan(value interface{}) error {
	buf, ok := value.([]byte)
	if !ok {
		return errors.New("type assertion to []byte failed")
	}
	err := json.Unmarshal(buf, &v)
	return err
}
