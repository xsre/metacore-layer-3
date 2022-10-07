
resource "helm_release" "cert-manager" {
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.9.1" # (26 Jul, 2022)
  name       = "cert-manager"
  namespace  = "cert-manager"

  values = [
    templatefile("${path.module}/values/cert-manager.tpl", {
      #domain_name             = var.domain_name
    })
  ]
  depends_on = [kubernetes_namespace.cert-manager]

}

resource "random_integer" "proxy_port_cert_manager" {
  min = 10000
  max = 60000
}

resource "null_resource" "cert-manager_finalizer" {
  provisioner "local-exec" {
    command = <<EOF
kubectl proxy -p ${tostring(random_integer.proxy_port_cert_manager.result)} &
export PROXY_PID=$!
kubectl get namespace ${kubernetes_namespace.cert-manager.metadata.0.name} -o json | jq '.spec = {"finalizers":[]}' > /tmp/${kubernetes_namespace.cert-manager.metadata.0.name}-finalizers.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @/tmp/${kubernetes_namespace.cert-manager.metadata.0.name}-finalizers.json localhost:${tostring(random_integer.proxy_port.result)}/api/v1/namespaces/${kubernetes_namespace.cert-manager.metadata.0.name}/finalize
kill $PROXY_PID
rm /tmp/${kubernetes_namespace.cert-manager.metadata.0.name}-finalizers.json
EOF
  }
  depends_on = [kubernetes_namespace.cert-manager]
}

resource "kubernetes_namespace" "cert-manager" {
  metadata {
    name = "cert-manager"
  }
}