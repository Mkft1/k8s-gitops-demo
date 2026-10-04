.PHONY: bootstrap lint test clean

bootstrap:
	./bootstrap.sh

lint:
	helm lint charts/nginx-app
	cd terraform/environments/dev && terraform fmt -check && terraform validate

test:
	helm template my-app charts/nginx-app | kube-linter lint -
	helm test my-app || true

clean:
	kind delete cluster --name kubernetes-learning
	rm -rf terraform/environments/dev/.terraform terraform/environments/dev/terraform.tfstate
