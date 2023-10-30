# Terraform

#### Terraform 구성

- 직접 생성한 모듈/Terraform 공식 모듈로 리소스 생성하는 방식을 선택.
- tfstate 파일은 AWS 계정내 S3에 저장.
- 각 리소스 별 따로 생성(vpc,eks,helm,iam,custodian)

**Reference)**

https://registry.terraform.io/browse/modules
