{{/*
image credentials name
*/}}
{{- define "imageCredentials.name" -}}
{{- if .Values.global.imageCredentials.name -}}
{{- .Values.global.imageCredentials.name -}}
{{- else -}}
{{- .Values.imageCredentials.name -}}
{{- end -}}
{{- end -}}

{{/*
image credentials registry
*/}}
{{- define "imageCredentials.registry" -}}
{{- if .Values.global.imageCredentials.registry -}}
{{- .Values.global.imageCredentials.registry -}}
{{- else -}}
{{- .Values.imageCredentials.registry -}}
{{- end -}}
{{- end -}}

{{/*
image credentials username
*/}}
{{- define "imageCredentials.username" -}}
{{- if .Values.global.imageCredentials.username -}}
{{- .Values.global.imageCredentials.username -}}
{{- else -}}
{{- .Values.imageCredentials.username -}}
{{- end -}}
{{- end -}}

{{/*
image credentials password
*/}}
{{- define "imageCredentials.password" -}}
{{- if .Values.global.imageCredentials.password -}}
{{- .Values.global.imageCredentials.password | b64enc -}}
{{- else -}}
{{- .Values.imageCredentials.password | b64enc -}}
{{- end -}}
{{- end -}}

{{/*
namespace
*/}}
{{- define "namespace.value" -}}
{{- if .Values.global.namespace -}}
{{- .Values.global.namespace -}}
{{- else -}}
{{- .Values.namespace -}}
{{- end -}}
{{- end -}}


{{/*
imageTag
*/}}
{{- define "imageTag" -}}
{{- if .Values.global.imageTag -}}
{{- .Values.global.imageTag -}}
{{- else -}}
{{- .Values.imageTag -}}
{{- end -}}
{{- end -}}
