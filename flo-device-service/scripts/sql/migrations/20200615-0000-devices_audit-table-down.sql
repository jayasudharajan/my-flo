drop index idx_devices_lastheard_healthtest;

alter table devices drop column fw_health_test_on;

drop table devices_audit;