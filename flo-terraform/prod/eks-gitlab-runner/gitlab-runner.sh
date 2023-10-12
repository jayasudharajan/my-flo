#!/bin/bash

export BASE_PATH=$(eval "pwd")
cd $BASE_PATH

if [[ -z "${APP_NAME}" ]]
then
    APP_NAME=gitlab-runner
fi

TOKEN_NAME=$(kubectl -n kube-system get secret | grep gitlab-admin | awk '{print $1}')
CERT_TOKEN_NAME=$(kubectl get secret |grep default | awk '{print $1}')
kubectl cluster-info | grep 'Kubernetes master' | awk '/http/ {print $NF}'

create_gitlabrunner(){

    helm upgrade --install "${APP_NAME}" -f values.yml gitlab/gitlab-runner --wait --namespace gitlab-runner --create-namespace

}

create_gitlabrunner_cert() {

    kubectl get secret $CERT_TOKEN_NAME -o jsonpath="{['data']['ca\.crt']}" | base64 --decode

}

create_gitlab_admin_token() {

    echo $TOKEN_NAME

    kubectl create -f gitlab-admin-service-account.yaml
    sleep 20
    kubens kube-system
    kubectl get secret $TOKEN_NAME -o yaml > /tmp/data
    yq r /tmp/data data.token |base64 --decode
    rm /tmp/data

}

create_gitlabrunner
echo ""
create_gitlabrunner_cert
echo ""
#create_gitlab_admin_token
