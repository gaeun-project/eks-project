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
  name = "eks-project-dev"
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
  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium", "t3.small"]
  }

  eks_managed_node_groups = {

    study-dev-spot-a = {
      min_size     = 2
      max_size     = 10
      desired_size = 2

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
      labels = {
        Environment = "ONLY_SPOT"
        GithubRepo  = "eks-project"
        GithubOrg   = "gaeun-project"
      }
    }
    study-dev-spot-b = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "SPOT"
      labels = {
        Environment = "ONLY_SPOT"
        GithubRepo  = "eks-project"
        GithubOrg   = "gaeun-project"
      }
    }
  }
  # aws-auth configmap
  manage_aws_auth_configmap = false

}