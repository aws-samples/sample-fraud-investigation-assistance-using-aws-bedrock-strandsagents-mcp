SHELL := /usr/bin/env bash -euo pipefail -c

APP_NAME = ###APP_NAME###
ENV_NAME = ###ENV_NAME###
AWS_ACCOUNT_ID = ###AWS_ACCOUNT_ID###
AWS_DEFAULT_REGION = ###AWS_DEFAULT_REGION###
TF_S3_BACKEND_NAME = ###TF_S3_BACKEND_NAME###

# Run one-time wizard to resolve placeholders with values of your choice
init:
	./init.sh

deploy-tf-backend-cf-stack:
	aws cloudformation deploy \
	--template-file ./iac/bootstrap/tf-backend-cf-stack.yml \
	--stack-name $(TF_S3_BACKEND_NAME) \
	--region $(AWS_DEFAULT_REGION) \
	--tags App=$(APP_NAME) Env=$(ENV_NAME) \
	--region $(AWS_DEFAULT_REGION) \
	--capabilities CAPABILITY_NAMED_IAM

destroy-tf-backend-cf-stack:
	@./build-script/empty-s3.sh empty_s3_bucket_by_name "$(TF_S3_BACKEND_NAME)-$(AWS_ACCOUNT_ID)-$(AWS_DEFAULT_REGION)"
	aws cloudformation delete-stack \
	--stack-name $(TF_S3_BACKEND_NAME)
	aws cloudformation wait stack-delete-complete \
	--stack-name $(TF_S3_BACKEND_NAME) \
	--region $(AWS_DEFAULT_REGION) \
	--capabilities CAPABILITY_NAMED_IAM

# Custom build scripts
build-layers:
	@$(ENV_PATH)../build-script/build-layers.sh "$(ENV_PATH)../app/layers"

build-lambdas:
	@$(ENV_PATH)../build-script/build-lambdas.sh "$(ENV_PATH)../app/lambdas"

init-app:
	@echo "Init app module"
	(cd iac/roots/app; \
		terraform init;)
	@echo "Finished Init app module"

plan-app:
	@echo "Plan app module"
	(cd iac/roots/app; \
		terraform plan;)
	@echo "Finished Planning app module"

deploy-app:
	@echo "Deploying app module"
	(cd iac/roots/app; \
		terraform init; \
		terraform apply -auto-approve;)
	@echo "Finished Deploying app module"

destroy-app:
	@echo "Destroying app module"
	(cd iac/roots/app; \
		terraform init; \
		terraform destroy -auto-approve;)
	@echo "Finished Destroying app module"

test-mcp-client:
	@$(ENV_PATH)../test/fut/mcp-client-tests.sh

test-agent:
	@$(ENV_PATH)../test/fut/agent-tests.sh

prep-ui-env:
	$(ENV_PATH)../ui/prep-env.sh

run-ui:
	streamlit run $(ENV_PATH)../ui/app.py --server.port=8080 --server.address=localhost

# Deploy all targets in the correct order
deploy-all: deploy-app

# Destroy all targets in the correct order
destroy-all: destroy-app
