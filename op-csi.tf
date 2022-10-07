# Kubernetes secrets store CSI driver
# https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_csi_driver.html
# https://secrets-store-csi-driver.sigs.k8s.io/introduction.html
resource "helm_release" "csi" {
  name       = "csi-secrets-store"
  chart      = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  version    = "1.2.3"
  namespace  = "kube-system"

  set {
    name  = "grpcSupportedProviders"
    value = "aws"
  }

  set {
    name  = "syncSecret.enabled"
    value = "true"
  }
}

#AWS Secrets & Configuration Provider (ASCP)
resource "null_resource" "ascp" {
  provisioner "local-exec" {
    command = "kubectl apply -f https://raw.githubusercontent.com/aws/secrets-store-csi-driver-provider-aws/main/deployment/aws-provider-installer.yaml"
  }

  depends_on = [helm_release.csi]
}
