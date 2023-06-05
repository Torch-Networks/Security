locals {
  region = reverse(split("/", abspath(get_terragrunt_dir())))[0]
  gh_token = run_cmd("aws", "ssm", "get-parameter", "--name", "/GH_TOKEN", "--query", "Parameter.Value", "--output", "text")
  aws_account_id = get_aws_account_id()
}
