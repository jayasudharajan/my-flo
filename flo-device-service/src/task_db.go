package main

import (
	"database/sql"
	"time"

	"device-service/models"

	"github.com/pkg/errors"
)

// TaskRepository is a repository to access tasks
type PgTaskRepository struct {
	DB *sql.DB
}

type TaskRepository interface {
	GetTasks(taskType models.TaskType, taskStatus models.TaskStatus, limit int32) ([]*models.Task, error)
	UpdateTask(t *models.Task) error
	InsertTask(t *models.Task) error
}

func (m PgTaskRepository) GetTasks(taskType models.TaskType, taskStatus models.TaskStatus, limit int32) ([]*models.Task, error) {
	const sqlStr = `
		SELECT id, mac_address, task_type, task_state, created_at, updated_at
		FROM task WHERE task_type = $1 and task_state = $2
		ORDER BY created_at ASC
		LIMIT $3
	`
	rows, err := m.DB.Query(sqlStr, taskType, taskStatus, limit)
	if err != nil {
		return nil, errors.Wrap(err, "GetTasks: query failed")
	}
	defer rows.Close()

	tasks := make([]*models.Task, 0)
	for rows.Next() {
		var t models.Task
		err = rows.Scan(&t.Id, &t.MacAddress, &t.Type, &t.Status, &t.CreatedAt, &t.UpdatedAt)
		if err != nil {
			return nil, err
		}
		tasks = append(tasks, &t)
	}

	return tasks, nil
}

func (m PgTaskRepository) UpdateTask(t *models.Task) error {
	result, err := m.DB.Exec(`
		UPDATE task SET mac_address = $1, task_type = $2, task_state = $3, updated_at = $4 
		WHERE id = $5
	`, t.MacAddress, t.Type, t.Status, time.Now(), t.Id)

	if err != nil {
		return errors.Wrap(err, "UpdateTask: query failed")
	}
	if rows, _ := result.RowsAffected(); rows < 1 {
		return errors.Wrapf(err, "UpdateTask: Task not found id: %v", t.Id)
	}
	return nil
}

func (m PgTaskRepository) InsertTask(t *models.Task) error {
	_, err := m.DB.Exec(`
		INSERT INTO task (id, mac_address, task_type, task_state, created_at, updated_at) 
		VALUES ($1, $2, $3, $4, $5, $6)
	`, t.Id, t.MacAddress, t.Type, t.Status, t.CreatedAt, t.UpdatedAt)

	if err != nil {
		return errors.Wrap(err, "InsertTask: query failed")
	}

	return nil
}
