usage:
	@echo "tf.all-setup : Setup Terraform VPC -> EKS -> HELM "
	@echo "tf.all-clean : Delete Terraform HELM -> EKS -> VPC"

tf.all-setup:
	@terraform -chdir=terraform/eks-project/vpc init
	@terraform -chdir=terraform/eks-project/vpc apply -auto-approve
	@terraform -chdir=terraform/eks-project/eks init
	@terraform -chdir=terraform/eks-project/eks apply -auto-approve	
	@terraform -chdir=terraform/eks-project/helm init
	@terraform -chdir=terraform/eks-project/helm apply -auto-approve
	

tf.all-clean:
	@terraform -chdir=terraform/eks-project/helm init
	@terraform -chdir=terraform/eks-project/helm destroy -auto-approve
	@terraform -chdir=terraform/eks-project/eks init
	@terraform -chdir=terraform/eks-project/eks destroy -auto-approve	
	@terraform -chdir=terraform/eks-project/vpc init
	@terraform -chdir=terraform/eks-project/vpc destroy -auto-approve

