terraform {
  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = "mad-eks-project-tfstates-dev"
    key            = "mad-eks-project-tfstates-dev/eks-project-lambda-dev.tfstate"
    profile        = "gaeun-dev"
    dynamodb_table = "terraform-lock"
  }
}
provider "aws" {
  region  = "ap-northeast-2"
  profile = "gaeun-dev"
}

module "iam_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "tagging-feature-policy"
  path        = "/"
  description = "for tagging feature"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "ec2:CreateTags",
                "ec2:DeleteTags",
                "ec2:DescribeTags"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudtrail:DescribeTrails",
                "cloudtrail:GetEventSelectors",
                "cloudtrail:ListPublicKeys",
                "cloudtrail:LookupEvents",
                "cloudtrail:GetTrailStatus",
                "cloudtrail:ListTags"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

module "iam_assumable_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_services = [
    "lambda.amazonaws.com"
  ]

  create_role = true

  role_name         = "LambdaExecRole-MadProject"
  role_requires_mfa = false

}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = module.iam_assumable_role.iam_role_name
  policy_arn = module.iam_policy.arn
}

# module "lambda_function" {
#   source  = "terraform-aws-modules/lambda/aws"
#   version = "~> 2.0"

#   function_name = "lambda_function_name"
#   handler       = "index.handler"
#   runtime       = "python3.10"

#   source_path = {
#     path             = "src/"
#     runtime          = "nodejs14.x"
#     patterns         = ["**/*"]
#   }

#   environment_variables = {
#     foo = "bar"
#   }
# }
