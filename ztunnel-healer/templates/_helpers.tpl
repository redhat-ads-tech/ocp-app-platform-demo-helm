{{/*
Expand the name of the chart.
*/}}
{{- define "ztunnel-healer.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ztunnel-healer.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ztunnel-healer.labels" -}}
helm.sh/chart: {{ include "ztunnel-healer.chart" . }}
{{ include "ztunnel-healer.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "ztunnel-healer.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ztunnel-healer.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
