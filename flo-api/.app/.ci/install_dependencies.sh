#!/bin/bash

source .ci/.env.rc

set -euo pipefail

sudo apt-get update
sudo apt-get install python-dev libffi-dev libssl-dev

sudo -H pip install awsebcli==3.10.6 --upgrade --ignore-installed
sudo -H pip install awscli==1.11.138 --upgrade --ignore-installed
sudo -H pip install docker-compose==1.8.0 --upgrade --ignore-installed

