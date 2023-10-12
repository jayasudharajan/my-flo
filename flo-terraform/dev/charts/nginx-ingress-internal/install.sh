#!/usr/bin/env bash
helm upgrade \
  --install nginx-ingress-internal \
  . \
  --recreate-pods \
  --wait --values values.yaml --namespace nginx-ingress-internal
