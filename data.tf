data "aws_caller_identity" "current" {}

### SSM - VALUES ###
data "aws_ssm_parameter" "ssm_vpc_id" {
  name = "${var.infra_id}-${var.env}-${var.cluster}-vpc-id"
}