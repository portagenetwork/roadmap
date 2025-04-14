{{/*
Expand the name of the chart.
*/}}
{{- define "dmp-roadmap.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "dmp-roadmap.fullname" -}}
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
{{- define "dmp-roadmap.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "dmp-roadmap.labels" -}}
helm.sh/chart: {{ include "dmp-roadmap.chart" . }}
{{ include "dmp-roadmap.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- with .Values.global.additionalLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "dmp-roadmap.selectorLabels" -}}
app.kubernetes.io/name: {{ include "dmp-roadmap.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .component }}
app.kubernetes.io/component: {{ .component }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "dmp-roadmap.serviceAccountName" -}}
{{- if .Values.app.serviceAccount.create }}
{{- default (include "dmp-roadmap.fullname" .) .Values.app.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.app.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create default domain URL
*/}}
{{- define "dmp-roadmap.domainUrl" -}}
{{- printf "https://%s" .Values.global.domain.name -}}
{{- end -}}

{{/*
Create default full URL with path
*/}}
{{- define "dmp-roadmap.fullUrl" -}}
{{- printf "%s%s" (include "dmp-roadmap.domainUrl" .) .Values.global.domain.path -}}
{{- end -}}

{{/*
Get the Rails relative URL root
*/}}
{{- define "dmp-roadmap.railsRelativeUrlRoot" -}}
{{- .Values.config.environment.railsRelativeUrlRoot | default .Values.global.domain.path -}}
{{- end -}}
