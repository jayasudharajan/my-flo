alter table devices add column fw_health_test_on boolean;

create index idx_devices_lastheard_healthtest on devices (last_heard_from_time desc, fw_health_test_on) 
    where fw_health_test_on is not null;

create table if not exists devices_audit (
    device_id macaddr not null,
    requested timestamp without time zone not null default now(),
    account_id uuid,
    location_id uuid,    
    by_user_id uuid,
    fw_req JSON,
    fw_req_health_test_on boolean,
    fw_last_known JSON,
    primary key(device_id,requested)
);
create index idx_devices_audit_requested_healthtest on devices_audit (requested desc, fw_req_health_test_on) 
    where fw_req_health_test_on is not null;
create index idx_byuser on devices_audit (by_user_id) where by_user_id is not null;