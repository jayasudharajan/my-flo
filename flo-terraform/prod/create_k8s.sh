#!/usr/bin/env bash
set -e

export AWS_PROFILE=flo-prod
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
export AWS_ACCOUNT=$(${YQ_CMD} aws.accountId)
export AWS_ACCOUNT_ID=$(${YQ_CMD} aws.accountId)
export AWS_REGION=$(${YQ_CMD} aws.region)
export AWS_DEFAULT_REGION=${AWS_REGION}
export TERRAFORM_DIRECTORY=terraform
export TERRAFORM_OUTPUT_PATH="/tmp/terraform_output.json"
export TERRAFORM_BUCKET="${ORGANISATION}-terraform-state-${AWS_ACCOUNT}"
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

    output=$(eval "aws route53 list-hosted-zones-by-name --dns-name ${ORGANISATION}.${DOMAIN} --profile ${PROFILE} | jq -c '.HostedZones[] | select(.Name == \"${ORGANISATION}.${DOMAIN}.\")'")
    echo $output
    create_main_dns="\"true\""
    create_child_dns="\"true\""
    if [ -n "${output}" ]; then
        echo "DNS zone already exist skippin creation process"
        create_main_dns="\"false\""
        echo $output | jq .Id | cut -c 14- | rev | cut -c 2- | rev > temp.txt
        zoneId=`cat temp.txt`
        echo "$zoneId"
        sed -i '' "s/  parentZoneId:.*/  parentZoneId: $zoneId/g" ../../deployment/values.yaml
        child_check=$(eval "aws route53 list-hosted-zones-by-name --dns-name ${ORGANISATION}.${DOMAIN} --profile ${PROFILE} | jq -c '.HostedZones[] | select(.Name == \"${CHILD_DNS}.${ORGANISATION}.${DOMAIN}.\")'")
        if [ -n "${child_check}" ]; then
            create_child_dns=="\"false\""
        fi
    fi


    sed -i '' "s/  create_main_dns:.*/  create_main_dns: $create_main_dns/g" ../../deployment/values.yaml
    sed -i '' "s/  create_child_dns:.*/  create_child_dns: $create_child_dns/g" ../../deployment/values.yaml
    yq r -j ../../${KOPS_CONFIG_FILE} > ${TERRAFORM_CONFIG_FILE}

    echo TF Init
    terraform init -var-file ${TERRAFORM_CONFIG_FILE}
    echo TF Refresh
    terraform refresh -var-file ${TERRAFORM_CONFIG_FILE}
    echo TF Plan
    terraform plan -var-file ${TERRAFORM_CONFIG_FILE} -out ${KOPS_CLUSTER_NAME}.tfplan $@
    # terraform apply ${KOPS_CLUSTER_NAME}.tfplan

    # terraform destroy -var-file ${TERRAFORM_CONFIG_FILE}
    echo "Applied"

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
    sed -i '' "s/  vpcId:.*/  vpcId: $vpcId/g" deployment/values.yaml
    sed -i '' "s/  parentZoneId:.*/  parentZoneId: $zoneId/g" deployment/values.yaml
    sed -i '' "s/  natgatewayId:.*/  natgatewayId: $NAT_GATEWAY_ID/g" deployment/values.yaml


    echo '''
subnets:
- {"name": "private-us-west-2a", "zone": "us-west-2a", "cidr": '$private_cidr1', "type": "Private", "id":'$private_sb1'}
- {"name": "private-us-west-2b", "zone": "us-west-2b", "cidr": '$private_cidr2', "type": "Private", "id":'$private_sb2'}
- {"name": "private-us-west-2c", "zone": "us-west-2c", "cidr": '$private_cidr3', "type": "Private", "id":'$private_sb3'}
- {"name": "public-us-west-2a", "zone": "us-west-2a", "cidr": '$public_cidr1', "type": "Utility", "id":'$public_sb1'}
- {"name": "public-us-west-2b", "zone": "us-west-2b", "cidr": '$public_cidr2', "type": "Utility", "id":'$public_sb2'}
- {"name": "public-us-west-2c", "zone": "us-west-2c", "cidr": '$public_cidr3', "type": "Utility", "id":'$public_sb3'}
    ''' > deployment/subnets.yaml
    export KOPS_SUBNETS_FILE=deployment/subnets.yaml
    echo "Subnet Yaml's written to the file"
}

vpc_peering() {

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

    terraform init -var-file ${TERRAFORM_CONFIG_FILE_PEERING} \
      -backend-config="region=${AWS_REGION}" \
      -backend-config="bucket=${TERRAFORM_BUCKET}" \
      -backend-config="key=${TERRAFORM_BUCKET_KEY_PREFIX}/peering.tfstate"
    terraform plan -var-file ${TERRAFORM_CONFIG_FILE_PEERING} -out peering.tfplan $@
    terraform apply peering.tfplan

    cd ../../

}


route53_association(){

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

    terraform init -var-file ${TERRAFORM_CONFIG_FILE_ROUTE53_ASSO} \
      -backend-config="region=${AWS_REGION}" \
      -backend-config="bucket=${TERRAFORM_BUCKET}" \
      -backend-config="key=${TERRAFORM_BUCKET_KEY_PREFIX}/route53_association.tfstate"

    terraform plan -var-file ${TERRAFORM_CONFIG_FILE_ROUTE53_ASSO} -out route53_association.tfplan $@
    terraform apply route53_association.tfplan

    cd ../../

}


kops_create_cluster() {

    cd ${BASE_PATH}
    export KOPS_SUBNETS_FILE=deployment/subnets.yaml

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

    kops replace --force -f /tmp/cluster.yaml

    s3path=${KOPS_STATE_STORE}/${KOPS_CLUSTER_NAME}"/pki/ssh/public/admin/"

    echo $s3path
    try
    (
    s3ls=$(eval "aws s3 ls $s3path")
    if [ -z "${s3ls}" ]; then
      echo encryption_key: $(head -c32 /dev/urandom | base64) > /tmp/encryption.values
      gotpl templates/encryption.yaml < /tmp/encryption.values > /tmp/encryption.yaml
      kops create secret --name ${KOPS_CLUSTER_NAME} encryptionconfig -f /tmp/encryption.yaml --force
      kops create secret --name ${KOPS_CLUSTER_NAME} sshpublickey admin -i pub-key/${K8S_SSH_KEY}
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

    #kops upgrade cluster --yes

    kops update cluster --name ${KOPS_CLUSTER_NAME} \
                        --target terraform \
                        --out terraform/kubernetes

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

    terraform init -var-file ${TERRAFORM_CONFIG_FILE}
    terraform plan -var-file ${TERRAFORM_CONFIG_FILE} -out ${KOPS_CLUSTER_NAME}.tfplan $@
    terraform refresh -var-file ${TERRAFORM_CONFIG_FILE}

    terraform apply ${KOPS_CLUSTER_NAME}.tfplan

    kops rolling-update cluster --name ${KOPS_CLUSTER_NAME} --yes --state ${KOPS_STATE_STORE}

    cd ..
}


#create_ssh_key
#terraform_base
#vpc_peering
#route53_association
### waiting for dns propagation
kops_create_cluster
### cluster access
