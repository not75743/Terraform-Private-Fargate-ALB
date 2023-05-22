terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.65.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
  default_tags {
    tags = {
      system_name = "fargate-nginx"
      env         = "dev"
      provision   = "terraform"
    }
  }
}

## Common Vars
variable "system_name" {
  type    = string
  default = "fargate-nginx"
}
variable "environment" {
  type    = string
  default = "dev"
}

## Network

module "network" {
  source        = "../../modules/network"
  system_name   = var.system_name
  environment   = var.environment
  cidr_vpc      = "10.10.0.0/16"
  cidr_public1  = "10.10.1.0/24"
  cidr_public2  = "10.10.2.0/24"
  cidr_private1 = "10.10.3.0/24"
  cidr_private2 = "10.10.4.0/24"
  az_public1    = "ap-northeast-1a"
  az_public2    = "ap-northeast-1c"
  az_private1   = "ap-northeast-1a"
  az_private2   = "ap-northeast-1c"
}

module "LB" {
  source      = "../../modules/LB"
  system_name = var.system_name
  environment = var.environment
  vpcid       = module.network.VPCID
  public1     = module.network.public1ID
  public2     = module.network.public2ID
  lb-port     = 80
}

module "app" {
  source          = "../../modules/app"
  system_name     = var.system_name
  environment     = var.environment
  vpcid           = module.network.VPCID
  private1        = module.network.private1ID
  private2        = module.network.private2ID
  container-name  = "nginx"
  container-image = "<ECRに格納したイメージのURL>"
  app-port        = 80
  lb_sg           = module.LB.lb_sg
  targetgroup_arn = module.LB.targetgroup_arn
}

output "alb_public_dns" {
  value = module.LB.alb_public_dns
}