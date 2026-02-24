{{/*
User password
*/}}
{{- define "gitlab-user.password" -}}
{{- if .Values.gitlab.users.password }}
{{- .Values.gitlab.users.password }}
{{- else }}
{{- randAlpha 8 }}
{{- end }}
{{- end }}

{{ define "gitlab.repo.check-pipeline" -}}
{{- $arg := . }}
{{- if $arg.properties }}
{{- if $arg.properties.onlyMergeWhenPipelineSucceeds }}
{{- $arg.properties.onlyMergeWhenPipelineSucceeds }}
{{- else }}
{{- false }}
{{- end }}
{{- else }}
{{- false }}
{{- end }}
{{- end }}
