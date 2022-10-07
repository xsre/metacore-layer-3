resource "kubernetes_config_map" "metacore" {
  metadata {
    name = "metacore"
  }
  data = {
    account_id = data.aws_caller_identity.current.account_id
    cluster_name = local.cluster_name
  }
}