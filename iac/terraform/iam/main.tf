
provider "aws" {
  region  = "ap-northeast-2"
  profile = "gaeun-dev"
}

terraform {
  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "mad-eks-project-tfstates-dev"
    key            = "mad-eks-project-tfstates-dev/eks-project-iam-dev.tfstate"
    profile        = "gaeun-dev"
    dynamodb_table = "terraform-lock"
  }
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

data "aws_caller_identity" "current" {}



locals {
  name = "eks-project-prd"
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
  account_id = data.aws_caller_identity.current.account_id
}

module "iam_service_account" {
  source = "git@github.com:gaeun-project/modules.git//terraform/iam/serviceaccount?ref=main"
  create_role                 = true

  # 여기 고쳐야함...account_id가 자동으로 매핑되도록
  account_id = local.account_id
  iam_service = {
    "argo-workflow" = "argo:workflows-sa"
    "KarpenterControllerRole" = "karpenter:karpenter"
  }
  # name                        = ""
  # namespace                   = ""
  provider_url                = local.provider_url
  eks_cluster_name            = local.eks_cluster_name
  output_eks                  = local.eks
  profile                     = local.profile

}

module "iam-assumable-role" {
source = "git@github.com:gaeun-project/modules.git//terraform/iam/role?ref=main"
create_role                  = true
name                        = "KarpenterNodeRole"
provider_url                = local.provider_url
eks_cluster_name            = local.eks_cluster_name
output_eks                  = local.eks
profile                     = local.profile


}



