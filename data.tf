data "aws_caller_identity" "current" {}

provider "aws" {
  region = var.region
}

### SSM - VALUES ###
data "aws_ssm_parameter" "ssm_vpc_id" {
  name = "${var.infra_id}-${var.env}-${var.cluster}-vpc-id"
}