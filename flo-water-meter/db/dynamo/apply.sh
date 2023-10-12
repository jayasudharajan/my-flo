#!/bin/sh
aws dynamodb create-table --cli-input-json file://$1 --region us-west-2