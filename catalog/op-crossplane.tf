data "aws_iam_policy" "crossplane-admin" {
  arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "random_integer" "proxy_port_crossplane" {
  min = 10000
  max = 60000
}

resource "null_resource" "crossplane_finalizer" {
  provisioner "local-exec" {
    command = <<EOF
kubectl proxy -p ${tostring(random_integer.proxy_port_crossplane.result)} &
export PROXY_PID=$!
kubectl get namespace ${kubernetes_namespace.crossplane.metadata.0.name} -o json | jq '.spec = {"finalizers":[]}' > /tmp/${kubernetes_namespace.crossplane.metadata.0.name}-finalizers.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @/tmp/${kubernetes_namespace.crossplane.metadata.0.name}-finalizers.json localhost:${tostring(random_integer.proxy_port.result)}/api/v1/namespaces/${kubernetes_namespace.crossplane.metadata.0.name}/finalize
kill $PROXY_PID
rm /tmp/${kubernetes_namespace.crossplane.metadata.0.name}-finalizers.json
EOF
  }
  depends_on = [kubernetes_namespace.crossplane]
}

resource "kubernetes_namespace" "crossplane" {
  metadata {
    name = "crossplane"
  }
}

resource "aws_iam_role" "crossplane-role" {
  name_prefix        = "crossplane"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.eks.identity.0.oidc.0.issuer, "https://", "")}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringLike": {
          "${replace(data.aws_eks_cluster.eks.identity.0.oidc.0.issuer, "https://", "")}:sub": "system:serviceaccount:crossplane:provider-aws-*"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "crossplane" {
  policy_arn = data.aws_iam_policy.crossplane-admin.arn
  role = aws_iam_role.crossplane-role.name
}

resource "helm_release" "crossplane" {
  repository = "https://charts.crossplane.io/stable"
  chart      = "crossplane"
  version    = "1.9.1"  
  name       = "crossplane"
  namespace  = "crossplane"

  values = [
    templatefile("${path.module}/values/crossplane.tpl", {
    })
  ]

  depends_on = [kubernetes_namespace.crossplane, aws_iam_role.crossplane-role]
}

resource "local_file" "crossplane-provider" {
  content    = <<EOT
apiVersion: pkg.crossplane.io/v1alpha1
kind: ControllerConfig
metadata:
  name: aws-config
  annotations:
    eks.amazonaws.com/role-arn: ${aws_iam_role.crossplane-role.arn}
spec:
  nodeSelector:
    apis: duces
  podSecurityContext:
    fsGroup: 2000
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-aws
spec:
  package: crossplane/provider-aws:v0.31.0
  controllerConfigRef:
    name: aws-config
---
apiVersion: aws.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: aws-provider
spec:
  credentials:
    source: InjectedIdentity
EOT
  filename = "${path.module}/../../../../env/${var.team}/${var.env}/${var.zone}/${var.infra_id}/${var.cluster}/crossplane.yaml"

  depends_on = [helm_release.crossplane]
}

resource "null_resource" "crossplane-provider" {
  provisioner "local-exec" {
    command = "kubectl apply -f ${path.module}/../../../../env/${var.team}/${var.env}/${var.zone}/${var.infra_id}/${var.cluster}/crossplane.yaml"
  }

  depends_on = [local_file.crossplane-provider]
}