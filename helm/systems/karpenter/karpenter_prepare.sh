
export KARPENTER_VERSION='v0.29.2'

export AWS_PROFILE=gaeun-dev

export CLUSTER_NAME='eks-project-prd'

export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws iam add-role-to-instance-profile \
    --instance-profile-name "KarpenterNodeInstanceProfile-${CLUSTER_NAME}" \
    --role-name "KarpenterNodeRole-${CLUSTER_NAME}"

for NODEGROUP in $(aws eks list-nodegroups --cluster-name ${CLUSTER_NAME} \
    --query 'nodegroups' --output text); do aws ec2 create-tags \
        --tags "Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}" \
        --resources $(aws eks describe-nodegroup --cluster-name ${CLUSTER_NAME} \
        --nodegroup-name $NODEGROUP --query 'nodegroup.subnets' --output text )
done

NODEGROUP=$(aws eks list-nodegroups --cluster-name ${CLUSTER_NAME} \
    --query 'nodegroups[0]' --output text)

LAUNCH_TEMPLATE=$(aws eks describe-nodegroup --cluster-name ${CLUSTER_NAME} \
    --nodegroup-name ${NODEGROUP} --query 'nodegroup.launchTemplate.{id:id,version:version}' \
    --output text | tr -s "\t" ",")

SECURITY_GROUPS=$(aws eks describe-cluster \
    --name ${CLUSTER_NAME} --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)

SECURITY_GROUPS=$(aws ec2 describe-launch-template-versions \
    --launch-template-id ${LAUNCH_TEMPLATE%,*} --versions ${LAUNCH_TEMPLATE#*,} \
    --query 'LaunchTemplateVersions[0].LaunchTemplateData.[NetworkInterfaces[0].Groups||SecurityGroupIds]' \
    --output text)


aws ec2 create-tags \
    --tags "Key=karpenter.sh/discovery,Value=${CLUSTER_NAME}" \
    --resources ${SECURITY_GROUPS}


ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/KarpenterNodeRole-${CLUSTER_NAME}"

existing_mappings=$(eksctl get iamidentitymapping --cluster ${CLUSTER_NAME} -o json)
if ! echo "${existing_mappings}" | jq -e --arg ARN "$ARN" '.[] | select(.rolearn == $ARN)'; then
    eksctl create iamidentitymapping \
      --username system:node:{{EC2PrivateDNSName}} \
      --cluster ${CLUSTER_NAME} \
      --arn ${ARN} \
      --group system:bootstrappers \
      --group system:nodes
else
    echo "Mapping for ${ARN} already exists!"
fi
kubectl get crd provisioners.karpenter.sh &> /dev/null

if [ $? -ne 0 ]; then
    kubectl create -f \
        https://raw.githubusercontent.com/aws/karpenter/${KARPENTER_VERSION}/pkg/apis/crds/karpenter.sh_provisioners.yaml
    kubectl create -f \
        https://raw.githubusercontent.com/aws/karpenter/${KARPENTER_VERSION}/pkg/apis/crds/karpenter.k8s.aws_awsnodetemplates.yaml
    kubectl create -f \
        https://raw.githubusercontent.com/aws/karpenter/${KARPENTER_VERSION}/pkg/apis/crds/karpenter.sh_machines.yaml
fi

echo ${AWS_ACCOUNT_ID}
echo ${CLUSTER_NAME}
echo ${SECURITY_GROUPS}
echo ${NODEGROUP}
