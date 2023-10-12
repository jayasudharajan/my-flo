#!/usr/bin/env bash
set -e

# Constants
export TILLER_NAMESPACE=kube-system

readonly BASE_DIR=$(eval "pwd")
readonly BASE_PATH="${BASE_DIR}"
readonly KOPS_CONFIG_FILE="deployment/values.yaml"
readonly SSHKEY=pub-key/id_rsa_kops
readonly TEMPLATES_DIR="templates"
readonly TERRAFORM_CONFIG_FILE=/tmp/config.tfvars
readonly TERRAFORM_CONFIG_FILE_PEERING=/tmp/config-peering.tfvars
readonly TERRAFORM_CONFIG_FILE_ROUTE53_ASSO=/tmp/config-route53-asso.tfvars
readonly TERRAFORM_CONFIG_FILE_NATGW_ELB_SEC=/tmp/config-natgw-elb-sec.tfvars
readonly TERRAFORM_DIRECTORY=terraform
readonly TERRAFORM_OUTPUT_PATH="/tmp/terraform_output.json"

# TODO: update all Terraform/Kops actions to base off of environment path
# TODO: DO NOT IGNORE local terraform state, lets make sure that is either committed to git or S3
# TODO: Move TF init/refresh/plan/apply to a function, that code is repeated often
pushd() {
  command pushd "$@" > /dev/null
}

popd() {
  command popd "$@" > /dev/null
}

try() {
    [[ $- = *e* ]]; SAVED_OPT_E=$?
    set +e
}

throw() {
    exit "${1}"
}

catch() {
    export ex_code=$?
    (( $SAVED_OPT_E )) && set +e
    return $ex_code
}

throwErrors() {
    set -e
}

ignoreErrors() {
    set +e
}

confirm() {
  read -p "Are you sure? " -n 1 -r
  echo    # (optional) move to a new line
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    exit 1
  fi
}

usage() {
  echo "usage: ${0} <dev|prod>"
  exit 1
}

_main_constants(){
  # Variables
  export YQ_READ_CONF="yq r ${BASE_DIR}/${ENVIRONMENT}/${KOPS_CONFIG_FILE}"

  export AWS_ACCOUNT=$(${YQ_READ_CONF} aws.accountId)
  export AWS_ACCOUNT_ID=$(${YQ_READ_CONF} aws.accountId)
  export AWS_PROFILE="flo-${ENVIRONMENT}"
  export AWS_REGION=$(${YQ_READ_CONF} aws.region)
  export AWS_DEFAULT_REGION="${AWS_REGION}"

  readonly CHILD_DNS=$(${YQ_READ_CONF} global.child_dns)
  readonly CREATE_MAIN_DNS=$(${YQ_READ_CONF} global.create_main_dns)
  readonly CREATE_CHILD_DNS=$(${YQ_READ_CONF} global.create_child_dns)
  readonly DEPLOYMENT=$(${YQ_READ_CONF} global.deployment)
  readonly DEPLOYMENT_CODE=$(${YQ_READ_CONF} global.deploymentCode)
  readonly DOMAIN=$(${YQ_READ_CONF} global.domain)
  readonly PROJECT=$(${YQ_READ_CONF} global.project)
  readonly ORGANISATION=$(${YQ_READ_CONF} global.organisation)
  readonly PROFILE=$(${YQ_READ_CONF} global.profile)
  readonly KOPS_CLUSTER_NAME=$(${YQ_READ_CONF} kubernetes.clusterName)
  readonly KOPS_STATE_STORE=$(${YQ_READ_CONF} kubernetes.stateStore)
  readonly K8S_SSH_KEY=$(${YQ_READ_CONF} kubernetes.sshKey)
  readonly TERRAFORM_BUCKET="${ORGANISATION}-terraform-state-${AWS_ACCOUNT}"
  readonly TERRAFORM_BUCKET_KEY="${AWS_REGION}/${PROJECT}/${DEPLOYMENT_CODE}/terraform.tfstate"
  readonly TERRAFORM_BUCKET_KEY_PREFIX="${AWS_REGION}/${PROJECT}/${DEPLOYMENT_CODE}"
  readonly TERRAFORM_PLAN_FILE="${ENVIRONMENT}.tfplan"

  # Debug
  # export -p
}

create_ssh_key() {
  echo "${FUNCNAME[0]}: Checking bastion/cluster SSH key"
  pushd "${BASE_DIR}/${ENVIRONMENT}"
  if [ ! -f "${SSHKEY}" ]; then
    echo "${FUNCNAME[0]}: Creating ssh key and uploading it to terraform bucket..."
    yes y | ssh-keygen -t rsa -f pub-key/id_rsa_kops -q -N '' >/dev/null
    cp pub-key/id_rsa_kops ~/.ssh
    aws s3 cp pub-key/id_rsa_kops "s3://${TERRAFORM_BUCKET}" --profile "${PROFILE}" >/dev/null
    rm -rf pub-key/id_rsa_kops
  else
    echo "${FUNCNAME[0]}: SSH Key is already generated"
  fi
  popd
}

_terraform_base_create_state() {
  pushd "${BASE_DIR}/${ENVIRONMENT}/${TERRAFORM_DIRECTORY}/base"
  echo "Generate Terraform Backend"
  (
    echo "terraform {"
    echo "  backend \"s3\" {"
    echo "    region = \"${AWS_REGION}\""
    echo "    bucket = \"${TERRAFORM_BUCKET}\""
    echo "    profile = \"${AWS_PROFILE}\""
    echo "    key    = \"${TERRAFORM_BUCKET_KEY_PREFIX}/base.tfstate\""
    echo "  }"
    echo "}"
    echo "provider \"aws\" {"
    echo "  profile = \"${AWS_PROFILE}\""
    echo "  region = \"${AWS_REGION}\""
    echo "}"
  ) > backend.tf
  popd
}

_terraform_base_check_dns_zone() {
  base_zone="$(echo ${KOPS_CLUSTER_NAME} | cut -d . -f 2-)"
  echo "${FUNCNAME[0]}: Checking Route53 for DNS zone '${base_zone}'"

  route53_base_zone=$(eval "aws route53 list-hosted-zones-by-name --dns-name ${base_zone} --profile ${PROFILE} | jq -c '.HostedZones[] | select(.Name == \"${base_zone}.\")'")
  create_main_dns='"true"'
  create_child_dns='"true"'

  if [ -n "${route53_base_zone}" ]; then
    echo "${FUNCNAME[0]}: DNS zone '${base_zone}' already exist skipping creation process"
    create_main_dns='"false"'
    zoneId="$(echo "${route53_base_zone}" | jq .Id | cut -c 14- | rev | cut -c 2- | rev)"
    echo "${FUNCNAME[0]}: ZoneId: ${zoneId}"
    yq w -i "${BASE_DIR}/${ENVIRONMENT}/deployment/values.yaml" aws.parentZoneId "${zoneId}"
    child_check=$(eval "aws route53 list-hosted-zones-by-name --dns-name ${ORGANISATION}.${DOMAIN} --profile ${PROFILE} | jq -c '.HostedZones[] | select(.Name == \"${CHILD_DNS}.${ORGANISATION}.${DOMAIN}.\")'")
    if [ -n "${child_check}" ]; then
      create_child_dns='"false"'
    fi
  fi
  export route53_base_zone
}

_terraform_base_update_subnets() {
  pushd "${BASE_DIR}/${ENVIRONMENT}"
  pushd "${TERRAFORM_DIRECTORY}/base"
  private_cidr1="$(terraform output -json kops_vpc_private_subnet_cidrs | jq '.value[0]')"
  private_cidr2="$(terraform output -json kops_vpc_private_subnet_cidrs | jq '.value[1]')"
  private_cidr3="$(terraform output -json kops_vpc_private_subnet_cidrs | jq '.value[2]')"
  private_sb1="$(terraform output -json private_subnet_ids | jq '.value[0]')"
  private_sb2="$(terraform output -json private_subnet_ids | jq '.value[1]')"
  private_sb3="$(terraform output -json private_subnet_ids | jq '.value[2]')"

  public_cidr1="$(terraform output -json kops_vpc_public_subnet_cidrs | jq '.value[0]')"
  public_cidr2="$(terraform output -json kops_vpc_public_subnet_cidrs | jq '.value[1]')"
  public_cidr3="$(terraform output -json kops_vpc_public_subnet_cidrs | jq '.value[2]')"
  public_sb1="$(terraform output -json public_subnet_ids | jq '.value[0]')"
  public_sb2="$(terraform output -json public_subnet_ids | jq '.value[1]')"
  public_sb3="$(terraform output -json public_subnet_ids | jq '.value[2]')"
  popd

  echo "${FUNCNAME[0]}: Writing subnets to YAML file"
  cat << EOF > deployment/subnets.yaml
subnets:
- {"name": "private-us-west-2a", "zone": "us-west-2a", "cidr": ${private_cidr1}, "type": "Private", "id": ${private_sb1}}
- {"name": "private-us-west-2b", "zone": "us-west-2b", "cidr": ${private_cidr2}, "type": "Private", "id": ${private_sb2}}
- {"name": "private-us-west-2c", "zone": "us-west-2c", "cidr": ${private_cidr3}, "type": "Private", "id": ${private_sb3}}
- {"name": "public-us-west-2a", "zone": "us-west-2a", "cidr": ${public_cidr1}, "type": "Utility", "id": ${public_sb1}}
- {"name": "public-us-west-2b", "zone": "us-west-2b", "cidr": ${public_cidr2}, "type": "Utility", "id": ${public_sb2}}
- {"name": "public-us-west-2c", "zone": "us-west-2c", "cidr": ${public_cidr3}, "type": "Utility", "id": ${public_sb3}}
EOF
  export KOPS_SUBNETS_FILE=deployment/subnets.yaml
  echo "${FUNCNAME[0]}: Subnet written to YAML file: '${KOPS_SUBNETS_FILE}'"
  popd
}

_terraform_base_update_values_dns() {
  pushd "${BASE_DIR}/${ENVIRONMENT}"
  echo "${FUNCNAME[0]}: Updating global.create_main_dns"
  yq w -i "deployment/values.yaml" global.create_main_dns "${create_main_dns}"
  echo "${FUNCNAME[0]}: Updating global.create_child_dns"
  yq w -i "deployment/values.yaml" global.create_child_dns "${create_child_dns}"
  popd
}

_terraform_base_retrieve_vpc_props() {
  pushd "${BASE_DIR}/${ENVIRONMENT}/${TERRAFORM_DIRECTORY}/base"
  organisation_cert_arn="$(terraform output -json kops_acm_id | jq '.value')"
  readonly ORGANISATION_CERT_ARN="${organisation_cert_arn}"

  # TODO: Why are we doing this again??
  if [ -n "${route53_base_zone}" ]; then
      echo "DNS zone already exist skippin creation process"
      create_main_dns='"false"'
      zoneId="$(echo "${route53_base_zone}" | jq .Id | cut -c 14- | rev | cut -c 2- | rev)"
      echo "ZoneId: ${zoneId}"
  else
      zoneId="$(terraform output -json kops_zone_id | jq '.value')"
      echo "ZoneId: ${zoneId}"

  fi

  vpcId="$(terraform output -json kops_vpc_id | jq '.value')"
  natGatewayId="$(terraform output  -json kops_nat_gateway_id | jq '.value[0]')"

  export natGatewayId
  export vpcId
  export zoneId
  popd
}

_terraform_base_update_values_vpc() {
  pushd "${BASE_DIR}/${ENVIRONMENT}"
  echo "${FUNCNAME[0]}: updating global.vpcId"
  yq w -i "deployment/values.yaml" global.vpcId "${vpcId}"
  echo "${FUNCNAME[0]}: updating global.parentZoneId"
  yq w -i "deployment/values.yaml" global.parentZoneId "${zoneId}"
  echo "${FUNCNAME[0]}: updating global.parentZoneId"
  yq w -i "deployment/values.yaml" global.natgatewayId "${natGatewayId}"
  popd
}

_terraform_base_create_config() {
  pushd "${BASE_DIR}/${ENVIRONMENT}"
  echo "${FUNCNAME[0]}: Generating Terraform config file: ${TERRAFORM_CONFIG_FILE}"
  yq r -j ${KOPS_CONFIG_FILE} > ${TERRAFORM_CONFIG_FILE}
  popd
}

# TODO: This function is still too big, break it up more
terraform_base() {
  echo "${FUNCNAME[0]}: Terraform Remote State Bucket: ${TERRAFORM_BUCKET}"
  pushd "${BASE_DIR}/${ENVIRONMENT}/${TERRAFORM_DIRECTORY}/base"

  _terraform_base_create_state
  _terraform_base_check_dns_zone
  _terraform_base_update_values_dns
  _terraform_base_create_config

  echo "${FUNCNAME[0]}: Initialize Terraform, set state and plan"
  set -x
  terraform init -var-file ${TERRAFORM_CONFIG_FILE}
  terraform refresh -var-file ${TERRAFORM_CONFIG_FILE}
  terraform plan \
    -var-file ${TERRAFORM_CONFIG_FILE} \
    -out "${KOPS_CLUSTER_NAME}.tfplan" \
    "${@}"
  echo "${FUNCNAME[0]}: terraform apply ${KOPS_CLUSTER_NAME}.tfplan"
  confirm
  terraform apply "${KOPS_CLUSTER_NAME}.tfplan"
  # terraform destroy -var-file ${TERRAFORM_CONFIG_FILE}  # DANGEROUS!!!
  set +x
  echo "${FUNCNAME[0]}: Terraform Plan Applied"
  popd

  _terraform_base_retrieve_vpc_props
  _terraform_base_update_values_vpc
  _terraform_base_update_subnets
}

_vpc_peering_create_config() {
  echo "${FUNCNAME[0]}: Create ${TERRAFORM_CONFIG_FILE_PEERING}"
  pushd "${BASE_DIR}/${ENVIRONMENT}"
  yq r -j ${KOPS_CONFIG_FILE} > ${TERRAFORM_CONFIG_FILE_PEERING}
  popd
}

_vpc_peering_create_tf_backend() {
  echo "${FUNCNAME[0]}: Create Terraform VPC Peering backend"
  pushd "${BASE_DIR}/${ENVIRONMENT}/${TERRAFORM_DIRECTORY}/vpc-peering"
  (
    echo "terraform {"
    echo "  backend \"s3\" {"
    echo "    region = \"${AWS_REGION}\""
    echo "    bucket = \"${TERRAFORM_BUCKET}\""
    echo "    profile = \"${AWS_PROFILE}\""
    echo "    key    = \"${TERRAFORM_BUCKET_KEY_PREFIX}/peering.tfstate\""
    echo "  }"
    echo "}"
    echo "provider \"aws\" {"
    echo "  profile = \"${AWS_PROFILE}\""
    echo "  region = \"${AWS_REGION}\""
    echo "}"
  ) > backend.tf
  popd
}

vpc_peering() {
  _vpc_peering_create_config
  _vpc_peering_create_tf_backend

  pushd "${BASE_DIR}/${ENVIRONMENT}/${TERRAFORM_DIRECTORY}/vpc-peering"
  set -x
  terraform init \
    -var-file ${TERRAFORM_CONFIG_FILE_PEERING} \
    -backend-config="region=${AWS_REGION}" \
    -backend-config="bucket=${TERRAFORM_BUCKET}" \
    -backend-config="key=${TERRAFORM_BUCKET_KEY_PREFIX}/peering.tfstate"
  terraform refresh -var-file ${TERRAFORM_CONFIG_FILE_PEERING}
  terraform plan \
    -var-file ${TERRAFORM_CONFIG_FILE_PEERING} \
    -out peering.tfplan \
    "${@}"
  echo "${FUNCNAME[0]}: terraform apply peering.tfplan"
  confirm
  terraform apply peering.tfplan
  set +x

  popd
}

_route53_association_create_config() {
  pushd "${BASE_DIR}/${ENVIRONMENT}"
  yq r -j ${KOPS_CONFIG_FILE} > ${TERRAFORM_CONFIG_FILE_ROUTE53_ASSO}
  popd
}

_route53_association_create_tf_backend() {
  pushd "${BASE_PATH}/${ENVIRONMENT}/${TERRAFORM_DIRECTORY}/route53-association"
  (
      echo "terraform {"
      echo "  backend \"s3\" {"
      echo "    region = \"${AWS_REGION}\""
      echo "    bucket = \"${TERRAFORM_BUCKET}\""
      echo "    profile = \"${AWS_PROFILE}\""
      echo "    key    = \"${TERRAFORM_BUCKET_KEY_PREFIX}/route53_association.tfstate\""
      echo "  }"
      echo "}"
      echo "provider \"aws\" {"
      echo "  profile = \"${AWS_PROFILE}\""
      echo "  region = \"${AWS_REGION}\""
      echo "}"
  ) > backend.tf
  popd
}

route53_association(){
  _route53_association_create_config
  _route53_association_create_tf_backend

  pushd "${BASE_PATH}/${ENVIRONMENT}/${TERRAFORM_DIRECTORY}/route53-association"
  set -x
  terraform init \
    -var-file ${TERRAFORM_CONFIG_FILE_ROUTE53_ASSO} \
    -backend-config="region=${AWS_REGION}" \
    -backend-config="bucket=${TERRAFORM_BUCKET}" \
    -backend-config="key=${TERRAFORM_BUCKET_KEY_PREFIX}/route53_association.tfstate"
  terraform plan \
    -var-file ${TERRAFORM_CONFIG_FILE_ROUTE53_ASSO} \
    -out route53_association.tfplan \
    "${@}"
  echo "${FUNCNAME[0]}: terraform apply route53_association.tfplan"
  terraform apply route53_association.tfplan
  set +x
  popd
}

_kops_create_generate_cluster_yaml() {
  pushd "${BASE_PATH}/${ENVIRONMENT}"
  export KOPS_SUBNETS_FILE=deployment/subnets.yaml

  echo "${FUNCNAME[0]}: kops generate cluster.yaml"
  kops toolbox template \
    --values ${KOPS_CONFIG_FILE} \
    --values ${KOPS_SUBNETS_FILE} \
    --template templates/cluster/cluster.yaml \
    --template templates/cluster/master.yaml \
    --template templates/cluster/nodes.yaml \
    --template templates/cluster/bastion.yaml \
    --format-yaml \
    --output /tmp/cluster.yaml
  cat /tmp/cluster.yaml
  echo "${FUNCNAME[0]}: kops replace cluster resources in cluster.yaml"
  kops replace \
    --filename /tmp/cluster.yaml \
    --state "${KOPS_STATE_STORE}" \
    # --force \
    "${@}"
  popd
}

_kops_create_cluster_create_tf_backend() {
  pushd "${BASE_PATH}/${ENVIRONMENT}/terraform/kubernetes"
  (
      echo "terraform {"
      echo "  backend \"s3\" {"
      echo "    region = \"${AWS_REGION}\""
      echo "    bucket = \"${TERRAFORM_BUCKET}\""
      echo "    key    = \"${TERRAFORM_BUCKET_KEY_PREFIX}/kubernetes.tfstate\""
      echo "    profile = \"${PROFILE}\""
      echo "  }"
      echo "}"
  ) > backend.tf
  popd
}

_kops_create_cluster_create_secrets() {
  local s3path="${KOPS_STATE_STORE}/${KOPS_CLUSTER_NAME}/pki/ssh/public/admin/"

  pushd "${BASE_PATH}/${ENVIRONMENT}"
  echo "${FUNCNAME[0]}: S3 Path: ${s3path}"

  try
  (
  s3ls=$(eval "aws s3 ls $s3path")
  if [ -z "${s3ls}" ]; then
    echo "encryption_key: $(head -c32 /dev/urandom | base64)" > /tmp/encryption.values
    gotpl templates/encryption.yaml < /tmp/encryption.values > /tmp/encryption.yaml
    kops create secret \
      encryptionconfig \
      --name "${KOPS_CLUSTER_NAME}" \
      -f /tmp/encryption.yaml \
      --force
    kops create secret \
      sshpublickey admin \
      --name ${KOPS_CLUSTER_NAME} \
      --pubkey "pub-key/${K8S_SSH_KEY}"
  else
    echo "SSH key for admin already created skippin creation process"
  fi
  )
  catch || {
      # now you can handle
      case $ex_code in
          $AnException)
              echo "AnException was thrown"
          ;;
          $AnotherException)
              echo "AnotherException was thrown"
          ;;
          *)
              echo "An unexpected exception was thrown"
              throw $ex_code # you can rethrow the "exception" causing the script to exit if not caught
          ;;
      esac
  }
  popd
}

_kops_create_update_cluster() {
  pushd "${BASE_PATH}/${ENVIRONMENT}"

  if [[ -n "${KOPS_UPGRADE_CLUSTER}" ]]; then
    echo "${FUNCNAME[0]}: kops upgrade cluster - Upgrades Kubernetes versions"
    echo kops upgrade cluster --yes
  fi
  echo "${FUNCNAME[0]}: kops update cluster"
  set -x
  kops update cluster --name "${KOPS_CLUSTER_NAME}" \
    --state "${KOPS_STATE_STORE}" \
    --target terraform \
    --out terraform/kubernetes
  kops export kubecfg \
    --state "${KOPS_STATE_STORE}"
  set +x
  popd
}

kops_create_cluster() {
  _kops_create_generate_cluster_yaml
  _kops_create_update_cluster
  _kops_create_cluster_create_tf_backend

  pushd "${BASE_PATH}/${ENVIRONMENT}/terraform/kubernetes"
  echo "${FUNCNAME[0]}: Terraform plan and refresh"
  set -x
  terraform init -var-file ${TERRAFORM_CONFIG_FILE}
  terraform refresh -var-file ${TERRAFORM_CONFIG_FILE}
  terraform plan \
    -var-file ${TERRAFORM_CONFIG_FILE} \
    -out "${KOPS_CLUSTER_NAME}.tfplan" \
    "${@}"
  echo "${FUNCNAME[0]}: Terraform apply"
  confirm
  terraform apply "${KOPS_CLUSTER_NAME}.tfplan"
  echo "${FUNCNAME[0]}: kops rolling-update"
  confirm
  kops rolling-update cluster \
    --name "${KOPS_CLUSTER_NAME}" \
    --state "${KOPS_STATE_STORE}" \
    --yes
  set +x

  popd
}

helm_initialize_nginx_ingress(){
  pushd "${BASE_PATH}/${ENVIRONMENT}"

  helm init --wait

  echo "Waiting for tiller initialization!"
  sleep 20

  # TODO: Replace this create command and just apply a fixed template
  echo kubectl create \
    clusterrolebinding admin-binding \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:default || true

  # TODO: function for helm upgrade/status
  set -x
  # helm repo list
  # helm repo update --debug
  helm upgrade \
    nginx-ingress kloia/nginx-ingress \
    --namespace nginx-ingress \
    --dry-run \
    --debug \
    --values nginx-values.yaml \
    --version 0.0.3 \
    --set cert="${ORGANISATION_CERT_ARN}" \
    --set controller.replicaCount=3 \
    --wait
  helm upgrade \
    metrics-server ./charts/metrics-server \
    --namespace kube-system \
    --dry-run \
    --install \
    --debug \
    --wait
  set +x
  popd
}

# peering
# kops terraform remove
# kops delete
# route53 asso
# base terraform

# destroy_cluster() {
#     printf "\n\n${ERROR_COLOUR}Are you 100%% certain you want to destroy the ${K8S_CLUSTER_NAME} platform? (y/n): ${NO_COLOUR}"
#     read -n1 CONFIRM_DESTROY
#     if [[ "${CONFIRM_DESTROY}" != "y" ]]; then
#         echo "\nCancelling Teardown\n"
#         exit 1
#     fi
#     header "Starting destruction of ${K8S_CLUSTER_NAME}"
#     cd terraform/${DESTRUCTION_TARGET}
#     terraform_${DESTRUCTION_TARGET} -destroy
#
#     header "Deleting Kops configuration for \"${K8S_CLUSTER_NAME}\""
#     kops delete cluster --yes ${K8S_CLUSTER_NAME}
#
#     header "Deleting any leftover files from s3://${K8S_CLUSTER_STATE_BUCKET}"
#     aws s3 rm --recursive s3://${K8S_CLUSTER_STATE_BUCKET}
#
#     header "Destroying \"base\""
#     cd ${TERRAFORM_DIRECTORY}/base
#     terraform_base -destroy
#
#     header "The cluster for \"${ENVIRONMENT_CONFIG}\" has been destroyed"
# }


install_ca() {

    echo "Install Cluster AutoScaler "

    helm install \
        stable/cluster-autoscaler \
        --name autoscaler \
        --namespace kube-system \
        --set image.tag=v1.2.2 \
        --set autoDiscovery.clusterName="${KOPS_CLUSTER_NAME}" \
        --set extraArgs.balance-similar-node-groups=false \
        --set extraArgs.expander=random \
        --set rbac.create=true \
        --set rbac.pspEnabled=true \
        --set awsRegion=us-west-2 \
        --set nodeSelector."node-role\.kubernetes\.io/master"="" \
        --set tolerations[0].effect=NoSchedule \
        --set tolerations[0].key=node-role.kubernetes.io/master \
        --set cloudProvider=aws

}

_natgw_elb_sec_create_tf_backend() {

  pushd "${BASE_PATH}/${ENVIRONMENT}/terraform/natgw-elb-sec"
  (
      echo "terraform {"
      echo "  backend \"s3\" {"
      echo "    region = \"${AWS_REGION}\""
      echo "    bucket = \"${TERRAFORM_BUCKET}\""
      echo "    key    = \"${TERRAFORM_BUCKET_KEY_PREFIX}/natgw-elb-sec.tfstate\""
      echo "    profile = \"${PROFILE}\""
      echo "  }"
      echo "}"
  ) > backend.tf
  popd
}

natgw_elb_sec() {
  pushd "${BASE_PATH}/${ENVIRONMENT}"
  yq r -j ${KOPS_CONFIG_FILE} > ${TERRAFORM_CONFIG_FILE_NATGW_ELB_SEC}

  _natgw_elb_sec_create_tf_backend

  set -x
  terraform init \
    -var-file ${TERRAFORM_CONFIG_FILE_NATGW_ELB_SEC} \
    -backend-config="region=${AWS_REGION}" \
    -backend-config="bucket=${TERRAFORM_BUCKET}" \
    -backend-config="key=${TERRAFORM_BUCKET_KEY_PREFIX}/natgw-elb-sec.tfstate"
  terraform plan \
    -var-file ${TERRAFORM_CONFIG_FILE_NATGW_ELB_SEC} \
    -out natgw-elb-sec.tfplan \
    "${@}"
  terraform apply natgw-elb-sec.tfplan
  set +x

  popd
}


instana_agent_implementation(){

    # TODO: This path does not yet exist in this repo
    # TODO: This path doesn't seem to exist in flo-infla either
    INSTANA_SECRET_SETUP="$(kubectl create -f _common/instana-secret.yaml)"
    INSTANA_AGENT_KEY="$(kubectl get secret instana-secrets -n instana-agent -o yaml > /tmp/instana-secret && yq r /tmp/instana-secret data.instana_key | base64 --decode )"

    export INSTANA_AGENT_KEY
    export INSTANA_SECRET_SETUP

    helm upgrade \
      instana-agent stable/instana-agent \
      --namespace instana-agent \
      --install \
      --set agent.key="${INSTANA_AGENT_KEY}" \
      --set agent.endpointHost=saas-us-west-2.instana.io \
      --set agent.endpointPort=443 \
      --set cluster.name=k8s.flocloud.co \
      --set zone.name=k8s.flocloud.co

}

# TODO: We don't use FluentD anymore, replace this with filebeat
logz_fluentd_deamonset(){

  LOGZ_API_KEY=$(kubectl get secret logz-secret -o yaml > /tmp/logz-secret && yq r /tmp/logz-secret  data.logz_api_key | base64 --decode)
  echo "updating spec.template.spec.containers[0].env[0].value"
  yq w -i -d3 logz-daemonset.yaml 'spec.template.spec.containers[0].env[0].value' "${LOGZ_API_KEY}"
  kubectl apply -f ${BASE_PATH}/charts/logz-daemonset.yaml
  #Workaround to accidentally push secret to code repository
  echo "updating spec.template.spec.containers[0].env[0].value"
  yq w -i -d3 logz-daemonset.yaml 'spec.template.spec.containers[0].env[0].value' '{{API_TOKEN}}'

}

main() {
  if [ "$#" -ne 1 ]; then
    usage
  else
    readonly ENVIRONMENT="${1}"
  fi
  _main_constants
  create_ssh_key
  terraform_base
  vpc_peering
  route53_association
  ### waiting for dns propagation
  kops_create_cluster
  ### cluster access
  helm_initialize_nginx_ingress
  echo install_ca
  natgw_elb_sec
  echo instana_agent_implementation
  dirs -c
}

main "$@"
