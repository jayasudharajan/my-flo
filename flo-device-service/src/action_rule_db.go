package main

import (
	"context"
	"database/sql"

	"github.com/lib/pq"
)

const getActionRulesByDeviceId = `
	SELECT id, event, action, target_device_id, exec_order, created_at, updated_at, enabled
	FROM action_rule
	WHERE device_id = $1;
`

const upsertActionRule = `
	INSERT INTO action_rule (id, device_id, event, action, target_device_id, exec_order, created_at, updated_at, enabled)
		VALUES ($1, $2, $3, $4, $5, $6, now(), now(), $7)
		ON CONFLICT (id)
			DO UPDATE SET (event, action, exec_order, updated_at, enabled) = ($3, $4, $6, now(), $7)
		RETURNING id, event, action, target_device_id, exec_order, created_at, updated_at, enabled;
`

const deleteActionRule = `
	DELETE FROM action_rule WHERE id = $1 AND device_id = $2
		RETURNING id, event, action, target_device_id, exec_order, created_at, updated_at, enabled;
`

const deleteActionRulesByTarget = `
	DELETE FROM action_rule WHERE target_device_id = $1;
`

type PgActionRuleRepository struct {
	DB *sql.DB
}

func (r *PgActionRuleRepository) GetActionRules(ctx context.Context, deviceId string) ([]ActionRule, error) {
	rows, err := r.DB.QueryContext(ctx, getActionRulesByDeviceId, deviceId)
	if err != nil {
		return []ActionRule{}, err
	}
	defer rows.Close()

	var actionRuleSlice = []ActionRule{}
	var actionRule ActionRule

	for rows.Next() {
		rows.Scan(&actionRule.Id, &actionRule.Event, &actionRule.Action, &actionRule.TargetDeviceId, &actionRule.Order, &actionRule.CreatedAt, &actionRule.UpdatedAt, &actionRule.Enabled)
		actionRuleSlice = append(actionRuleSlice, actionRule)
	}
	if err = rows.Err(); err != nil {
		return []ActionRule{}, err
	}
	return actionRuleSlice, err
}

func (r *PgActionRuleRepository) UpsertActionRules(deviceId string, actionRules ActionRules) (ActionRules, error) {
	var actionRuleSlice = []ActionRule{}
	var upsertedActionRule ActionRule

	for _, actionRule := range actionRules.Data {
		if actionRule.Id == "" {
			actionRule.Id, _ = GenerateUuid()
		}
		err := r.DB.
			QueryRow(upsertActionRule, actionRule.Id, deviceId, actionRule.Event, actionRule.Action, actionRule.TargetDeviceId, actionRule.Order, actionRule.Enabled).
			Scan(&upsertedActionRule.Id, &upsertedActionRule.Event, &upsertedActionRule.Action, &upsertedActionRule.TargetDeviceId, &upsertedActionRule.Order, &upsertedActionRule.CreatedAt, &upsertedActionRule.UpdatedAt, &upsertedActionRule.Enabled)
		if err != nil {
			pqErr := err.(*pq.Error)
			if pqErr.Code.Name() == "unique_violation" {
				err = UniqueConstraintFailed
			}

			return ActionRules{
				Data: []ActionRule{},
			}, err
		}
		actionRuleSlice = append(actionRuleSlice, upsertedActionRule)
	}

	return ActionRules{
		Data: actionRuleSlice,
	}, nil
}

func (r *PgActionRuleRepository) DeleteActionRule(deviceId string, actionRuleId string) (ActionRule, error) {
	var deletedActionRule ActionRule

	err := r.DB.
		QueryRow(deleteActionRule, actionRuleId, deviceId).
		Scan(&deletedActionRule.Id, &deletedActionRule.Event, &deletedActionRule.Action, &deletedActionRule.TargetDeviceId, &deletedActionRule.Order, &deletedActionRule.CreatedAt, &deletedActionRule.UpdatedAt, &deletedActionRule.Enabled)
	if err != nil {
		return ActionRule{}, err
	}

	return deletedActionRule, err
}

func (r *PgActionRuleRepository) DeleteActionRulesByTarget(deviceId string) error {
	_, err := r.DB.Exec(deleteActionRulesByTarget, deviceId)

	if err != nil {
		return err
	}
	return nil
}
