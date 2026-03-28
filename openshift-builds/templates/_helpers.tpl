{{/*
Expand the name of the chart.
*/}}
{{- define "openshift-builds.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
