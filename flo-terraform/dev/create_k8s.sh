#!/usr/bin/env bash
set -e

export AWS_PROFILE=flo
export KOPS_CONFIG_FILE=deployment/values.yaml
export TERRAFORM_CONFIG_FILE=/tmp/config.tfvars
export TERRAFORM_CONFIG_FILE_PEERING=/tmp/config-peering.tfvars
export TERRAFORM_CONFIG_FILE_ROUTE53_ASSO=/tmp/config-route53-asso.tfvars
export TERRAFORM_CONFIG_FILE_NATGW_ELB_SEC=/tmp/config-natgw-elb-sec.tfvars
export YQ_CMD="yq r ${KOPS_CONFIG_FILE}"
export TEMPLATES_DIR=/templates
export DEPLOYMENT=$(${YQ_CMD} global.deployment)
export DEPLOYMENT_CODE=$(${YQ_CMD} global.deploymentCode)
export PROJECT=$(${YQ_CMD} global.project)
export ORGANISATION=$(${YQ_CMD} global.organisation)
export PROFILE=$(${YQ_CMD} global.profile)
export DOMAIN=$(${YQ_CMD} global.domain)
export CREATE_MAIN_DNS=$(${YQ_CMD} global.create_main_dns)
export CREATE_CHILD_DNS=$(${YQ_CMD} global.create_child_dns)
export CHILD_DNS=$(${YQ_CMD} global.child_dns)
export PARENT_DNS="$(${YQ_CMD} global.parentZoneName)"
export AWS_ACCOUNT=$(${YQ_CMD} aws.accountId)
export AWS_ACCOUNT_ID=$(${YQ_CMD} aws.accountId)
export AWS_REGION=$(${YQ_CMD} aws.region)
export AWS_DEFAULT_REGION=${AWS_REGION}
export TERRAFORM_DIRECTORY=terraform
export TERRAFORM_OUTPUT_PATH="/tmp/terraform_output.json"
export TERRAFORM_BUCKET="$(${YQ_CMD} global.bucket)"
export TERRAFORM_BUCKET_KEY="${AWS_REGION}/${PROJECT}/${DEPLOYMENT_CODE}/terraform.tfstate"
export TERRAFORM_BUCKET_KEY_PREFIX="${AWS_REGION}/${PROJECT}/${DEPLOYMENT_CODE}"
export TERRAFORM_PLAN_FILE="${ENVIRONMENT}.tfplan"
export KOPS_CLUSTER_NAME=$(${YQ_CMD} kubernetes.clusterName)
export KOPS_STATE_STORE=$(${YQ_CMD} kubernetes.stateStore)
export K8S_SSH_KEY=$(${YQ_CMD} kubernetes.sshKey)
export TILLER_NAMESPACE=kube-system
export SSHKEY=pub-key/id_rsa_kops
export BASE_PATH=$(eval "pwd")


function try()
{
    [[ $- = *e* ]]; SAVED_OPT_E=$?
    set +e
}

function throw()
{
    exit $1
}

function catch()
{
    export ex_code=$?
    (( $SAVED_OPT_E )) && set +e
    return $ex_code
}

function throwErrors()
{
    set -e
}

function ignoreErrors()
{
    set +e
}

function log()
{
  printf "$(date "+%Y-%m-%d %H:%M:%S%z") - ${FUNCNAME[1]} - %s\n" "${1}"
}

function prompt()
{
  prompt="${1} [y/N]"
  read -r -p "${prompt}\n" resp
  case "${resp}" in
    [yY][eE][sS]|[yY])
      eval $(printf "%q" "${@:2}")
      ;;
    *)
      return 0
      ;;
  esac
}


echo $TERRAFORM_BUCKET

create_ssh_key() {
  if [ ! -f ${SSHKEY} ]; then
    echo "Creating ssh key and uploading it to terraform bucket..."
    yes y | ssh-keygen -t rsa -f pub-key/id_rsa_kops -q -N '' >/dev/null
    cp pub-key/id_rsa_kops ~/.ssh
    aws s3 cp pub-key/id_rsa_kops s3://${TERRAFORM_BUCKET} --profile ${PROFILE} >/dev/null
    rm -rf pub-key/id_rsa_kops
  else
    echo "SSH Key is already generated"
  fi
}

terraform_base() {
    cd ${TERRAFORM_DIRECTORY}/base
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

    output=$(eval "aws route53 list-hosted-zones-by-name --dns-name ${PARENT_DNS} --profile ${PROFILE} | jq -c '.HostedZones[] | select(.Name == \"${PARENT_DNS}.\")'")
    create_main_dns="\"true\""
    create_child_dns="\"true\""
    if [ -n "${output}" ]; then
        log "DNS zone already exist skippin creation process"
        create_main_dns="\"false\""
        echo $output | jq .Id | cut -c 14- | rev | cut -c 2- | rev > temp.txt
        zoneId=`cat temp.txt`
        log "Zone ID: ${zoneId}"
        [ "$(yq r ../../deployment/values.yaml aws.parentZoneId)" != "${zoneId}" ] && yq w -i ../../deployment/values.yaml aws.parentZoneId "${zoneId}"
        child_check=$(eval "aws route53 list-hosted-zones-by-name --dns-name ${PARENT_DNS} --profile ${PROFILE} | jq -c '.HostedZones[] | select(.Name == \"${CHILD_DNS}.${PARENT_DNS}.\")'")
        if [ -n "${child_check}" ]; then
            create_child_dns="\"false\""
            childZoneId="$(echo ${child_check} | jq .Id | cut -c 14- | rev | cut -c 2- | rev)"
        fi
    fi

    if [ "$(yq r ../../deployment/values.yaml global.create_main_dns)" != "${create_main_dns}" ]; then
      echo "updating global.create_main_dns"
      echo yq w -i ../../deployment/values.yaml global.create_main_dns "${create_main_dns}"
    fi
    if [ "$(yq r ../../deployment/values.yaml global.create_child_dns)" != "${create_child_dns}" ]; then
      echo "updating global.create_child_dns"
      echo yq w -i ../../deployment/values.yaml global.create_child_dns "${create_child_dns}"
    fi

    yq r -j ../../${KOPS_CONFIG_FILE} > ${TERRAFORM_CONFIG_FILE}

    log "Terraform Init"
    terraform init -var-file ${TERRAFORM_CONFIG_FILE}
    # log "Terraform - Refresh"
    # terraform refresh -var-file ${TERRAFORM_CONFIG_FILE}
    log "Terraform Plan"
    terraform plan -var-file ${TERRAFORM_CONFIG_FILE} -out ${KOPS_CLUSTER_NAME}.tfplan $@
    log "Terraform Apply"
    terraform apply ${KOPS_CLUSTER_NAME}.tfplan && \
      log "Terraform Changes Applied"
    #terraform destroy -var-file ${TERRAFORM_CONFIG_FILE}

    private_cidr1=$(terraform output -json kops_vpc_private_subnet_cidrs | jq '.value[0]')
    private_cidr2=$(terraform output -json kops_vpc_private_subnet_cidrs | jq '.value[1]')
    private_cidr3=$(terraform output -json kops_vpc_private_subnet_cidrs | jq '.value[2]')
    private_sb1=$(terraform output -json private_subnet_ids | jq '.value[0]')
    private_sb2=$(terraform output -json private_subnet_ids | jq '.value[1]')
    private_sb3=$(terraform output -json private_subnet_ids | jq '.value[2]')

    public_cidr1=$(terraform output -json kops_vpc_public_subnet_cidrs | jq '.value[0]')
    public_cidr2=$(terraform output -json kops_vpc_public_subnet_cidrs | jq '.value[1]')
    public_cidr3=$(terraform output -json kops_vpc_public_subnet_cidrs | jq '.value[2]')
    public_sb1=$(terraform output -json public_subnet_ids | jq '.value[0]')
    public_sb2=$(terraform output -json public_subnet_ids | jq '.value[1]')
    public_sb3=$(terraform output -json public_subnet_ids | jq '.value[2]')


    organisation_cert_arn=$(terraform output -json kops_acm_id | jq '.value')
    export ORGANISATION_CERT_ARN=${organisation_cert_arn}
    export NAT_GATEWAY_ID=$(terraform output  -json kops_nat_gateway_id | jq '.value[0]')

    if [ -n "${output}" ]; then
        echo "DNS zone already exist skippin creation process"
        create_main_dns="\"false"\"
        zoneId=$output | jq .Id | cut -c 14- | rev | cut -c 2- | rev
        echo $zoneId
    else
        zoneId=$(terraform output -json kops_zone_id | jq '.value')
        echo $zoneId

    fi
    vpcId=$(terraform output -json kops_vpc_id | jq '.value')
    cd ../../

    log "updating values.yaml - global.vpcId"
    yq w -i deployment/values.yaml global.vpcId "${vpcId}"
    log "updating values.yaml - global.parentZoneId"
    yq w -i deployment/values.yaml global.parentZoneId "${zoneId}"
    log "Base - updating values.yaml - global.natgatewayId"
    yq w -i deployment/values.yaml global.natgatewayId "${NAT_GATEWAY_ID}"


    log "updating subnets.yaml"
    echo '''
subnets:
- {"name": "peering-us-west-2a", "zone": "us-west-2a", "cidr": '10.0.200.0/24', "type": "Private", "id":'subnet-095108c660f0b2e65'}
- {"name": "private-us-west-2a", "zone": "us-west-2a", "cidr": '$private_cidr1', "type": "Private", "id":'$private_sb1'}
- {"name": "private-us-west-2b", "zone": "us-west-2b", "cidr": '$private_cidr2', "type": "Private", "id":'$private_sb2'}
- {"name": "private-us-west-2c", "zone": "us-west-2c", "cidr": '$private_cidr3', "type": "Private", "id":'$private_sb3'}
- {"name": "public-us-west-2a", "zone": "us-west-2a", "cidr": '$public_cidr1', "type": "Utility", "id":'$public_sb1'}
- {"name": "public-us-west-2b", "zone": "us-west-2b", "cidr": '$public_cidr2', "type": "Utility", "id":'$public_sb2'}
- {"name": "public-us-west-2c", "zone": "us-west-2c", "cidr": '$public_cidr3', "type": "Utility", "id":'$public_sb3'}
    ''' > deployment/subnets.yaml
    export KOPS_SUBNETS_FILE=deployment/subnets.yaml
    log "Subnets written to YAML config file"
}

vpc_peering() {
    cd ${BASE_PATH}
    yq r -j ${KOPS_CONFIG_FILE} > ${TERRAFORM_CONFIG_FILE_PEERING}

    cd ${BASE_PATH}/${TERRAFORM_DIRECTORY}/vpc-peering
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

    log "Terraform - Init"
    terraform init -var-file ${TERRAFORM_CONFIG_FILE_PEERING} \
      -backend-config="region=${AWS_REGION}" \
      -backend-config="bucket=${TERRAFORM_BUCKET}" \
      -backend-config="key=${TERRAFORM_BUCKET_KEY_PREFIX}/peering.tfstate"
    log "Terraform - Plan"
    terraform plan -var-file ${TERRAFORM_CONFIG_FILE_PEERING} -out peering.tfplan $@
    log "Terraform - Apply"
    terraform apply peering.tfplan && \
      log "Terraform Changes Applied"

    cd ../../

}


route53_association(){

    cd ${BASE_PATH}
    yq r -j ${KOPS_CONFIG_FILE} > ${TERRAFORM_CONFIG_FILE_ROUTE53_ASSO}

    cd ${BASE_PATH}/${TERRAFORM_DIRECTORY}/route53-association
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

    log "Terraform - Route53 - Init"
    terraform init -var-file ${TERRAFORM_CONFIG_FILE_ROUTE53_ASSO} \
      -backend-config="region=${AWS_REGION}" \
      -backend-config="bucket=${TERRAFORM_BUCKET}" \
      -backend-config="key=${TERRAFORM_BUCKET_KEY_PREFIX}/route53_association.tfstate"

    log "Terraform - Route53 - Plan"
    terraform plan -var-file ${TERRAFORM_CONFIG_FILE_ROUTE53_ASSO} -out route53_association.tfplan $@
    log "Terraform - Route53 - Apply"
    terraform apply route53_association.tfplan

    cd ../../

}


kops_create_cluster() {

    cd ${BASE_PATH}
    export KOPS_SUBNETS_FILE=deployment/subnets.yaml

    log "kops - Generate Cluster Config"
    kops toolbox template \
      --values ${KOPS_CONFIG_FILE} \
      --values ${KOPS_SUBNETS_FILE} \
      --template templates/cluster/cluster.yaml \
      --template templates/cluster/master.yaml \
      --template templates/cluster/nodes.yaml \
      --template templates/cluster/bastion.yaml \
      --format-yaml \
      --output /tmp/cluster.yaml

    log "kops - Review current cluster configuration"
    less /tmp/cluster.yaml

    log "kops - Replace"
    kops replace --force --filename /tmp/cluster.yaml || return 1

    s3path=${KOPS_STATE_STORE}/${KOPS_CLUSTER_NAME}"/pki/ssh/public/admin/"

    echo $s3path
    try
    (
    s3ls=$(eval "aws s3 ls $s3path")
    if [ -z "${s3ls}" ]; then
      echo encryption_key: $(head -c32 /dev/urandom | base64) > /tmp/encryption.values
      return 1  # Let's not mess around with accidentally overwriting the encryption vals
      gotpl templates/encryption.yaml < /tmp/encryption.values > /tmp/encryption.yaml
      kops create secret --name ${KOPS_CLUSTER_NAME} encryptionconfig -f /tmp/encryption.yaml --force
      kops create secret --name ${KOPS_CLUSTER_NAME} sshpublickey admin -i pub-key/${K8S_SSH_KEY}
    else
      log "SSH key for admin already created skippin creation process"
    fi
    )
    catch || {
        # TODO: 2020-12-08 wtf is all of this, should be removed
        # now you can handle
        case $ex_code in
            $AnException)
                log "AnException was thrown"
            ;;
            $AnotherException)
                log "AnotherException was thrown"
            ;;
            *)
                log "An unexpected exception was thrown"
                throw $ex_code # you can rethrow the "exception" causing the script to exit if not caught
            ;;
        esac
    }

    #kops upgrade cluster --yes

    log "kops - Update Cluster"
    kops update cluster --name ${KOPS_CLUSTER_NAME} \
                        --target terraform \
                        --out terraform/kubernetes || return 1

    log "kops - Export kubecfg"
    kops export kubecfg

    cd terraform/kubernetes
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

    log "Terraform - kops - Init"
    terraform init -var-file ${TERRAFORM_CONFIG_FILE}
    log "Terraform - kops - Plan"
    terraform refresh -var-file ${TERRAFORM_CONFIG_FILE}
    terraform plan -var-file ${TERRAFORM_CONFIG_FILE} -out ${KOPS_CLUSTER_NAME}.tfplan $@

    log "Terraform - Apply"
    terraform apply ${KOPS_CLUSTER_NAME}.tfplan && \
        log "Terraform Changes Applied"


    log "kops - rolling-update"
    prompt "Would you like to execute a Kops rolling update?" \
      kops rolling-update cluster --name ${KOPS_CLUSTER_NAME} --state ${KOPS_STATE_STORE}

    cd ..
}

helm_initialize_nginx_ingress(){

    cd ${BASE_PATH}

    helm init

    echo "Waiting for tiller initialization !"

    sleep 20

    kubectl create clusterrolebinding admin-binding --clusterrole cluster-admin --serviceaccount=kube-system:default || true

    helm upgrade  nginx-ingress kloia/nginx-ingress --version 0.0.2 -f nginx-values.yaml --set cert=${ORGANISATION_CERT_ARN} --namespace=nginx-ingress --set controller.replicaCount=3
    helm upgrade --install metrics-server ${BASE_PATH}/charts/metrics-server --namespace=kube-system

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
        --name autoscaler \
        --namespace kube-system \
        --set image.tag=v1.2.2 \
        --set autoDiscovery.clusterName=${KOPS_CLUSTER_NAME} \
        --set extraArgs.balance-similar-node-groups=false \
        --set extraArgs.expander=random \
        --set rbac.create=true \
        --set rbac.pspEnabled=true \
        --set awsRegion=us-west-2 \
        --set nodeSelector."node-role\.kubernetes\.io/master"="" \
        --set tolerations[0].effect=NoSchedule \
        --set tolerations[0].key=node-role.kubernetes.io/master \
        --set cloudProvider=aws \
        stable/cluster-autoscaler


}
natgw-elb-sec() {


    yq r -j ${KOPS_CONFIG_FILE} > ${TERRAFORM_CONFIG_FILE_NATGW_ELB_SEC}


    cd terraform/natgw-elb-sec
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


    terraform init -var-file ${TERRAFORM_CONFIG_FILE_NATGW_ELB_SEC} \
      -backend-config="region=${AWS_REGION}" \
      -backend-config="bucket=${TERRAFORM_BUCKET}" \
      -backend-config="key=${TERRAFORM_BUCKET_KEY_PREFIX}/natgw-elb-sec.tfstate"

    terraform plan -var-file ${TERRAFORM_CONFIG_FILE_NATGW_ELB_SEC} -out natgw-elb-sec.tfplan $@
    terraform apply natgw-elb-sec.tfplan

    cd ..
}


instana_agent_implementation(){


    INSTANA_SECRET_SETUP=$(kubectl create -f ../secrets/instana-secret.yaml)
    INSTANA_AGENT_KEY=$(kubectl get secret instana-secrets -n instana-agent -o yaml > /tmp/instana-secret && yq r /tmp/instana-secret  data.instana_key | base64 --decode )

    helm upgrade --install instana-agent  --namespace instana-agent \
    --set agent.key=$INSTANA_AGENT_KEY \
    --set agent.endpointHost=saas-us-west-2.instana.io \
    --set agent.endpointPort=443 \
    --set cluster.name=k8s.flocloud.co \
    --set zone.name=k8s.flocloud.co \
    stable/instana-agent

}

logz_fluentd_deamonset(){

  LOGZ_API_KEY=$(kubectl get secret logz-secret -o yaml > /tmp/logz-secret && yq r /tmp/logz-secret  data.logz_api_key | base64 --decode)
  echo "updating spec.template.spec.containers[0].env[0].value"
  yq w -i -d3 logz-daemonset.yaml 'spec.template.spec.containers[0].env[0].value' "${LOGZ_API_KEY}"
  kubectl apply -f ${BASE_PATH}/charts/logz-daemonset.yaml
  #Workaround to accidentally push secret to code repository
  echo "updating spec.template.spec.containers[0].env[0].value"
  yq w -i -d3 logz-daemonset.yaml 'spec.template.spec.containers[0].env[0].value' '{{API_TOKEN}}'

}

#create_ssh_key
terraform_base
vpc_peering
route53_association

### waiting for dns propagation
kops_create_cluster

### cluster access
#helm_initialize_nginx_ingress
#install_ca
#natgw-elb-sec
#instana_agent_implementation
#logz_fluentd_deamonset
