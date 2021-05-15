#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
readonly repo=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

readonly ORGANIZATION_AWS_PROFILE="rce-organization"
readonly AWSCLI_VERSION="2.2.5"


function main {
  local -r account_name="$1"

  export AWS_PROFILE="${ORGANIZATION_AWS_PROFILE}"
  check_aws_credentials

  # TODO Create new email address to Google Groups
  local -r account_email="${account_name}@rce.fi"

  local -r new_account_id="$( create_account "${account_name}" "${account_email}" )"

  # TODO Create group for account admins
  # TODO Create users and add to account admins group
  # TODO Add user to account admins group

  generate_and_test_aws_config "${account_name}" "${new_account_id}"

  info "Account created and tested successfully"
}

function generate_and_test_aws_config {
  local -r profile_name="$1"
  local -r account_id="$2"

  info "Generating aws_config in ${repo}/configs/${profile_name}"
  mkdir -p "${repo}/configs"
  generate_aws_config "${account_id}" "${profile_name}" > "${repo}/configs/${profile_name}"

  info "Testing generated aws configuration"
  pushd "${repo}/configs"
  AWS_CONFIG_FILE="./${profile_name}" \
  AWS_PROFILE="${profile_name}" \
  check_aws_credentials
  popd
}

function generate_aws_config {
  local -r account_id="$1"
  local -r profile_name="$2"
  echo "[profile ${profile_name}]"
  echo "source_profile = ${AWS_PROFILE}"
  echo "role_arn = arn:aws:iam::${account_id}:role/OrganizationAccountAccessRole"
}

function check_aws_credentials {
  aws sts get-caller-identity
}

function create_account {
  local -r account_name="$1"
  local -r account_email="$2"

  info "Creating account ${account_name}"
  local -r create_account_request_id="$( put_create_account_request "${account_name}" "${account_email}" )"

  info "Waiting for account to be created"
  while [ "$( get_account_creation_status "${create_account_request_id}" )" = "IN_PROGRESS" ]; do
    info "Still waiting for account to be created..."
    sleep 5
  done
  info "Account has been created"

  get_created_account_id "$create_account_request_id"
}

function put_create_account_request {
  local -r account_name="$1"
  local -r account_email="$2"

  aws organizations create-account \
    --email "${account_email}" \
    --account-name "${account_name}" \
    --iam-user-access-to-billing ALLOW \
    --output text --query "CreateAccountStatus.Id"
}

function get_account_creation_status {
  local -r create_account_request_id="$1"
  aws organizations describe-create-account-status \
    --create-account-request-id "${create_account_request_id}" \
    --output text --query "CreateAccountStatus.State"
}

function get_created_account_id {
  local -r create_account_request_id="$1"
  aws organizations describe-create-account-status \
    --create-account-request-id "${create_account_request_id}" \
    --output text --query "CreateAccountStatus.AccountId"
}

function aws {
  require_docker

  docker run \
    --env AWS_CONFIG_FILE \
    --env AWS_PROFILE \
    --env AWS_REGION \
    --env AWS_DEFAULT_REGION \
    --volume "${HOME}/.aws:/root/.aws" \
    --volume "$( pwd ):/aws" \
    --rm --interactive \
    amazon/aws-cli:${AWSCLI_VERSION} "$@"
}


function require_docker {
  require_command docker
  if ! docker ps > /dev/null; then
    fatal "Running 'docker ps' failed. Is docker daemon running?"
  fi
}

function require_command {
  local -r command="$1"
  if ! command -v "$command" > /dev/null; then
    fatal "Command '$command' is required"
  fi
}

function info {
  log "INFO" "$1"
}

function fatal {
  log "ERROR" "$1"
  exit 1
}

function log {
  local -r level="$1"
  local -r message="$2"
  local -r timestamp=$(date +"%Y-%m-%d %H:%M:%S")

  >&2 echo -e "${timestamp} ${level} ${message}"
}

main "$@"
