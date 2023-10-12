#!/usr/bin/env bash
helm upgrade --install kafka-minion ./k8s --recreate-pods --wait --values values.yaml --namespace prometheus

