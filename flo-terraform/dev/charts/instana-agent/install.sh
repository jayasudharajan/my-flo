#!/usr/bin/env bash
helm upgrade instana-agent --namespace instana-agent \
--install \
--repo https://agents.instana.io/helm \
--set agent.key='' \
--set agent.endpointHost=ingress-red-saas.instana.io \
--set agent.endpointPort=443 \
--set cluster.name='eks.flocloud.co' \
--set zone.name='' \
--set agent.pod.requests.cpu=0.1 \
instana-agent