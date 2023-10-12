#!/usr/bin/env bash
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

VAULT=$(which vault)
if [[ ! -x "$VAULT" ]]; then
    die "Vault binary was not found in your PATH. Please install vault"
fi


cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

users_map() {
  local users=$1
  local i=0
  local cnt=$(echo $users | wc -w)
  echo -n '{'
  echo "${users}" | while IFS= read -r u; do
    i=$(($i + 1))
    local pw=$(${VAULT} kv get -format json secret/common/database_users/$u | jq -r '.data.data.password')
    if [[ $i -ne $cnt ]]; then
        echo -n " ${u} = \"${pw}\", "
    else
        echo -n " ${u} = \"${pw}\" "
    fi
  done
  echo -n '}'

}
create_users() {
  local dbname=$1
  local users=$2
  local dbcreds=$(${VAULT} kv get -format json secret/common/databases/$dbname)
  export TF_VAR_postgresql_host=$(echo ${dbcreds} | jq -r '.data.data.host')
  export TF_VAR_postgresql_user=$(echo ${dbcreds} | jq -r '.data.data.username')
  export TF_VAR_postgresql_password=$(echo ${dbcreds} | jq -r '.data.data.password')
  export TF_VAR_postgresql_database=$dbname
  export TF_VAR_developers="$(users_map "$users")"
  terraform init
  terraform plan
  terraform apply -auto-approve

}

users=$(${VAULT} kv  list -format json secret/common/database_users/  | jq -r '.[]')
databases=$(${VAULT} kv  list -format json secret/common/databases/  | jq -r '.[]')

echo "${databases}" | while IFS= read -r line; do
    create_users "${line}" "${users}"
done