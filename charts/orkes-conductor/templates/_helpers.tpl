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

{{/*
Helper to get Redis configuration with fallback from global to legacy
*/}}
{{- define "orkes-conductor.redis.host" -}}
{{- .Values.global.redis.host | default .Values.redis.host -}}
{{- end -}}

{{- define "orkes-conductor.redis.port" -}}
{{- .Values.global.redis.port | default .Values.redis.port | default 6379 -}}
{{- end -}}

{{- define "orkes-conductor.redis.password" -}}
{{- .Values.global.redis.auth.password | default .Values.redis.password -}}
{{- end -}}

{{- define "orkes-conductor.redis.username" -}}
{{- .Values.global.redis.auth.username | default .Values.redis.username -}}
{{- end -}}

{{- define "orkes-conductor.redis.ssl" -}}
{{- $globalSsl := or .Values.global.redis.ssl .Values.global.redis.sslEnabled -}}
{{- $localSsl := or .Values.redis.ssl .Values.redis.sslEnabled -}}
{{- or $globalSsl $localSsl | toString -}}
{{- end -}}

{{- define "orkes-conductor.redis.clusterMode" -}}
{{- .Values.global.redis.clusterMode | default .Values.redis.clusterMode -}}
{{- end -}}

{{- define "orkes-conductor.redis.dbIndex" -}}
{{- .Values.global.redis.dbIndex | default .Values.redis.dbIndex | default 0 -}}
{{- end -}}

{{- define "orkes-conductor.redis.zoneSuffix" -}}
{{- .Values.global.redis.zoneSuffix | default .Values.redis.zoneSuffix | default "us-east-1c" -}}
{{- end -}}

{{/*
Helper to get PostgreSQL configuration with fallback from global to legacy
*/}}
{{- define "orkes-conductor.postgres.host" -}}
{{- .Values.global.postgres.host | default .Values.postgres.host -}}
{{- end -}}

{{- define "orkes-conductor.postgres.port" -}}
{{- .Values.global.postgres.port | default .Values.postgres.port | default 5432 -}}
{{- end -}}

{{- define "orkes-conductor.postgres.database" -}}
{{- .Values.global.postgres.database | default .Values.postgres.database -}}
{{- end -}}

{{- define "orkes-conductor.postgres.username" -}}
{{- .Values.global.postgres.auth.username | default .Values.postgres.username -}}
{{- end -}}

{{- define "orkes-conductor.postgres.password" -}}
{{- .Values.global.postgres.auth.password | default .Values.postgres.password -}}
{{- end -}}

{{- define "orkes-conductor.postgres.url" -}}
{{- .Values.global.postgres.url | default .Values.postgres.url -}}
{{- end -}}

{{- define "orkes-conductor.postgres.ssl.enabled" -}}
{{- .Values.global.postgres.ssl.enabled | default .Values.postgres.ssl.enabled -}}
{{- end -}}

{{- define "orkes-conductor.postgres.ssl.mode" -}}
{{- .Values.global.postgres.ssl.mode | default .Values.postgres.ssl.mode | default "require" -}}
{{- end -}}

{{- define "orkes-conductor.postgres.maxPoolSize" -}}
{{- .Values.global.postgres.connection.maxPoolSize | default .Values.postgres.maxPoolSize -}}
{{- end -}}

{{- define "orkes-conductor.postgres.minPoolSize" -}}
{{- .Values.global.postgres.connection.minPoolSize | default .Values.postgres.minPoolSize -}}
{{- end -}}

{{- define "orkes-conductor.postgres.connectionTimeout" -}}
{{- .Values.global.postgres.connection.timeout | default .Values.postgres.connectionTimeout -}}
{{- end -}}

{{/*
Helper to get Vault configuration with fallback
*/}}
{{- define "orkes-conductor.vault.enabled" -}}
{{- or .Values.global.vault.enabled .Values.vault.enabled -}}
{{- end -}}

{{- define "orkes-conductor.vault.server.enabled" -}}
{{- or .Values.global.vault.server.enabled .Values.vault.server.enabled -}}
{{- end -}}

{{- define "orkes-conductor.vault.server.role" -}}
{{- .Values.global.vault.server.role | default .Values.vault.server.role -}}
{{- end -}}

{{- define "orkes-conductor.vault.server.serviceAccount" -}}
{{- .Values.global.vault.server.serviceAccount | default .Values.vault.server.serviceAccount | default "conductor-app" -}}
{{- end -}}

{{- define "orkes-conductor.vault.server.envSecrets" -}}
{{- if .Values.global.vault.server.envSecrets -}}
{{- .Values.global.vault.server.envSecrets | toYaml -}}
{{- else -}}
{{- .Values.vault.server.envSecrets | toYaml -}}
{{- end -}}
{{- end -}}

{{- define "orkes-conductor.vault.workers.enabled" -}}
{{- or .Values.global.vault.workers.enabled .Values.vault.workers.enabled -}}
{{- end -}}

{{- define "orkes-conductor.vault.workers.role" -}}
{{- .Values.global.vault.workers.role | default .Values.vault.workers.role -}}
{{- end -}}

{{- define "orkes-conductor.vault.workers.serviceAccount" -}}
{{- .Values.global.vault.workers.serviceAccount | default .Values.vault.workers.serviceAccount | default "conductor-workers-app" -}}
{{- end -}}

{{/*
Helper to get server configuration with fallback
*/}}
{{- define "orkes-conductor.server.replicas" -}}
{{- .Values.server.replicas | default .Values.app.replicaCount | default 3 -}}
{{- end -}}

{{- define "orkes-conductor.server.image.repository" -}}
{{- .Values.server.image.repository | default .Values.image.repository -}}
{{- end -}}

{{- define "orkes-conductor.server.image.tag" -}}
{{- .Values.server.image.tag | default .Values.global.image.tag | default .Chart.AppVersion -}}
{{- end -}}

{{- define "orkes-conductor.server.image.pullPolicy" -}}
{{- .Values.server.image.pullPolicy | default .Values.global.image.pullPolicy | default .Values.image.pullPolicy | default "IfNotPresent" -}}
{{- end -}}

{{/*
Helper to get workers configuration with fallback
*/}}
{{- define "orkes-conductor.workers.replicas" -}}
{{- .Values.workers.replicas | default .Values.workers.replicaCount | default .Values.workersConfig.replicaCount | default 2 -}}
{{- end -}}

{{- define "orkes-conductor.workers.image.repository" -}}
{{- .Values.workers.image.repository | default .Values.workerImage.repository -}}
{{- end -}}

{{- define "orkes-conductor.workers.image.tag" -}}
{{- .Values.workers.image.tag | default .Values.global.image.tag | default .Chart.AppVersion -}}
{{- end -}}

{{- define "orkes-conductor.workers.image.pullPolicy" -}}
{{- .Values.workers.image.pullPolicy | default .Values.global.image.pullPolicy | default .Values.workerImage.pullPolicy | default "IfNotPresent" -}}
{{- end -}}

{{- define "orkes-conductor.workers.accessKeyId" -}}
{{- .Values.workers.auth.accessKeyId | default .Values.workers.accessKeyId | default .Values.workersConfig.accessKeyId -}}
{{- end -}}

{{- define "orkes-conductor.workers.accessKeySecret" -}}
{{- .Values.workers.auth.accessKeySecret | default .Values.workers.accessKeySecret | default .Values.workersConfig.accessKeySecret -}}
{{- end -}}

{{/*
Helper to get merged vault envSecrets (global takes precedence)
*/}}
{{- define "orkes-conductor.vault.server.getMergedEnvSecrets" -}}
{{- $globalSecrets := .Values.global.vault.server.envSecrets | default dict -}}
{{- $localSecrets := .Values.vault.server.envSecrets | default dict -}}
{{- merge $globalSecrets $localSecrets | toYaml -}}
{{- end -}}

{{- define "orkes-conductor.vault.workers.getMergedEnvSecrets" -}}
{{- $globalSecrets := .Values.global.vault.workers.envSecrets | default dict -}}
{{- $localSecrets := .Values.vault.workers.envSecrets | default dict -}}
{{- merge $globalSecrets $localSecrets | toYaml -}}
{{- end -}}

{{- define "orkes-conductor.vault.server.getMergedAnnotations" -}}
{{- $globalAnnotations := .Values.global.vault.server.annotations | default dict -}}
{{- $localAnnotations := .Values.vault.server.annotations | default dict -}}
{{- merge $globalAnnotations $localAnnotations | toYaml -}}
{{- end -}}

{{- define "orkes-conductor.vault.workers.getMergedAnnotations" -}}
{{- $globalAnnotations := .Values.global.vault.workers.annotations | default dict -}}
{{- $localAnnotations := .Values.vault.workers.annotations | default dict -}}
{{- merge $globalAnnotations $localAnnotations | toYaml -}}
{{- end -}}

{{/*
Helper to check if a key exists in merged server envSecrets
*/}}
{{- define "orkes-conductor.vault.server.hasEnvSecret" -}}
{{- $globalSecrets := .root.Values.global.vault.server.envSecrets | default dict -}}
{{- $localSecrets := .root.Values.vault.server.envSecrets | default dict -}}
{{- $merged := merge $globalSecrets $localSecrets -}}
{{- if hasKey $merged .key -}}
true
{{- end -}}
{{- end -}}

{{/*
Helper to check if a key exists in merged workers envSecrets
*/}}
{{- define "orkes-conductor.vault.workers.hasEnvSecret" -}}
{{- $globalSecrets := .root.Values.global.vault.workers.envSecrets | default dict -}}
{{- $localSecrets := .root.Values.vault.workers.envSecrets | default dict -}}
{{- $merged := merge $globalSecrets $localSecrets -}}
{{- if hasKey $merged .key -}}
true
{{- end -}}
{{- end -}}
