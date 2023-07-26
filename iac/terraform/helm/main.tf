terraform {
  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "mad-eks-project-tfstates-dev"
    key            = "mad-eks-project-tfstates-dev/eks-project-helm-dev.tfstate"
    profile        = "gaeun-dev"
    dynamodb_table = "terraform-lock"
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = "gaeun-dev"
  alias = "gaeun-dev"
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket         = "mad-eks-project-tfstates-dev"
    region         = "ap-northeast-2"
    key            = "mad-eks-project-tfstates-dev/eks-project-eks-dev.tfstate"
    profile        = "gaeun-dev"
    dynamodb_table = "terraform-lock"
  }
}

locals {
  name = "eks-project-dev"
  tags = {
    Name        = local.name
    Environment = "dev"
    Team        = "study"
    Project     = "eks-project"
  }
  profile          = "gaeun-dev"
  eks              = data.terraform_remote_state.eks.outputs.eks
  provider_url     = local.eks.oidc_provider
  eks_cluster_name = local.eks.cluster_name
}

module "helm_services" {
  source = "git@github.com:gaeun-project/modules.git//terraform/helm/common?ref=main"

  name                        = local.name
  tags                        = local.tags
  provider_url                = local.provider_url
  eks_cluster_name            = local.eks_cluster_name
  output_eks                  = local.eks
  profile                     = local.profile
  external_dns_zones          = ["multi-account-dashboard.com"]

  providers = {
    aws.dev = aws.gaeun-dev
  }
}