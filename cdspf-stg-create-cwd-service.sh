#!/usr/bin/env bash
set -Eeuo pipefail

# =========
# Settings
# =========
AWS_REGION="${AWS_REGION:-ap-northeast-1}"
AWS_PROFILE="${AWS_PROFILE:-}"          # 例: export AWS_PROFILE=cdspf-stg
STACK_PREFIX="${STACK_PREFIX:-cdspf-stg-ap-ne1-1}"

# 元スクリプトの stack 名に入っている識別子（例: 11-13-2025-12-03T10-57-17）
# 引数 or 環境変数で指定。未指定なら現在時刻で生成。
RUN_ID="${1:-${RUN_ID:-}}"
if [[ -z "${RUN_ID}" ]]; then
  RUN_ID="$(date -u +'%m-%d-%Y-%m-%dT%H-%M-%S')"
fi

export AWS_PAGER=""  # aws cli のページャを無効化

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
    log "Delete CloudFormation stack: ${stack}"
    aws_cli cloudformation delete-stack --stack-name "${stack}"
    log "Waiting for stack delete to complete: ${stack}"
    aws_cli cloudformation wait stack-delete-complete --stack-name "${stack}"
  else
    log "Stack not found (skip delete): ${stack}"
  fi
}

deploy_stack() {
  local stack="$1" template="$2"; shift 2
  local -a params=( "$@" )

  log "Deploy CloudFormation stack: ${stack} (template: ${template})"
  aws_cli cloudformation deploy \
    --template-file "${template}" \
    --stack-name "${stack}" \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides "${params[@]}"
}

# =========
# Finders (latest match)
# =========
latest_json_match() {
  # $1: aws cli json array (via stdin), $2: jq filter that returns a string or empty
  jq -r "$2"
}

find_latest_log_group() {
  local regex="$1"
  aws_cli logs describe-log-groups \
    --query 'logGroups[].logGroupName' \
    --output json \
  | latest_json_match /dev/stdin \
      "map(select(test(\"${regex}\"))) | sort | last // empty"
}

find_latest_alarm() {
  local regex="$1"
  aws_cli cloudwatch describe-alarms \
    --query 'MetricAlarms[].AlarmName' \
    --output json \
  | latest_json_match /dev/stdin \
      "map(select(test(\"${regex}\"))) | sort | last // empty"
}

require_value() {
  local label="$1" value="$2"
  [[ -n "${value}" ]] || die "No matching ${label} found."
}

# =========
# High-level helpers
# =========
deploy_with_log_group() {
  local stack="$1" template="$2" param_key="$3" regex="$4"

  local lg
  lg="$(find_latest_log_group "${regex}")"
  require_value "CloudWatch Log Group (${regex})" "${lg}"
  log "Found log group: ${lg}"

  delete_stack_if_exists "${stack}"
  deploy_stack "${stack}" "${template}" "${param_key}=${lg}"
}

deploy_with_alarms() {
  # Usage:
  # deploy_with_alarms <stack> <template> <paramKey1> <regex1> <paramKey2> <regex2> ...
  local stack="$1" template="$2"; shift 2
  local -a params=()

  while (( $# )); do
    local key="$1" regex="$2"; shift 2
    local alarm
    alarm="$(find_latest_alarm "${regex}")"
    require_value "CloudWatch Alarm (${regex})" "${alarm}"
    log "Found alarm for ${key}: ${alarm}"
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

  # 1) DB-Query-Analysis Dashboard
  deploy_with_log_group \
    "${STACK_PREFIX}-${RUN_ID}-DB-Query-Analysis-Dashboard-Stack" \
    "DB_Query_Analysis.yaml" \
    "LogGroupName" \
    "^cdspf/cdspf-stg-ap-ne1-1-\\d{2}-\\d{2}-\\d{14}$"

  # 2) Service-IWpro-Auto Dashboard
  deploy_with_alarms \
    "${STACK_PREFIX}-${RUN_ID}-Service-IWpro-Auto-Dashboard-Stack" \
    "Service_IWpro-Auto.yaml" \
    "DocumentsetPluginQueueDepthAlarm" "^cdspf-stg-ap-ne1-1-(.+)-DocumentsetPluginQueueStack-(.+)-PluginQueueDepthAlarm-(.+)$" \
    "DocumentsetPluginQueueTimeAlarm"  "^cdspf-stg-ap-ne1-1-(.+)-DocumentsetPluginQueueStack-(.+)-PluginQueueTimeAlarm-(.+)$" \
    "DxpfImageProcessingPluginQueueDepthAlarm" "^cdspf-stg-ap-ne1-1-(.+)-DxpfImageProcessingPluginQueueStack-(.+)-PluginQueueDepthAlarm-(.+)$" \
    "DxpfImageProcessingPluginQueueTimeAlarm"  "^cdspf-stg-ap-ne1-1-(.+)-DxpfImageProcessingPluginQueueStack-(.+)-PluginQueueTimeAlarm-(.+)$"

  # 3) Service-IWpro-DMS Dashboard
  deploy_with_alarms \
    "${STACK_PREFIX}-${RUN_ID}-Service-IWpro-DMS-Dashboard-Stack" \
    "Service_IWpro-DMS.yaml" \
    "DaitoRegistrationPluginQueueDepthAlarm" "^cdspf-stg-ap-ne1-1-(.+)-DaitoRegistrationPluginQueueStack-(.+)-PluginQueueDepthAlarm-(.+)$" \
    "DaitoRegistrationPluginQueueTimeAlarm"  "^cdspf-stg-ap-ne1-1-(.+)-DaitoRegistrationPluginQueueStack-(.+)-PluginQueueTimeAlarm-(.+)$"

  # 4) Service-NPS Dashboard
  # NOTE: ここは元スクリプトに合わせて parameter 名を維持（QueueDepthAlarm/QueueTimeAlarm）しています。:contentReference[oaicite:2]{index=2}
  deploy_with_alarms \
    "${STACK_PREFIX}-${RUN_ID}-Service-NPS-Dashboard-Stack" \
    "Service_NPS.yaml" \
    "MsofficeToPdfForNpsPluginLambdaQueueDepthAlarm" "^cdspf-stg-ap-ne1-1-(.+)-MsofficeToPdfForNpsPluginLambdaStack-(.+)-PluginQueueDepthAlarm-(.+)$" \
    "MsofficeToPdfForNpsPluginLambdaQueueTimeAlarm"  "^cdspf-stg-ap-ne1-1-(.+)-MsofficeToPdfForNpsPluginLambdaStack-(.+)-PluginQueueTimeAlarm-(.+)$"

  # 5) Service-attention Dashboard
  deploy_with_alarms \
    "${STACK_PREFIX}-${RUN_ID}-Service-attention-Dashboard-Stack" \
    "Service_attention.yaml" \
    "FormatConversionPluginQueueDepthAlarm" "^cdspf-stg-ap-ne1-1-(.+)-FormatConversionPluginQueueStack-(.+)-PluginQueueDepthAlarm-(.+)$" \
    "FormatConversionPluginQueueTimeAlarm"  "^cdspf-stg-ap-ne1-1-(.+)-FormatConversionPluginQueueStack-(.+)-PluginQueueTimeAlarm-(.+)$" \
    "ImageOperationPluginQueueDepthAlarm" "^cdspf-stg-ap-ne1-1-(.+)-ImageOperationPluginQueueStack-(.+)-PluginQueueDepthAlarm-(.+)$" \
    "ImageOperationPluginQueueTimeAlarm"  "^cdspf-stg-ap-ne1-1-(.+)-ImageOperationPluginQueueStack-(.+)-PluginQueueTimeAlarm-(.+)$"

  log "All done."
}

main "$@"
