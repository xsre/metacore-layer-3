resource "kubernetes_namespace" "emissary" {
  metadata {
    name = "emissary"
  }
}

resource "null_resource" "emissary-crds" {
  provisioner "local-exec" {
    command = <<EOF
        kubectl apply -f https://app.getambassador.io/yaml/emissary/3.1.0/emissary-crds.yaml
        kubectl wait --timeout=90s --for=condition=available deployment emissary-apiext -n emissary-system
EOF
  }
  depends_on = [kubernetes_namespace.emissary]
}

# https://www.getambassador.io/docs/emissary/latest/tutorials/getting-started/
resource "helm_release" "emissary-ingress" {
  repository = "https://app.getambassador.io"
  chart      = "emissary-ingress"
  #version    = "v1.4.0" # (23 Aug, 2022)
  name       = "emissary-ingress"
  namespace  = "emissary"

  values = [
    templatefile("${path.module}/values/emissary-ingress.tpl", {
    })
  ]  

  depends_on = [null_resource.emissary-crds]

}

resource "null_resource" "emissary-wait" {
  provisioner "local-exec" {
    command = <<EOF
        kubectl -n emissary wait --for condition=available --timeout=90s deploy -lapp.kubernetes.io/instance=emissary-ingress
EOF
  }
  depends_on = [helm_release.emissary-ingress]
}

# After deploying the Service above and manually enabling the proxy protocol you will need to deploy the following 
# Ambassador Module to tell Emissary-ingress to use the proxy protocol and then restart Emissary-ingress for the configuration to take effect.
# https://www.getambassador.io/docs/emissary/latest/topics/running/ambassador-with-aws/
resource "null_resource" "emissary-proxy-protocol" {
  provisioner "local-exec" {
    command = "kubectl apply -f - <<EOF\n${var.proxy_protocol}\nEOF"
  }
  depends_on = [null_resource.emissary-wait] 
}

variable "proxy_protocol" {
  default = <<EOF
    apiVersion: getambassador.io/v3alpha1
    kind: Module
    metadata:
      name: ambassador
      namespace: emissary
    spec:
      config:
        use_proxy_proto: true
    EOF   
}

