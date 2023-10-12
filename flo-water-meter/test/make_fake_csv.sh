#!/bin/bash

# NOTE: this script will generate 60 seconds worth of test data in v8 CSV, GZip it, then upload to S3 with the proper version name for testing purposes

DEVICES=${DEVICES:-10}
MACS=()
#populate fake mac addresses array
for ((i=1;i<=DEVICES;i++));
do
    uuid=$(uuidgen)
    mac=$(echo ${uuid//-/} | cut -c2-13)
    MACS+=( $mac )
done
# echo ${MACS[@]}
FN="data.csv"

ROWS=${ROWS:-288}
NOW_DT=$(date +%s)
HR_STR=$(date -r $NOW_DT +"%Y-%m-%d %H:00:00")
BUCKET_DT=$(date -j -f "%Y-%m-%d %T" "${HR_STR}" +%s)

# print header to csv file
# echo 'bucket,device_id,seconds,seconds_flo,seconds_slot,total_gallon,gpm_sum,gpm_min_flo,gpm_max,psi_sum,psi_min,psi_max,temp_sum,temp_min,temp_max' > $FN
rm -f $FN

ENTRIES=0
BSIZE=300
ALL_ZEROS=$(eval printf '0%.0s' {1..$BSIZE})
for (( i=1; i<=ROWS; i++ )); 
do
    BUCKET_STR=$(date -r $BUCKET_DT +"%Y-%m-%d %H:%M:%S")
    #echo $BUCKET_STR
    # +5min each loop itteration
    BUCKET_DT=$(( $BUCKET_DT + $BSIZE ))

    for m in ${MACS[@]}; 
    do
        gpm_avg=$(shuf -i 100-500 -n 1)
        gpm_avg=$(bc <<< "scale=2; $gpm_avg / 100")
        rdiff=$(shuf -i 10-100 -n 1)
        if [ $(( $RANDOM % 7 )) == 0 ]; then
            SEC_FLO=$(shuf -i 0-$BSIZE -n 1)
            GPM_SUM=$(bc <<< "scale=2; $gpm_avg * $SEC_FLO")
            TOTAL_G=$(bc <<< "scale=2; $gpm_avg * ($BSIZE / 60)")

            GPM_MIN_FLO=$(bc <<< "scale=2; $gpm_avg - ($rdiff / 100)")
            GPM_MAX=$(bc <<< "scale=2; $gpm_avg + ($rdiff / 100)")
        else
            SEC_FLO=0
            GPM_SUM=0
            TOTAL_G=0
            GPM_MIN_FLO=0
            GPM_MAX=0
        fi

        psi_avg=$(bc <<< "scale=2; $gpm_avg * 17.13")
        PSI_SUM=$(bc <<< "scale=2; $psi_avg * $BSIZE")
        PSI_MIN=$(bc <<< "scale=2; $psi_avg - ($rdiff / 11)")
        PSI_MAX=$(bc <<< "scale=2; $psi_avg + (($rdiff / 11) * 3.7)")

        TEMP_SUM=$(bc <<< "scale=1; $PSI_SUM + $BSIZE")
        TEMP_MIN=$(bc <<< "scale=1; $PSI_MIN - 1.1")
        TEMP_MAX=$(bc <<< "scale=1; $PSI_MAX + 0.9")

        # build SEC_BIT mapping
        if (( SEC_FLO > 0 )); then
            SEC_BIT=$(eval printf '1%.0s' {1..$SEC_FLO})
            zlen=$(( $BSIZE - $SEC_FLO ))
            if (( zlen > 0 )); then
                SEC_BIT+=$(eval printf '0%.0s' {1..$zlen})
            fi
        else
            SEC_BIT=$ALL_ZEROS
        fi

        _bucket="${BUCKET_STR},${m},${BSIZE},${SEC_FLO},${SEC_BIT}"
        _gpm="${TOTAL_G},${GPM_SUM},${GPM_MIN_FLO},${GPM_MAX}"
        _psi="${PSI_SUM},${PSI_MIN},${PSI_MAX}"
        _tempa="${TEMP_SUM},${TEMP_MIN},${TEMP_MAX}"

        # print row to csv file
        echo "${_bucket},${_gpm},${_psi},${_tempa}" >> $FN
        ENTRIES=$(( $ENTRIES + 1 ))
        
        if (( ENTRIES % 100 == 0 )); then
            echo "${ENTRIES} generated..."
        fi
    done
done
echo "Total Entries: ${ENTRIES} @ ${FN}"

# psql postgres://x.y.z < schema.sql
# psql postgres://x.y.z -c "\COPY water_5min FROM data.csv CSV"
# REFRESH MATERIALIZED VIEW water_hourly;
# \di+ did_bk_ux
# \di+ bk_ix