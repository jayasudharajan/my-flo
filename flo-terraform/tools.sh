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

helm_initialize_nginx_ingress(){

    pushd ${BASE_PATH}/terraform/base
    
    organisation_cert_arn=$(terraform output -json kops_acm_id | jq '.value')
    export ORGANISATION_CERT_ARN=${organisation_cert_arn}

    popd
    
    echo $ORGANISATION_CERT_ARN

    helm init

    helm repo add kloia https://kloia.github.io/helm-charts/
    
    kubectl create clusterrolebinding admin-binding --clusterrole cluster-admin --serviceaccount=kube-system:default || true

    helm  upgrade --install nginx-ingress kloia/nginx-ingress --version 0.0.2 -f nginx-values.yaml --set cert=$ORGANISATION_CERT_ARN --namespace=nginx-ingress --set controller.replicaCount=3

    helm upgrade --install metrics-server ${BASE_PATH}/charts/metrics-server --namespace=kube-system
    
    

}

# peering
# kops terraform remove
# kops delete 
# route53 asso
# base terraform

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
        echo "    profile = \"${AWS_PROFILE}\""
        echo "    key    = \"${TERRAFORM_BUCKET_KEY_PREFIX}/route53_association.tfstate\""
        echo "  }"
        echo "}"
        echo "provider \"aws\" {"
        echo "  profile = \"${AWS_PROFILE}\""
        echo "  region = \"${AWS_REGION}\""
        echo "}"
    ) > backend.tf




    terraform init -var-file ${TERRAFORM_CONFIG_FILE_NATGW_ELB_SEC} \
      -backend-config="region=${AWS_REGION}" \
      -backend-config="bucket=${TERRAFORM_BUCKET}" \
      -backend-config="key=${TERRAFORM_BUCKET_KEY_PREFIX}/natgw-elb-sec.tfstate"

    terraform plan -var-file ${TERRAFORM_CONFIG_FILE_NATGW_ELB_SEC} -out natgw-elb-sec.tfplan $@
    terraform apply natgw-elb-sec.tfplan

    cd ../../
}


instana_agent_implementation(){


    INSTANA_SECRET_SETUP=$(kubectl create -f ../secrets/instana-secret.yaml)
    INSTANA_AGENT_KEY=$(kubectl get secret instana-secrets -n instana-agent -o yaml > /tmp/instana-secret && yq r /tmp/instana-secret  data.instana_key | base64 --decode )

    helm upgrade --install instana-agent  --namespace instana-agent \
    --set agent.key=$INSTANA_AGENT_KEY \
    --set agent.endpointHost=saas-us-west-2.instana.io \
    --set agent.endpointPort=443 \
    --set cluster.name=oceanus.flosecurecloud.com \
    --set zone.name=oceanus.flosecurecloud.com \
    stable/instana-agent

}

logz_fluentd_deamonset(){
  LOGZ_SECRET_SETUP=$(kubectl create -f ../secrets/logzio-secret.yaml)
  LOGZ_API_KEY=$(kubectl get secret logz-secret -n kube-system -o yaml > /tmp/logz-secret && yq r /tmp/logz-secret  data.logz_api_key | base64 --decode)
  sed -i '' "s/            value: {{API_TOKEN}}.*/            value: $LOGZ_API_KEY/g" ${BASE_PATH}/charts/logz-daemonset.yaml
  kubectl apply -f ${BASE_PATH}/charts/logz-daemonset.yaml
  #Workaround to accidentally push secret to code repository
  sed -i '' "s/            value: $LOGZ_API_KEY.*/            value: {{API_TOKEN}}/g" ${BASE_PATH}/charts/logz-daemonset.yaml

}

helm_initialize_nginx_ingress
#install_ca
#natgw-elb-sec
#instana_agent_implementation
#logz_fluentd_deamonset
