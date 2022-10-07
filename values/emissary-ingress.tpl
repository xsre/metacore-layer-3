# Override the generated chart name. Defaults to .Chart.Name.
nameOverride: ''
# Override the generated release name. Defaults to .Release.Name.
fullnameOverride: ''
# Override the generated release namespace. Defaults to .Release.Namespace.
namespaceOverride: ''

# Number of Ambassador replicas
replicaCount: 3
# If true, Create a DaemonSet. By default Deployment controller will be created
daemonSet: false

service:
  type: LoadBalancer

  # Note that target http ports need to match your ambassador configurations service_port
  # https://www.getambassador.io/reference/modules/#the-ambassador-module
  ports:
  - name: http
    port: 80
    targetPort: 8080
      # protocol: TCP
      # nodePort: 30080
      # hostPort: 80
  - name: https
    port: 443
    targetPort: 8443
      # protocol: TCP
      # nodePort: 30443
      # hostPort: 443
    # TCPMapping_Port
      # port: 2222
      # targetPort: 2222
      # protocol: TCP
      # nodePort: 30222

  annotations: {
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb",
    service.beta.kubernetes.io/aws-load-balancer-internal: "true",
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
  }

deploymentStrategy:
  type: RollingUpdate

# CPU/memory resource requests/limits
resources: # +doc-gen:break
  # Recommended resource requests and limits for Ambassador
  limits:
    cpu: 1000m
    memory: 600Mi
  requests:
    cpu: 200m
    memory: 300Mi

# NodeSelector for ambassador pods
nodeSelector:
    apis: duces

createNamespace: false

