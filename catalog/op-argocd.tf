# argo-cd operator
resource "random_integer" "proxy_port_argo" {
  min = 10000
  max = 60000
}

resource "null_resource" "argo_finalizer" {
  provisioner "local-exec" {
    command = <<EOF
kubectl proxy -p ${tostring(random_integer.proxy_port_argo.result)} &
export PROXY_PID=$!
kubectl get namespace ${kubernetes_namespace.argocd.metadata.0.name} -o json | jq '.spec = {"finalizers":[]}' > /tmp/${kubernetes_namespace.argocd.metadata.0.name}-finalizers.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @/tmp/${kubernetes_namespace.argocd.metadata.0.name}-finalizers.json localhost:${tostring(random_integer.proxy_port.result)}/api/v1/namespaces/${kubernetes_namespace.argocd.metadata.0.name}/finalize
kill $PROXY_PID
rm /tmp/${kubernetes_namespace.argocd.metadata.0.name}-finalizers.json
EOF
  }
  depends_on = [kubernetes_namespace.argocd]
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.4.3" # (8 Sep, 2022)
  name       = "argocd"
  namespace  = "argocd"

  values = [
    templatefile("${path.module}/values/argocd.tpl", {
    })
  ]

  depends_on = [kubernetes_namespace.argocd]
}

# If password lost reset the admin password
# kubectl -n argocd patch secret argocd-secret -p '{"stringData": {"admin.password": "$2a$10$oopQdD.FxyJsq..cTgjNGu/xWZ6xSDwjohzhkxXBbMhPbMAt2NqPO","admin.passwordMtime": "'$(date +%FT%T%Z)'"}}'
