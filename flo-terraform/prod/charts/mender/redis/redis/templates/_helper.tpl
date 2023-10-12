{{/* vim: set filetype=mustache: */}}

{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride -}}
{{- end -}}


{{- define "fullname" -}}
{{- printf "%s" .Release.Name -}}
{{- end -}}

{{- define "config-dir-map" -}}
{{- printf "%s-config-dir-map" (include "name" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "redis-storage-claim-name" -}}
{{- printf "%s-redis-storage-claim" (include "name" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}