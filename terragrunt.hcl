# ---------------------------------------------------------------------------------------------------------------------
# TERRAGRUNT CONFIGURATION
# Terragrunt is a thin wrapper for Terraform that provides extra tools for working with multiple Terraform modules,
# remote state, and locking: https://github.com/gruntwork-io/terragrunt
# ---------------------------------------------------------------------------------------------------------------------
terraform {
  extra_arguments "retry_lock" {
    commands = get_terraform_commands_that_need_locking()
    arguments = [
      "-lock-timeout=20m"
    ]
  }

  before_hook "cleaner" {
    commands = [
      "init",
    ]
    execute = ["rm", "-rf", ".terraform"]
  }
}

locals {
  region_vars    = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  gh_token       = local.region_vars.locals.gh_token
  region         = local.region_vars.locals.region
  aws_account_id = local.region_vars.locals.aws_account_id

}

inputs = merge(
  local.region_vars.locals
)

retryable_errors = [
  "(?s).*Error installing provider.*tcp.*connection reset by peer.*",
  "(?s).*ssh_exchange_identification.*Connection closed by remote host.*"
]

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"
  allowed_account_ids = ["${local.aws_account_id}"]
}
EOF
}

remote_state {
  backend = "s3"

  config = {
    bucket         = join("-", [get_env("BUCKET", "tf-bucket"), "audit", local.aws_account_id, local.region])
    dynamodb_table = join("-", [get_env("DYNAMODB_TABLE", "terraform-locks"), local.aws_account_id])
    encrypt        = true
    region         = local.region
    key            = "${path_relative_to_include()}/terraform.tfstate"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}
