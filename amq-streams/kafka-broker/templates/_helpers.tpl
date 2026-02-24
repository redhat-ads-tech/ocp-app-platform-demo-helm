{{/*
Expand the name of the chart.
*/}}
{{- define "kafka-broker.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "kafka-broker.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "kafka-broker.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kafka-broker.labels" -}}
helm.sh/chart: {{ include "kafka-broker.chart" . }}
{{ include "kafka-broker.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kafka-broker.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kafka-broker.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Kafka authentication
*/}}
{{- define "kafka-broker.authentication" -}}
{{- if eq .Values.authentication.saslMechanism "SCRAM-SHA-512" -}}
authentication:
  type: scram-sha-512
{{- else }}
authentication: {}
{{- end }}
{{- end }}

{{/*
ArgoCD Syncwave for Kafka resources
*/}}
{{- define "kafka-broker.argocd-syncwave" -}}
{{- if and (.Values.argocd) (.Values.argocd.syncwave) }}
{{- if (.Values.argocd.syncwave.enabled) -}}
argocd.argoproj.io/sync-wave: "{{ .Values.argocd.syncwave.kafka }}"
{{- else }}
{{- "{}" }}
{{- end }}
{{- else }}
{{- "{}" }}
{{- end }}
{{- end }}

{{/*
ArgoCD Syncwave for Namespace
*/}}
{{- define "kafka-namespace.argocd-syncwave" -}}
{{- if and (.Values.argocd) (.Values.argocd.syncwave) }}
{{- if (.Values.argocd.syncwave.enabled) -}}
argocd.argoproj.io/sync-wave: "{{ .Values.argocd.syncwave.namespace }}"
{{- else }}
{{- "{}" }}
{{- end }}
{{- else }}
{{- "{}" }}
{{- end }}
{{- end }}
