terraform {
  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "mad-eks-project-tfstates-dev"
    key            = "mad-eks-project-tfstates-dev/eks-project-iam-dev.tfstate"
    profile        = "gaeun-dev"
    dynamodb_table = "terraform-lock"
  }
}
provider "aws" {
  region  = "ap-northeast-2"
  profile = "gaeun-dev"
}


module "iam_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_arns = [
    "arn:aws:iam::750876142122:root"
  ]

  create_role = true

  role_name         = "mad-project"
  role_requires_mfa = false

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
  ]
  number_of_custom_role_policy_arns = 1
}
