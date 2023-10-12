{{/* vim: set filetype=mustache: */}}

{{- define "name" -}}
{{- default .Chart.Name .Values.nameOverride -}}
{{- end -}}


{{- define "fullname" -}}
{{- printf "%s" .Release.Name -}}
{{- end -}}

