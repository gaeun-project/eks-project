usage:
	@echo "tf.all-setup : Setup Terraform VPC -> EKS -> HELM "
	@echo "tf.all-clean : Delete Terraform HELM -> EKS -> VPC"

tf.all-setup:
	@terraform -chdir=iac/terraform/vpc init
	@terraform -chdir=iac/terraform/vpc apply -auto-approve
	@terraform -chdir=iac/terraform/eks init
	@terraform -chdir=iac/terraform/eks apply -auto-approve	
	@terraform -chdir=iac/terraform/helm init
	@terraform -chdir=iac/terraform/helm apply -auto-approve
	

tf.all-clean:
	@terraform -chdir=iac/terraform/helm init
	@terraform -chdir=iac/terraform/helm destroy -auto-approve
	@terraform -chdir=iac/terraform/eks init
	@terraform -chdir=iac/terraform/eks destroy -auto-approve	
	@terraform -chdir=iac/terraform/vpc init
	@terraform -chdir=iac/terraform/vpc destroy -auto-approve

