#!/bin/sh
kubectl config set-cluster one-ci --server=${K8S_URL}
kubectl config set-credentials user-ci --token=${K8S_TOKEN}
kubectl config set-context default-context --cluster=one-ci --user=user-ci
kubectl config use-context default-context