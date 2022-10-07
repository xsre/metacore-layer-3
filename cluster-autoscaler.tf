resource "helm_release" "cluster-autoscaler" {
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = "9.21.0"
  name       = "cluster-autoscaler"
  namespace  = "kube-system"

  set {
    name  = "autoDiscovery.clusterName"
    value = local.cluster_name
  }

  values = [
    templatefile("${path.module}/../../../env/${var.team}/${var.env}/${var.region}/${var.infra_id}/${var.cluster}/helm/cluster-autoscaler.tpl", {
      region  = var.region
      version = "v1.23.0"
    })
  ]
}