package main

import (
	"database/sql"
	"sync/atomic"
	"time"

	"github.com/lib/pq"
)

type Attribute struct {
	ID        string
	Value     string
	UpdatedAt time.Time
}
type archiverRepo struct {
	pgsql     *PgSqlDb
	readpgsql *PgSqlDb
	logger    *Logger
	state     int32
}

func CreateArchiverRepo(pgsql *PgSqlDb, readpgsql *PgSqlDb, log *Logger) *archiverRepo {
	return &archiverRepo{
		pgsql:     pgsql,
		readpgsql: readpgsql,
		logger:    log.CloneAsChild("archiverRepo"),
		state:     1,
	}
}

func (c *archiverRepo) Close() {
	if atomic.CompareAndSwapInt32(&c.state, 1, 0) {
		c.pgsql.Close()
		if c.pgsql != c.readpgsql {
			c.readpgsql.Close()
		}
	}
}
func (c *archiverRepo) EditAttribute(key string) (*Attribute, error) {
	attr := Attribute{}
	rows, err := c.pgsql.Connection.Query("select attr_id, attr_val, updated_at from puck_attribute where attr_id = $1 limit 1", key)
	if err != nil {
		return nil, c.logger.Warn("editAttribute query failed, %v", err.Error())
	}
	defer rows.Close()
	for rows.Next() {
		err = rows.Scan(&attr.ID, &attr.Value, &attr.UpdatedAt)
		if err != nil {
			return nil, c.logger.Warn("editAttribute scan failed, %v", err.Error())
		}
	}
	return &attr, nil
}

func (c *archiverRepo) UpdateAttribute(attribute *Attribute) error {
	_, err := c.pgsql.ExecNonQuery("UPDATE puck_attribute set attr_val = $1, updated_at = $2 where attr_id = $3",
		attribute.Value, time.Now().UTC(), attribute.ID)
	if err != nil {
		return c.logger.Warn("updateAttribute failed, %v", err.Error())
	}

	return nil
}

func (c *archiverRepo) DeleteEntries(until time.Time) error {
	_, err := c.pgsql.ExecNonQuery(`
		DELETE
		FROM puck_telemetry pt
		WHERE pt.created_time < $1
		`, until)
	return err
}

func (c *archiverRepo) DeleteEntriesWithHint(until time.Time, deviceIds []string) error {
	_, err := c.pgsql.ExecNonQuery(`
		DELETE
		FROM puck_telemetry pt
		WHERE pt.created_time < $1
		AND pt.mac_address  = ANY($2)
		`, until, pq.Array(deviceIds))
	return err
}

func (c *archiverRepo) GetArchivableEntries(from, to time.Time, offset, limit int) (map[string][]string, error) {
	rows, err := c.readpgsql.Query(`
	SELECT 
		pt.mac_address, json_strip_nulls(to_json(pt)) 
	FROM puck_telemetry pt 
	WHERE
		pt.created_time >= $1 
		AND pt.created_time < $2
	ORDER BY pt.created_time limit $3 offset $4;
	`, from, to, limit, offset)
	if err != nil {
		return nil, err
	}

	return c.scanArchivableEntries(rows)
}

func (c *archiverRepo) GetArchivableEntriesWithHint(from, to time.Time, offset, limit int, deviceIds []string) (map[string][]string, error) {

	rows, err := c.readpgsql.Query(`
	SELECT 
		pt.mac_address, json_strip_nulls(to_json(pt)) 
	FROM puck_telemetry pt 
	WHERE
		pt.created_time >= $1 
		AND pt.created_time < $2
		AND pt.mac_address  = ANY($3)
	ORDER BY pt.created_time limit $4 offset $5;
	`, from, to, pq.Array(deviceIds), limit, offset)

	if err != nil {
		return nil, err
	}

	return c.scanArchivableEntries(rows)
}

func (c *archiverRepo) scanArchivableEntries(rows *sql.Rows) (map[string][]string, error) {
	entries := make(map[string][]string)
	for rows.Next() {
		var e, did string
		err := rows.Scan(&did, &e)
		if err != nil {
			return nil, err
		}
		entries[did] = append(entries[did], e)
	}

	return entries, nil
}
