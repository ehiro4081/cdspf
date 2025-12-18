#!/usr/bin/env bash
set -Eeuo pipefail

# =========
# Arguments
# =========
RUN_ID="${1:-}"
SEARCH_PREFIX="${2:-}"

[[ -n "${RUN_ID}" ]] || {
  echo "ERROR: RUN_ID is required"
  echo "Example: cdspf-stg-ap-ne1-1-11-13-2025-12-03T10-57-17-"
  exit 1
}

[[ -n "${SEARCH_PREFIX}" ]] || {
  echo "ERROR: SEARCH_PREFIX is required"
  echo "Example: cdspf-stg-ap-ne1-1-"
  exit 1
}

# =========
# Settings
# =========
AWS_REGION="${AWS_REGION:-ap-northeast-1}"
AWS_PROFILE="${AWS_PROFILE:-}"
ALARM_PREFIX1="PluginQueueDepthAlarm"
ALARM_PREFIX2="PluginQueueTimeAlarm"

export AWS_PAGER=""

# =========
# Utilities
# =========
log() { printf '[%s] %s\n' "$(date -Is)" "$*"; }
die() { log "ERROR: $*"; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Command not found: $1"
}

aws_cli() {
  local args=()
  [[ -n "${AWS_PROFILE}" ]] && args+=(--profile "${AWS_PROFILE}")
  [[ -n "${AWS_REGION}"  ]] && args+=(--region "${AWS_REGION}")
  aws "${args[@]}" "$@"
}

stack_exists() {
  aws_cli cloudformation describe-stacks --stack-name "$1" >/dev/null 2>&1
}

delete_stack_if_exists() {
  local stack="$1"
  if stack_exists "${stack}"; then
    log "Delete stack: ${stack}"
    aws_cli cloudformation delete-stack --stack-name "${stack}"
    aws_cli cloudformation wait stack-delete-complete --stack-name "${stack}"
  else
    log "Stack not found (skip): ${stack}"
  fi
}

deploy_stack() {
  local stack="$1" template="$2"; shift 2
  aws_cli cloudformation deploy \
    --stack-name "${stack}" \
    --template-file "${template}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides "$@"
}

# =========
# Finders
# =========
find_latest_log_group() {
  local regex="$1"
  aws_cli logs describe-log-groups \
    --query 'logGroups[].logGroupName' \
    --output json |
  jq -r "map(select(test(\"${regex}\"))) | sort | last // empty"
}

find_latest_alarm() {
  local regex="$1"
  aws_cli cloudwatch describe-alarms \
    --query 'MetricAlarms[].AlarmName' \
    --output json |
  jq -r "map(select(test(\"${regex}\"))) | sort | last // empty"
}

require_value() {
  [[ -n "$2" ]] || die "No matching $1 found"
}

# =========
# High-level helpers
# =========
deploy_with_log_group() {
  local stack="$1" template="$2" param="$3" regex="$4"

  local lg
  lg="$(find_latest_log_group "${regex}")"
  require_value "LogGroup (${regex})" "${lg}"

  delete_stack_if_exists "${stack}"
  deploy_stack "${stack}" "${template}" "${param}=${lg}"
}

deploy_with_alarms() {
  local stack="$1" template="$2"; shift 2
  local params=()

  while (( $# )); do
    local key="$1" regex="$2"; shift 2
    local alarm
    alarm="$(find_latest_alarm "${regex}")"
    require_value "Alarm (${regex})" "${alarm}"
    params+=("${key}=${alarm}")
  done

  delete_stack_if_exists "${stack}"
  deploy_stack "${stack}" "${template}" "${params[@]}"
}

# =========
# Main
# =========
main() {
  need_cmd aws
  need_cmd jq

  deploy_with_log_group \
    "${RUN_ID}DB-Query-Analysis-Dashboard-Stack" \
    "DB_Query_Analysis.yaml" \
    "LogGroupName" "LogGroupName" \
    "^cdspf/${SEARCH_PREFIX}[0-9]{2}-[0-9]{2}-[0-9]{14}$"

  deploy_with_alarms \
    "${RUN_ID}Service-IWpro-Auto-Dashboard-Stack" \
    "Service_IWpro-Auto.yaml" \
    "DocumentsetPluginQueueDepthAlarm" "^${SEARCH_PREFIX}.*${ALARM_PREFIX1}.*$" \
    "DocumentsetPluginQueueTimeAlarm"  "^${SEARCH_PREFIX}.*${ALARM_PREFIX2}.*$" \
    "DxpfImageProcessingPluginQueueDepthAlarm" "^${SEARCH_PREFIX}.*${ALARM_PREFIX1}.*$" \
    "DxpfImageProcessingPluginQueueTimeAlarm"  "^${SEARCH_PREFIX}.*${ALARM_PREFIX2}.*$"

  deploy_with_alarms \
    "${RUN_ID}Service-IWpro-DMS-Dashboard-Stack" \
    "Service_IWpro-DMS.yaml" \
    "DaitoRegistrationPluginQueueDepthAlarm" "^${SEARCH_PREFIX}.*${ALARM_PREFIX1}.*$" \
    "DaitoRegistrationPluginQueueTimeAlarm"  "^${SEARCH_PREFIX}.*${ALARM_PREFIX2}.*$"

  deploy_with_alarms \
    "${RUN_ID}Service-NPS-Dashboard-Stack" \
    "Service_NPS.yaml" \
    "MsofficeToPdfForNpsPluginLambdaQueueDepthAlarm" "^${SEARCH_PREFIX}.*${ALARM_PREFIX1}.*$" \
    "MsofficeToPdfForNpsPluginLambdaQueueTimeAlarm"  "^${SEARCH_PREFIX}.*${ALARM_PREFIX2}.*$"

  deploy_with_alarms \
    "${RUN_ID}Service-attention-Dashboard-Stack" \
    "Service_attention.yaml" \
    "FormatConversionPluginQueueDepthAlarm" "^${SEARCH_PREFIX}.*${ALARM_PREFIX1}.*$" \
    "FormatConversionPluginQueueTimeAlarm"  "^${SEARCH_PREFIX}.*${ALARM_PREFIX2}.*$" \
    "ImageOperationPluginQueueDepthAlarm" "^${SEARCH_PREFIX}.*${ALARM_PREFIX1}.*$" \
    "ImageOperationPluginQueueTimeAlarm"  "^${SEARCH_PREFIX}.*${ALARM_PREFIX2}.*$"

  log "All dashboards deployed successfully"
}

main "$@"
