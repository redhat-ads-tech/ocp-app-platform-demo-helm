{{/*
Expand the name of the chart.
*/}}
{{- define "parasol.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "parasol.fullname" -}}
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
{{- define "parasol.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "parasol.labels" -}}
helm.sh/chart: {{ include "parasol.chart" . }}
{{ include "parasol.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "parasol.selectorLabels" -}}
app.kubernetes.io/name: {{ include "parasol.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "parasol.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "parasol.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "parasol.store.source.image" -}}
{{- printf "docker://%s:%s" .Values.parasol.store.image.source.image .Values.parasol.store.image.source.tag }}
{{- end }}

{{- define "parasol.store.image" -}}
{{- printf "docker://%s/%s/%s:%s" .Values.registry.host .Values.registry.organization .Values.parasol.store.image.name .Values.parasol.store.image.tag }}
{{- end }}

{{- define "parasol.web.source.image" -}}
{{- printf "docker://%s:%s" .Values.parasol.web.image.source.image .Values.parasol.web.image.source.tag }}
{{- end }}

{{- define "parasol.web.image" -}}
{{- printf "docker://%s/%s/%s:%s" .Values.registry.host .Values.registry.organization .Values.parasol.web.image.name .Values.parasol.web.image.tag }}
{{- end }}

{{- define "sso.url" -}}
{{- $ := index . 0 -}}
{{- $arg := index . 1 }}
{{- if eq $arg "dev" -}}
{{- printf "https://%s/realms/%s" $.Values.parasol.web.sso.dev.host $.Values.parasol.web.sso.dev.realm }}
{{- else if eq $arg "staging" -}}
{{- printf "https://%s/realms/%s" $.Values.parasol.web.sso.staging.host $.Values.parasol.web.sso.staging.realm }}
{{- else if eq $arg "prod" -}}
{{- printf "https://%s/realms/%s" $.Values.parasol.web.sso.prod.host $.Values.parasol.web.sso.prod.realm }}
{{- else -}}
{{- "" }}
{{- end }}
{{- end }}

{{- define "sso.client" -}}
{{- $ := index . 0 -}}
{{- $arg := index . 1 }}
{{- if eq $arg "dev" -}}
{{- $.Values.parasol.web.sso.dev.client }}
{{- else if eq $arg "staging" -}}
{{- $.Values.parasol.web.sso.staging.client }}
{{- else if eq $arg "prod" -}}
{{- $.Values.parasol.web.sso.prod.client }}
{{- else -}}
{{- "" }}
{{- end }}
{{- end }}

{{- define "sso.logout-url" -}}
{{- $ := index . 0 -}}
{{- $arg := index . 1 -}}
{{- printf "https://parasol-web-%s.%s/home" $arg.namespace $.Values.cluster.subdomain }}
{{- end }}
