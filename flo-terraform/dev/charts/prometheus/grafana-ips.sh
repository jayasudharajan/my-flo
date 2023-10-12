#!/bin/bash

grafana_ip_list=($(curl https://grafana.com/api/hosted-grafana/source-ips.txt|sort -n|uniq))
total_ips="${#grafana_ip_list[@]}"

echo "## Total IPs to add to Security Groups: ${total_ips}"

i=1
for ip in "${grafana_ip_list[@]}"
do
  cidr="${ip}/32"
  printf "%s," "${cidr}"
  if [ $(($i%5)) -eq 0 ]
  then
    echo
  fi
  i=$(($i+1))
done

