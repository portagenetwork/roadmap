{{/*
Generate volume definitions based on storage type
*/}}
{{- define "dmp-roadmap.volumes" -}}
{{- if eq .Values.storage.type "cephfs" }}
{{- range $name, $volume := .Values.storage.cephfs.volumes }}
- name: {{ $name }}
  persistentVolumeClaim:
    claimName: {{ include "dmp-roadmap.fullname" $ }}-{{ $name }}
{{- end }}
{{- else if eq .Values.storage.type "pvc" }}
{{- range $name, $volume := .Values.storage.pvc.volumes }}
- name: {{ $name }}
  persistentVolumeClaim:
    claimName: {{ include "dmp-roadmap.fullname" $ }}-{{ $name }}
{{- end }}
{{- else if eq .Values.storage.type "hostPath" }}
{{- range $name, $volume := .Values.storage.hostPath.volumes }}
- name: {{ $name }}
  hostPath:
    path: {{ $volume.path }}
    type: {{ $volume.type | default "DirectoryOrCreate" }}
{{- end }}
{{- else if eq .Values.storage.type "nfs" }}
{{- range $name, $volume := .Values.storage.nfs.volumes }}
- name: {{ $name }}
  nfs:
    server: {{ $.Values.storage.nfs.server }}
    path: {{ $volume.path }}
{{- end }}
{{- else if eq .Values.storage.type "emptyDir" }}
{{- range $name, $volume := .Values.storage.emptyDir.volumes }}
- name: {{ $name }}
  emptyDir:
    {{- if $volume.sizeLimit }}
    sizeLimit: {{ $volume.sizeLimit }}
    {{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate volume mounts based on storage type
*/}}
{{- define "dmp-roadmap.volumeMounts" -}}
{{- $volumes := dict }}
{{- if eq .Values.storage.type "cephfs" }}
{{- $volumes = .Values.storage.cephfs.volumes }}
{{- else if eq .Values.storage.type "pvc" }}
{{- $volumes = .Values.storage.pvc.volumes }}
{{- else if eq .Values.storage.type "hostPath" }}
{{- $volumes = .Values.storage.hostPath.volumes }}
{{- else if eq .Values.storage.type "nfs" }}
{{- $volumes = .Values.storage.nfs.volumes }}
{{- else if eq .Values.storage.type "emptyDir" }}
{{- $volumes = .Values.storage.emptyDir.volumes }}
{{- end }}
{{- range $name, $volume := $volumes }}
- name: {{ $name }}
  mountPath: {{ $volume.mountPath }}
{{- end }}
{{- end }}
