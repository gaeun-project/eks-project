terraform {
  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "mad-eks-project-tfstates-dev"
    key            = "mad-eks-project-tfstates-dev/eks-project-eks-dev.tfstate"
    profile        = "gaeun-dev"
    dynamodb_table = "terraform-lock"
  }
}


provider "aws" {
  region  = "ap-northeast-2"
  profile = "gaeun-dev"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    # This requires the awscli to be installed locally where Terraform is executed
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket         = "mad-eks-project-tfstates-dev"
    region         = "ap-northeast-2"
    key            = "mad-eks-project-tfstates-dev/eks-project-vpc-dev.tfstate"
    profile        = "gaeun-dev"
    dynamodb_table = "terraform-lock"
  }
}

locals {
  name = "eks-project-prd"
  tags = {
    Name        = local.name
    Environment = "dev"
    Project     = "eks-project"
    Team        = "study"
  }
  vpc                   = data.terraform_remote_state.vpc.outputs.vpc
  private_subnets_by_az = local.vpc.private_subnets
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.0"

  cluster_name    = local.name
  cluster_version = "1.23"

  cluster_endpoint_public_access = true
  cluster_enabled_log_types      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  tags                           = local.tags

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  vpc_id     = local.vpc.vpc_id
  subnet_ids = tolist(local.private_subnets_by_az)

  eks_managed_node_groups = {

    nodegroup_karpenter = {
      min_size     = 2
      max_size     = 3
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      labels = {
        label_karpenter = "enabled"
      }
      taints = {
        dedicated = {
          key    = "taint_karpenter"
          value  = "enabled"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }
  # aws-auth configmap
  manage_aws_auth_configmap = false

}

