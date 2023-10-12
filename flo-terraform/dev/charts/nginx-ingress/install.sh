#!/usr/bin/env bash
helm upgrade --install nginx-ingress ./ingress-nginx --wait --values values.yaml --namespace nginx-ingress
