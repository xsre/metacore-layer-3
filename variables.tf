variable "region" {
  description = "AWS Region Id"
}

variable "infra_id" {
  description = "Shoud be an unique identifier"
}

variable "env" {
  description = "Environment: dev/stag/prod"
}

variable "team" {
  description = "Team who has the ownership"
}

variable "cluster" {
  description = "blue/green deployments"
}

variable "domain" {
  description = "Route53 provisioned domain"
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone id"
}