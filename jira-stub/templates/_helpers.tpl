{{/*
Expand the name of the chart.
*/}}
{{- define "jira-stub.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "jira-stub.labels" -}}
app: {{ include "jira-stub.name" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
