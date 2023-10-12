package main

import (
	"database/sql"
	log "github.com/labstack/gommon/log"
	"strings"
)

// DeviceRepository is the device repository
type PgOnboardingLogRepository struct {
	DB *sql.DB
}

// GetOnboardingLogs returns devices onboarding logs that have the event installed and are shutoff
func (r *PgOnboardingLogRepository) GetNeedInstallOnboardingLogs(offset int, limit int) ([]OnboardingLog, error) {
	var onboardingLogs []OnboardingLog

	if limit > 1000 {
		limit = 1000
	}

	getAllOnboardingLog := `
		SELECT
			   id,
			   mac_address,
		       created_at,
		       updated_last_time,
		       event,
		       device_model,
		       device_type,
		       is_paired
		FROM mirror_onboarding_log o
		WHERE o.device_type = 'flo_device_v2'
		AND o.event = 2
		AND o.created_at > current_date - interval '5' day
		OFFSET $1
		LIMIT $2
		`

	rows, err := r.DB.Query(getAllOnboardingLog, offset, limit)
	if err != nil {
		log.Errorf("query %s has failed, err: %v", getAllOnboardingLog, err)
		return onboardingLogs, err
	}
	defer rows.Close()

	for rows.Next() {
		oLog := OnboardingLog{}
		if err := rows.Scan(&oLog.Id,
			&oLog.MacAddress,
			&oLog.Created,
			&oLog.UpdatedLastTime,
			&oLog.Event,
			&oLog.DeviceModel,
			&oLog.DeviceType,
			&oLog.IsPaired); err != nil {
			log.Errorf("failed to convert row, err: %s", err)
		} else {
			oLog.MacAddress = strings.Replace(oLog.MacAddress, ":", "", -1)
			onboardingLogs = append(onboardingLogs, oLog)
		}
	}
	if err = rows.Err(); err != nil {
		return onboardingLogs, err
	}
	return onboardingLogs, nil
}
