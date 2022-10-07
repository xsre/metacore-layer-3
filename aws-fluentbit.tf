resource "aws_iam_policy" "fluentbit" {
  name_prefix = "${var.infra_id}-${var.env}-fluentbit-policy"
  description = "IAM policy for fluentbit"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "fluentBitLogManagement"
        Action = [
          "logs:PutLogEvents",
          "logs:Describe*",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutRetentionPolicy"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "fluentbit-role" {
  name_prefix        = "fluentbit"
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
          "${replace(data.aws_eks_cluster.eks.identity.0.oidc.0.issuer, "https://", "")}:sub": "system:serviceaccount:logs:fluentbit-sa"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "fluentbit" {
  policy_arn = aws_iam_policy.fluentbit.arn
  role       = aws_iam_role.fluentbit-role.name
}

resource "kubernetes_namespace" "logs" {
  metadata {
    name = "logs"
  }
}

resource "kubernetes_service_account" "fluentbit" {
  metadata {
    name      = "fluentbit-sa"
    namespace = kubernetes_namespace.logs.id
    annotations = {
      "eks.amazonaws.com/role-arn" = "${aws_iam_role.fluentbit-role.arn}"
    }
  }

  automount_service_account_token = true
  depends_on                      = [kubernetes_namespace.logs]
}

resource "helm_release" "logs" {
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  version    = "0.1.21" # (8 Sep, 2022)
  name       = "aws-fluent-bit"
  namespace  = kubernetes_namespace.logs.id

  values = [
    templatefile("${path.module}/../../../env/${var.team}/${var.env}/${var.region}/${var.infra_id}/${var.cluster}/helm/aws-fluentbit.tpl", {
      logGroupName = "${local.cluster_name}-fluentbit"
      region       = var.region
    })
  ]

  depends_on = [kubernetes_namespace.logs]
}

resource "random_integer" "proxy_port_logs" {
  min = 10000
  max = 60000
}

resource "null_resource" "logs_finalizer" {
  provisioner "local-exec" {
    command = <<EOF
kubectl proxy -p ${tostring(random_integer.proxy_port_logs.result)} &
export PROXY_PID=$!
kubectl get namespace ${kubernetes_namespace.logs.metadata.0.name} -o json | jq '.spec = {"finalizers":[]}' > /tmp/${kubernetes_namespace.logs.metadata.0.name}-finalizers.json
curl -k -H "Content-Type: application/json" -X PUT --data-binary @/tmp/${kubernetes_namespace.logs.metadata.0.name}-finalizers.json localhost:${tostring(random_integer.proxy_port.result)}/api/v1/namespaces/${kubernetes_namespace.logs.metadata.0.name}/finalize
kill $PROXY_PID
rm /tmp/${kubernetes_namespace.logs.metadata.0.name}-finalizers.json
EOF
  }
  depends_on = [kubernetes_namespace.logs]
}