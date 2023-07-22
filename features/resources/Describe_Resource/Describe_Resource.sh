#!/bin/bash

# ${parameter-account} is ACCOUNT Number
# ${parameter-role} is Role Name
# ${parameter-region} is Region
# ${parameter-service} i Service

echo "parameter-account: $account"
echo "parameter-role: $role"
echo "parameter-region: $region"
echo "parameter-service: $service"

ROLE_ARN="arn:aws:iam::${account}:role/${role}"
SESSION_NAME=${role}
AWS_REGION=${region}

# Role을 가정하고 임시 보안 자격 증명 얻기
CREDENTIALS=$(aws sts assume-role --role-arn $ROLE_ARN --role-session-name $SESSION_NAME --region $AWS_REGION --output json)

# 임시 보안 자격 증명을 환경 변수로 설정
export AWS_ACCESS_KEY_ID=$(echo $CREDENTIALS | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $CREDENTIALS | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $CREDENTIALS | jq -r .Credentials.SessionToken)

# AWS CLI 명령을 이 새로운 자격 증명으로 실행
# 예를 들면, S3 버킷의 리스트를 가져오는 명령을 실행할 수 있습니다.
aws ec2 describe-instances \
  --query 'Reservations[*].Instances[*].{ImageId:ImageId, InstanceId:InstanceId, InstanceType:InstanceType}' \
  --output json > output.json

jq -c '.[]' output.json | cut -c 2- | rev | cut -c 2- | rev > instances.json


#액세스 키 취소
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
hours=$(date +%H)
minutes=$(date +%M)
seconds=$(date +%S)

aws s3 cp instances.json s3://mad-master-bucket/${service}/account=${account}/service=ec2/year=${year}/month=${month}/day=${day}/hours=${hours}/AWS_Info.json
rm output.json instances.json