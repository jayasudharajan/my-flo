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

{{- define "elasticsearch-claim-name" -}}
{{- printf "%s-elasticsearch-claim" (include "name" .) | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}