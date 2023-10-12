
{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{- define "config-dir-map" -}}
{{- printf "%s-config-dir-map" (include "name" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "openresty-config-dir" -}}
{{- printf "%s-openresty-dir" (include "name" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "conductor-config-dir" -}}
{{- printf "%s-conductor-dir" (include "name" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "redis-storage-claim-name" -}}
{{- printf "%s-redis-storage-claim" (include "name" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "elasticsearch-storage-claim-name" -}}
{{- printf "%s-elasticsearch-stor-claim" (include "name" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}