#!/usr/bin/env bash


function error_exit() {
  echo "$1" 1>&2
  exit 1
}


function check_deps() {
  test -f $(which aws) || error_exit "aws command not detected in path, please install it"
  test -f $(which jq) || error_exit "jq command not detected in path, please install it"
}

function find_alb_name() {
 target_alb=""
 pattern=$1
 for alb_name in $(aws elbv2 describe-load-balancers | jq -r '."LoadBalancers"[]."LoadBalancerArn"'); do
    if grep -q "$pattern" <<< "$alb_name"; then
        target_alb="$alb_name"
        break
    fi
 done
 echo "$target_alb";
}
check_deps
stdin=$(cat)
alb_pattern=$(echo $stdin | jq -r .alb_pattern)
export AWS_PROFILE=$(echo $stdin | jq -r .aws_profile)
alb_arn=$(find_alb_name ${alb_pattern})
jq -n --arg alb_arn "$alb_arn" \
  '{"alb_arn":$alb_arn}'

