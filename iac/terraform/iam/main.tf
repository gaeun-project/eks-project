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



resource "aws_iam_role" "role" {
  name = "custodian_role"
    # 생성할 IAM Role 이름

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
            Service = "lambda.amazonaws.com"
                # IAM Role 생성 시, EC2 Profile 역할로 사용됨을 지정
        }
        Action = "sts:AssumeRole"
            # AdministratorAccess 권한이 존재 하더라도, AssumeRole로 접근 필수적
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role = aws_iam_role.role.name
}


# module "iam_assumable_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

#   trusted_role_arns = [
#     "arn:aws:iam::750876142122:root"
#   ]

#   create_role = true

#   role_name         = "mad-project"
#   role_requires_mfa = false

#   custom_role_policy_arns = [
#     "arn:aws:iam::aws:policy/ReadOnlyAccess"
#   ]
#   number_of_custom_role_policy_arns = 1
# }
