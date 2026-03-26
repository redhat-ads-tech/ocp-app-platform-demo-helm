{{- define "parasol-insurance-tenant.username" -}}
{{ .Values.tenant.username }}
{{- end -}}

{{- define "parasol-insurance-tenant.prefix" -}}
{{ .Values.tenant.username }}-parasol-insurance
{{- end -}}
