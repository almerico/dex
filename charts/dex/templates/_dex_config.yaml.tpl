{{ $issuerDomain := .Values.domain }}
issuer: https://{{ $issuerDomain }}
storage:
  type: kubernetes
  config:
    inCluster: true
logger:
  level: debug
{{- range .Values.ports }}
{{- if eq .name "http" }}
web:
  http: 0.0.0.0:{{ .internalPort }}
{{- end }}
{{- if eq .name "grpc" }}
grpc:
  addr: 0.0.0.0:{{ .internalPort }}
  tlsCert: /etc/dex/tls/grpc/server/tls.crt
  tlsKey: /etc/dex/tls/grpc/server/tls.key
  tlsClientCA: /etc/dex/tls/grpc/ca/tls.crt
{{- end }}
{{- end }}
connectors:
{{- range $id, $connector := .Values.connectors }}
{{- if ( $connector.config.clientID ) and ( $connector.config.clientSecret ) }}
- type: {{ $connector.config.type }}
  id: {{ $id }}
  name: {{ $connector.config.name }}
  config:
    clientID: {{ $connector.config.clientID }}
    clientSecret: {{ $connector.config.clientSecret }}
    redirectURI: https://{{ $issuerDomain }}/callback
{{- if $connector.config.issuer }}
    issuer: {{ $connector.config.issuer }}
{{- end }}
{{- if $connector.config.orgs }}
    orgs:
{{- range $connector.config.orgs }}
      - name: {{ . }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
oauth2:
  skipApprovalScreen: true

enablePasswordDB: true

frontend:
  theme: cloudbees
