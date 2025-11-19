{{/*
Expand the name of the chart.
*/}}
{{- define "orkes-conductor.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "orkes-conductor.fullname" -}}
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

{{- define "orkes-conductor-workers.fullname" -}}
{{- if .Values.workers.name }}
{{- .Values.workers.name | trunc 55 | trimSuffix "-" }}
{{- else if .Values.fullnameOverride }}
{{- printf "%s-workers" .Values.fullnameOverride | trunc 55 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- printf "%s-workers" .Release.Name | trunc 55 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s-workers" .Release.Name $name | trunc 55 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Server-specific fullname
*/}}
{{- define "orkes-conductor-server.fullname" -}}
{{- if .Values.server.name }}
{{- .Values.server.name | trunc 63 | trimSuffix "-" }}
{{- else if .Values.fullnameOverride }}
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
{{- define "orkes-conductor.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "orkes-conductor.labels" -}}
helm.sh/chart: {{ include "orkes-conductor.chart" . }}
{{ include "orkes-conductor.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "orkes-conductor.selectorLabels" -}}
app.kubernetes.io/name: {{ include "orkes-conductor.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "orkes-conductor.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "orkes-conductor.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "imagePullSecret" }}
{{- with .Values.imageCredentials }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{/*
Custom image pull secret for multiple registries
*/}}
{{- define "customImagePullSecret" }}
{{- $auths := dict }}
{{- range .Values.customImagePullSecrets.registries }}
{{- $auth := printf "%s:%s" .username .password | b64enc }}
{{- $registryAuth := dict "username" .username "password" .password "email" .email "auth" $auth }}
{{- $_ := set $auths .registry $registryAuth }}
{{- end }}
{{- dict "auths" $auths | toJson | b64enc }}
{{- end }}

{{/*
Generate the list of image pull secrets
*/}}
{{- define "orkes-conductor.imagePullSecrets" -}}
{{- if .Values.existingImagePullSecret }}
- name: {{ .Values.existingImagePullSecret }}
{{- else if .Values.customImagePullSecrets.enabled }}
- name: {{ .Values.customImagePullSecrets.name }}
{{- else }}
- name: orkesregistry
{{- end }}
{{- end }}
