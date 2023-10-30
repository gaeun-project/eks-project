terraform {
  backend "s3" {
    region         = "ap-northeast-2"
    bucket         = var.s3_bucket
    key            = var.key
  }
}

provider "aws" {
  region  = "ap-northeast-2"
  profile = var.aws_profile
}


resource "aws_iam_role" "lambda_role" {
  name = "custodian_role"

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
  role = aws_iam_role.lambda_role.name
}


# variable "image_uri" {
#   description = "The URI of the Docker image in ECR"
#   type        = string
# }


resource "aws_lambda_function" "lambda" {
  function_name = "lambda"

  # ECR에 저장된 컨테이너 이미지 URI
  image_uri = var.image_uri
  package_type = "Image"
  # 이미 정해진 IAM 역할
  role = aws_iam_role.lambda_role.arn

  # Lambda 함수 실행에 필요한 메모리 크기 (예: 128MB)
  memory_size = 128

  # Lambda 함수의 타임아웃 (예: 10초)
  timeout = 60

  # 아키텍처 지정 (예: ARM 또는 x86_64)
  architectures = ["x86_64"] # 또는 ["x86_64"] 등

}

# resource "aws_config_config_rule" "config_rule" {
#   name = "custodian-config-rule"

#   source {
#     owner             = "CUSTOM_LAMBDA"
#     source_identifier = aws_lambda_function.lambda.arn

#     source_detail {
#       event_source = "aws.config"
#       message_type = "ConfigurationItemChangeNotification" # 구성 변경 시 실행
#     }
#   }

#   scope {
#     compliance_resource_types = ["AWS::AllSupported"] # 전체 리소스 범위
#   }

#   depends_on = [aws_lambda_function.lambda]
# }
resource "aws_lambda_permission" "allow_config_call" {
  statement_id  = "AllowExecutionFromAWSConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "config.amazonaws.com"
#   source_arn    = aws_config_config_rule.config_rule.arn

  depends_on = [aws_lambda_function.lambda]
}

resource "aws_config_config_rule" "config_rule" {
  name             = "custodian-config-rule"
  description      = "Monitor configuration changes using custom lambda function"

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.lambda.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }
  }
}