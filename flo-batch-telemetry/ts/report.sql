select device_id,count(0),sum(seconds) from water_5min
    where device_id in ('90e202cf7af0','90e2020b72c9','0cae7dc57c90')
      and bk >= '2022-08-07T00:00:00' and bk < '2022-08-08T00:00:00' group by device_id;
/*
+-------------------+-------+-------+
| device_id         | count | sum   |
|-------------------+-------+-------|
| 0c:ae:7d:c5:7c:90 | 288   | 86322 |
| 90:e2:02:0b:72:c9 | 288   | 86400 |
| 90:e2:02:cf:7a:f0 | 288   | 86400 |
+-------------------+-------+-------+
 */

-- extend timeout to 1hr for the query
SET statement_timeout = 3600000;

-- send this select stmt to local dir as csv for about 3K devices as a sample query
\copy (
    select REPLACE(device_id::text, ':', '') as mac,count(0) as chunks,sum(seconds) as seconds from water_5min
        where device_id >= '000000000000' and device_id < '010000000000'
            and bk >= '2022-08-07T00:00:00' and bk < '2022-08-08T00:00:00' group by mac
                limit 1000000
) to '~/telemetry/2022-08-07/mac_00_01.csv' with csv header;

-- send this select stmt to local dir as csv for all devices
\copy (
    select REPLACE(device_id::text, ':', '') as mac,count(0) as chunks,sum(seconds) as seconds from water_5min
        where bk >= '2022-08-07T00:00:00' and bk < '2022-08-08T00:00:00' group by mac
                limit 1000000000
) to '~/telemetry/2022-08-07/all_macs2.csv' with csv header;

-- use csvq to query csv data