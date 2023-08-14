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

data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket         = "mad-eks-project-tfstates-dev"
    region         = "ap-northeast-2"
    key            = "mad-eks-project-tfstates-dev/eks-project-iam-dev.tfstate"
    profile        = "gaeun-dev"
    dynamodb_table = "terraform-lock"
  }
}

variable "image_uri" {
  description = "The URI of the Docker image in ECR"
  type        = string
}


resource "aws_lambda_function" "lambda" {
  function_name = "lambda"

  # ECR에 저장된 컨테이너 이미지 URI
  image_uri = var.image_uri
  package_type  = "Image"
  # 이미 정해진 IAM 역할
  role = data.terraform_remote_state.iam.outputs.role_arn

  # Lambda 함수 실행에 필요한 메모리 크기 (예: 128MB)
  memory_size = 128

  # Lambda 함수의 타임아웃 (예: 10초)
  timeout = 60

  # 아키텍처 지정 (예: ARM 또는 x86_64)
  architectures = ["x86_64"] # 또는 ["x86_64"] 등

}

