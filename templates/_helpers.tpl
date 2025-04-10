{{/*
Expand the name of the chart.
*/}}
{{- define "temporal-scaling-demo.name" -}}
{{- include "common.names.name" . -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "temporal-scaling-demo.fullname" -}}
{{- include "common.names.fullname" . -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "temporal-scaling-demo.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels with component
*/}}
{{- define "temporal-scaling-demo.labels" -}}
{{- $root := index . 0 -}}
{{- $component := index . 1 -}}
helm.sh/chart: {{ include "temporal-scaling-demo.chart" $root }}
{{- if $root.Chart.AppVersion }}
app.kubernetes.io/version: {{ $root.Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ $root.Release.Service }}
app.kubernetes.io/name: {{ include "temporal-scaling-demo.name" $root }}
app.kubernetes.io/instance: {{ $root.Release.Name }}
{{- if $component }}
app.kubernetes.io/component: {{ $component }}
{{- end }}
{{- end }}

{{/*
Selector labels with component
*/}}
{{- define "temporal-scaling-demo.selectorLabels" -}}
{{- $root := index . 0 -}}
{{- $component := index . 1 -}}
app.kubernetes.io/name: {{ include "temporal-scaling-demo.name" $root }}
app.kubernetes.io/instance: {{ $root.Release.Name }}
{{- if $component }}
app.kubernetes.io/component: {{ $component }}
{{- end }}
{{- end }}
