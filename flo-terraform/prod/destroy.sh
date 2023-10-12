#!/bin/bash
set -e

export AWS_PROFILE=flo-prod
export TERRAFORM_DIRECTORY=terraform
export BASE_PATH=$(eval "pwd")
export KOPS_CONFIG_FILE=deployment/values.yaml
export TERRAFORM_CONFIG_FILE=/tmp/config.tfvars
export YQ_CMD="yq r ${KOPS_CONFIG_FILE}"
export KOPS_STATE_STORE=$(${YQ_CMD} kubernetes.stateStore)


peering_destroy(){

    cd ${BASE_PATH}/${TERRAFORM_DIRECTORY}/vpc-peering

        terraform destroy -var-file /tmp/config-peering.tfvars -auto-approve=true

    cd ..
}

kubernetes_destroy(){

    cd ${BASE_PATH}/${TERRAFORM_DIRECTORY}/kubernetes

        terraform destroy -var-file /tmp/config.tfvars -auto-approve=true
        
    cd ..
}

kops_cluster_destroy(){

    kops delete cluster --name oceanus.flosecurecloud.com --yes
}

route53_asso_destroy(){

    cd ${BASE_PATH}/${TERRAFORM_DIRECTORY}/route53-association
 
        terraform destroy -var-file /tmp/config-route53-asso.tfvars -auto-approve=true
        
    cd ..
    
}

base_destroy(){
    
    #aws s3 rm ${KOPS_STATE_STORE} --recursive 

    cd ${BASE_PATH}/${TERRAFORM_DIRECTORY}/base

        terraform destroy -var-file /tmp/config.tfvars -auto-approve=true
        
    cd ..
    
}

#peering_destroy
#route53_asso_destroy
#kubernetes_destroy
#kops_cluster_destroy
base_destroy

# Removing Rules 
# 1-) peering
# 2-) terraform resources created by kops
# 3-) delete resources created by kops 
# 4-) delete route53 asso
# 5-) delete base resources of terraform
