include .envfile

## ----------------------------------------------------------------------
##  Makefile can be used to streamline the process and make it more efficient.
##  Using a Makefile to automate these tasks, developers can save time and reduce the
##  risk of errors when managing complex infrastructure with Terraform.
## ----------------------------------------------------------------------

# ----------------------------------------------------------------------------------------------------------------------
# ENVIRONMENT - SET ENVIRONMENT
# ----------------------------------------------------------------------------------------------------------------------
set_env:
	@echo "-------------------------\n    SET ENVIRONMENT\n-------------------------"
	@echo "AWS VAULT: $(vault_name)"
	@echo "REGION:    $(region)"
	@echo "----------------------------------------------------------------------\nENVIRONMENT: ALWAYS run 'unset AWS_VAULT' before run 'make set_env'\n----------------------------------------------------------------------"
	@echo "TERRAFORM:   Please run 'make plan' to see the changes"
	@echo "----------------------------------------------------------------------\nTERRAFORM: more info in documentation\n"

	@ rm -f .envfile && touch .envfile
	@echo VAULT_NAME=$(vault_name) >> .envfile
	@echo AWS_REGION=$(region) >> .envfile
	@aws-vault exec $(vault_name) --no-session --region=$(region)

# ----------------------------------------------------------------------------------------------------------------------
# TERRAFORM - PLAN COMMANDS
# ----------------------------------------------------------------------------------------------------------------------

plan: ##            PLAN ALL MODULES
	cd ${AWS_REGION} && terragrunt run-all plan
	terragrunt hclfmt --terragrunt-working-dir=${AWS_REGION}

plan_module: ##     PLAN ONE MODULE - module=iam
	terragrunt plan --terragrunt-working-dir=${AWS_REGION}/$(module)
	terragrunt hclfmt --terragrunt-working-dir=${AWS_REGION}/$(module)

planfile_json: ##   PLAN ALL MODULES AND GENERATE JSON FILE
	bash scripts/tfplanjson.sh ${AWS_REGION}

# --------------
# apply commands
# --------------
apply:
	cd $(STAGE) && terragrunt run-all apply

apply_module:
	terragrunt apply --terragrunt-working-dir=${AWS_REGION}/$(module)

# ----------------
# destroy commands
# ----------------
destroy:
	cd $(STAGE) && terragrunt run-all destroy
destroy_module:
	terragrunt destroy --terragrunt-working-dir=${AWS_REGION}/$(module)

# --------------
# state commands
# --------------
state_list:
	terragrunt state list --terragrunt-working-dir=${AWS_REGION}/$(module)

#############
# INFRACOST #
#############
infracostauth:
	infracost auth login
infracost:
	bash scripts/infracost.sh ${AWS_REGION}
# need authentication

help: ##            SHOW MAKEFILE OPTIONS.
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)
