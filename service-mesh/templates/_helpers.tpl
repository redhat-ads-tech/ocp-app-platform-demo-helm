{{/*
Expand the name of the chart.
*/}}
{{- define "service-mesh.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
