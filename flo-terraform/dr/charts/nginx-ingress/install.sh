#!/usr/bin/env bash
helm upgrade --install nginx-ingress ./nginx-ingress \
    --wait --namespace nginx-ingress \
    --set cert=arn:aws:acm:us-west-2:098786959887:certificate/4f522843-d02a-4567-95b6-70efd7967d9c
