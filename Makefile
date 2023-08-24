usage:
	@echo "tf.all-setup : Setup Terraform VPC -> EKS -> HELM "
	@echo "tf.all-clean : Delete Terraform HELM -> EKS -> VPC"
	@echo "argo.setup : Setup argoworkflow"
	@echo "arog.update : Update argoworkflow"
	@echo "argo.clean : Delete argoworkflow"

tf.all-setup:
	@terraform -chdir=iac/terraform/vpc init
	@terraform -chdir=iac/terraform/vpc apply -auto-approve
	@terraform -chdir=iac/terraform/eks init
	@terraform -chdir=iac/terraform/eks apply -auto-approve	
	@terraform -chdir=iac/terraform/helm init
	@terraform -chdir=iac/terraform/helm apply -auto-approve
	@terraform -chdir=iac/terraform/iam init
	@terraform -chdir=iac/terraform/iam apply -auto-approve
	

tf.all-clean:
	@terraform -chdir=iac/terraform/helm init
	@terraform -chdir=iac/terraform/helm destroy -auto-approve
	@terraform -chdir=iac/terraform/eks init
	@terraform -chdir=iac/terraform/eks destroy -auto-approve	
	@terraform -chdir=iac/terraform/vpc init
	@terraform -chdir=iac/terraform/vpc destroy -auto-approve
	@terraform -chdir=iac/terraform/iam init
	@terraform -chdir=iac/terraform/iam destroy -auto-approve
	

argo.setup:
	@kubectl create ns argo
	@helm upgrade --install --values ./helm/systems/argo/values.yaml argo argo/argo-workflows -n argo
	@kubectl apply -f ./helm/systems/argo/token.yaml -n argo
	@kubectl apply -f ./helm/systems/argo/argoworkflow/role.yaml -n argo
	@kubectl apply -f ./helm/systems/argo/argoworkflow/argoworkflows.yaml -n argo
	@ARGO_TOKEN="Bearer $(kubectl get secret argo-workflows-sa.service-account-token -o=jsonpath='{.data.token}' -n argo | base64 --decode)"
	@echo ${ARGO_TOKEN}

argo.update:
	@kubectl apply -f ./helm/systems/argo/argoworkflow/argoworkflows.yaml -n argo

argo.clean:
	@kubectl delete -f ./helm/systems/argo/token.yaml -n argo
	@kubectl delete -f ./helm/systems/argo/argoworkflow/role.yaml -n argo
	@kubectl delete -f ./helm/systems/argo/argoworkflow/argoworkflows.yaml -n argo
	@helm uninstall argo