{{/*
Expand the name of the chart.
*/}}
{{- define "sonarqube.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sonarqube.labels" -}}
app: {{ include "sonarqube.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
