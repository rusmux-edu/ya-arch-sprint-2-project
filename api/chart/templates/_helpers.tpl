{{- define "api.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "api.fullname" -}}
{{- if contains .Chart.Name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "api.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "api.labels" -}}
helm.sh/chart: {{ include "api.chart" . }}
{{ include "api.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "api.selectorLabels" -}}
app.kubernetes.io/name: {{ include "api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "api.env" -}}
- name: UVICORN_PORT
  valueFrom:
    configMapKeyRef:
      name: {{ include "api.fullname" . }}
      key: UVICORN_PORT
- name: MONGODB__URL
  valueFrom:
    secretKeyRef:
      name: {{ include "api.fullname" . }}
      key: MONGODB__URL
- name: MONGODB__DB_NAME
  valueFrom:
    configMapKeyRef:
      name: {{ include "api.fullname" . }}
      key: MONGODB__DB_NAME
- name: MONGODB__WRITE_CONCERN
  valueFrom:
    configMapKeyRef:
      name: {{ include "api.fullname" . }}
      key: MONGODB__WRITE_CONCERN
- name: REDIS__IS_CLUSTER
  valueFrom:
    configMapKeyRef:
      name: {{ include "api.fullname" . }}
      key: REDIS__IS_CLUSTER
- name: REDIS__URL
  valueFrom:
    secretKeyRef:
      name: {{ include "api.fullname" . }}
      key: REDIS__URL
- name: DUMMY
  valueFrom:
    configMapKeyRef:
      name: {{ include "api.fullname" . }}
      key: DUMMY
{{- end }}

{{- define "spec.topologySpreadConstraints" -}}
topologySpreadConstraints:
  - maxSkew: 2
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        {{- include "api.selectorLabels" . | nindent 8 }}
{{- end }}

{{- define "spec.podSecurity" -}}
automountServiceAccountToken: false
securityContext:
  runAsUser: 10001
  runAsGroup: 10002
  fsGroup: 2000
  runAsNonRoot: true
  seccompProfile:
    type: RuntimeDefault
{{- end }}

{{- define "spec.containers" -}}
containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
    ports:
      - containerPort: {{ .Values.service.port }}
    env:
      {{- include "api.env" . | nindent 6 }}
    livenessProbe:
      httpGet:
        path: /livez
        port: {{ .Values.service.port }}
      initialDelaySeconds: 3
      periodSeconds: 10
      timeoutSeconds: 10
      failureThreshold: 3
    readinessProbe:
      httpGet:
        path: /readyz
        port: {{ .Values.service.port }}
      initialDelaySeconds: 3
      periodSeconds: 10
      timeoutSeconds: 10
      successThreshold: 1
      failureThreshold: 3
    resources:
      {{- toYaml .Values.resources | nindent 6 }}
{{- end }}
