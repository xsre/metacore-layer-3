## DNS provider where the DNS records will be created. Available providers are:
## - alibabacloud, aws, azure, azure-private-dns, cloudflare, coredns, designate, digitalocean, google, hetzner, infoblox, linode, rfc2136, transip
##
provider: aws

nodeSelector:
    apis: duces

aws:
  ## AWS region
  ##
  region: ${region}
  ## Zone Filter. Available values are: public, private
  ##
  zoneType: "public"
  ## AWS Role to assume
  ##

## ServiceAccount parameters
## https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/
##
serviceAccount:
  create: false
  ## Service Account for pods
  ##
  name: external-dns


## RBAC parameteres
## https://kubernetes.io/docs/reference/access-authn-authz/rbac/
##
rbac:
  create: false
  ## Deploys ClusterRole by Default
  ##
  ## Podsecuritypolicy
  ##
  pspEnabled: false


## K8s resources type to be observed for new DNS entries by ExternalDNS
##
sources:
  # - crd
  # - ambassador-host
  - service
  # - istio-gateway

  # - contour-httpproxy

## Modify how DNS records are synchronized between sources and providers (options: sync, upsert-only)
##
policy: sync

## Verbosity of the ExternalDNS logs. Available values are:
## - panic, debug, info, warn, error, fatal
##
logLevel: info