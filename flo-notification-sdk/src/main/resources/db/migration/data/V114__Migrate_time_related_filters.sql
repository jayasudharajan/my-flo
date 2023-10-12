-- Snooze Filter
INSERT INTO filter_state (alarm_id, type, device_id, incident_id, expiration)
  SELECT alarm_id, 1, icd_id, id, snooze_to
  FROM incident
  WHERE snooze_to > now() at time zone 'utc';

-- Max Frequency Cap Filter
INSERT INTO filter_state (alarm_id, type, device_id, incident_id, expiration)
  SELECT i.alarm_id, 2, i.icd_id, i.id, (i.create_at + a.max_delivery_frequency::interval)
  FROM incident i
  INNER JOIN alarm a ON a.id = i.alarm_id
  WHERE i.status = 3
    AND (i.create_at + a.max_delivery_frequency::interval) > now() at time zone 'utc';
