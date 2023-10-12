#!/bin/bash

if [[ $1 != *".sql"* ]]; then
    echo "Missing schema input: *.sql"
    exit 1
fi

go get github.com/timescale/timescaledb-parallel-copy/cmd/timescaledb-parallel-copy

NOW=$(date +%s)
FN=$(date -r $NOW +"run.$1.%Y%m%d_%H%M%S.txt")

CONN=${CONN:-'postgres://tsdbadmin:jl60n6blr9vqny9v@tsdb-168dc9d0-flo-dev.a.timescaledb.io:16627/defaultdb?sslmode=require'}
echo "Bootstrap using $1" | tee -a $FN
psql $CONN < $1 | tee -a $FN

START=$(date +%s)
echo "Started ${START}" | tee -a $FN
#psql $CONN -c "\COPY water_5min FROM data.csv CSV" | tee -a $FN
~/go/bin/timescaledb-parallel-copy --connection $CONN --table water_5min --file data.csv --workers 4 --reporting-period 10s
DONE=$(date +%s)
echo "Completed ${DONE}" | tee -a $FN
DIFF=$(( $DONE - $START ))
echo "Took ${DIFF}" | tee -a $FN

psql $CONN -abc "analyze water_5min;" | tee -a $FN
psql $CONN -abc "REFRESH MATERIALIZED VIEW water_hourly;" | tee -a $FN
psql $CONN -abc "REFRESH MATERIALIZED VIEW water_daily;" | tee -a $FN
#psql $CONN -abc "\di+ brin*;"
psql $CONN -abc "\di+ water*;" | tee -a $FN
psql $CONN -o $FN.2 \
    -c "explain analyze select bk,device_id,seconds,seconds_flo,total_gallon,gpm_min_flo,gpm_max from water_5min where bk >= '2020-02-14' and device_id='fc:c9:70:68:bd:34' limit 3;" \
    -c "explain analyze select bk,device_id,seconds,seconds_flo,total_gallon,gpm_min_flo,gpm_max from water_5min where bk >= '2020-02-14' and device_id='71:8d:3f:b4:9a:14' limit 3;" \
    -c "explain analyze select bk,device_id,seconds,seconds_flo,total_gallon,gpm_min_flo,gpm_max from water_5min where bk >= '2020-02-14' and device_id='71:8d:3f:b4:9a:14' limit 3;" \
    -c "explain analyze select bk,device_id,seconds,seconds_flo,total_gallon,gpm_min_flo,gpm_max from water_5min where bk >= '2020-02-14' limit 3;" \
    -c "explain analyze select bk,device_id,seconds,seconds_flo,total_gallon,gpm_min_flo,gpm_max from water_5min where bk >= '2020-02-14' limit 3;" \
    -c "explain analyze select bk,device_id,seconds,seconds_flo,total_gallon,gpm_min_flo,gpm_max from water_5min where device_id='71:8d:3f:b4:9a:14' limit 3;" \
    -c "explain analyze select bk,device_id,seconds,seconds_flo,total_gallon,gpm_min_flo,gpm_max from water_5min where device_id='71:8d:3f:b4:9a:14' limit 3;"
cat $FN.2 | tee -a $FN
rm -f $FN.2