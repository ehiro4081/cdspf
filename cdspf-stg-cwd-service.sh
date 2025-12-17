# 既存のCloudFormationスタック削除：cdspf-stg-ap-ne1-1-11-13-2025-12-03T10-57-17-DB-Query-Analysis-Dashboard-Stack
STACK_NAME=cdspf-stg-ap-ne1-1-11-13-2025-12-03T10-57-17-DB-Query-Analysis-Dashboard-Stack
aws cloudformation delete-stack --stack-name "$STACK_NAME"
echo "Delete CloudFormation stack: $STACK_NAME"

# ロググループ名の取得：DB_Query_Analysys
LOG_GROUP_NAME=$(aws logs describe-log-groups --query 'logGroups[].logGroupName' --output json | \
jq -r '
  map(select(test("^cdspf/cdspf-stg-ap-ne1-1-\\d{2}-\\d{2}-\\d{14}$"))) |
  max
')
if [ -z "$LOG_GROUP_NAME" ]; then
  echo "No matching CloudWatch Log Group found."
  exit 1
fi
echo "Found alarm name: $LOG_GROUP_NAME"


# CloudFormationデプロイ。テンプレートファイルは DB_Query_Analysys.yaml
aws cloudformation deploy \
  --template-file DB_Query_Analysis.yaml \
  --stack-name "$STACK_NAME" \
  --parameter-overrides LogGroupName="$LOG_GROUP_NAME" \
  --capabilities CAPABILITY_NAMED_IAM

# 既存のCloudFormationスタック削除：cdspf-stg-ap-ne1-1-11-13-2025-12-03T10-57-17-Service-IWpro-Auto-Dashboard-Stack
STACK_NAME=cdspf-stg-ap-ne1-1-11-13-2025-12-03T10-57-17-Service-IWpro-Auto-Dashboard-Stack
aws cloudformation delete-stack --stack-name "$STACK_NAME"
echo "Delete CloudFormation stack: $STACK_NAME"

# アラーム名の取得：Service_IWpro-Auto
ALARM_NAME1=$(aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName' --output json | \
jq -r '
  map(
    select(test("^cdspf-stg-ap-ne1-1-(.+)-DocumentsetPluginQueueStack-(.+)-PluginQueueDepthAlarm-(.+)$"))
  ) | max
')
if [ -z "$ALARM_NAME1" ]; then
  echo "No matching CloudWatch alarm found."
  exit 1
fi
echo "Found alarm name: $ALARM_NAME1"

ALARM_NAME2=$(aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName' --output json | \
jq -r '
  map(
    select(test("^cdspf-stg-ap-ne1-1-(.+)-DocumentsetPluginQueueStack-(.+)-PluginQueueTimeAlarm-(.+)$"))
  ) | max
')
if [ -z "$ALARM_NAME2" ]; then
  echo "No matching CloudWatch alarm found."
  exit 1
fi
echo "Found alarm name: $ALARM_NAME2"

ALARM_NAME3=$(aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName' --output json | \
jq -r '
  map(
    select(test("^cdspf-stg-ap-ne1-1-(.+)-DxpfImageProcessingPluginQueueStack-(.+)-PluginQueueDepthAlarm-(.+)$"))
  ) | max
')
if [ -z "$ALARM_NAME3" ]; then
  echo "No matching CloudWatch alarm found."
  exit 1
fi
echo "Found alarm name: $ALARM_NAME3"

ALARM_NAME4=$(aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName' --output json | \
jq -r '
  map(
    select(test("^cdspf-stg-ap-ne1-1-(.+)-DxpfImageProcessingPluginQueueStack-(.+)-PluginQueueTimeAlarm-(.+)$"))
  ) | max
')
if [ -z "$ALARM_NAME4" ]; then
  echo "No matching CloudWatch alarm found."
  exit 1
fi
echo "Found alarm name: $ALARM_NAME4"

# CloudFormationデプロイ。テンプレートファイルは Service_IWpro-Auto.yaml
aws cloudformation deploy \
  --template-file Service_IWpro-Auto.yaml \
  --stack-name "$STACK_NAME" \
  --parameter-overrides DocumentsetPluginQueueDepthAlarm="$ALARM_NAME1" DocumentsetPluginQueueTimeAlarm="$ALARM_NAME2" DxpfImageProcessingPluginQueueDepthAlarm="$ALARM_NAME3" DxpfImageProcessingPluginQueueTimeAlarm="$ALARM_NAME4" \
  --capabilities CAPABILITY_NAMED_IAM


# 既存のCloudFormationスタック削除：cdspf-stg-ap-ne1-1-11-13-2025-12-03T10-57-17-Service-IWpro-DMS-Dashboard-Stack
STACK_NAME=cdspf-stg-ap-ne1-1-11-13-2025-12-03T10-57-17-Service-IWpro-DMS-Dashboard-Stack
aws cloudformation delete-stack --stack-name "$STACK_NAME"
echo "Delete CloudFormation stack: $STACK_NAME"

# アラーム名の取得：Service_IWpro-DMS
ALARM_NAME1=$(aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName' --output json | \
jq -r '
  map(
    select(test("^cdspf-stg-ap-ne1-1-(.+)-DaitoRegistrationPluginQueueStack-(.+)-PluginQueueDepthAlarm-(.+)$"))
  ) | max
')
if [ -z "$ALARM_NAME1" ]; then
  echo "No matching CloudWatch alarm found."
  exit 1
fi
echo "Found alarm name: $ALARM_NAME1"

ALARM_NAME2=$(aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName' --output json | \
jq -r '
  map(
    select(test("^cdspf-stg-ap-ne1-1-(.+)-DaitoRegistrationPluginQueueStack-(.+)-PluginQueueTimeAlarm-(.+)$"))
  ) | max
')
if [ -z "$ALARM_NAME2" ]; then
  echo "No matching CloudWatch alarm found."
  exit 1
fi
echo "Found alarm name: $ALARM_NAME2"

# CloudFormationデプロイ。テンプレートファイルは Service_IWpro-DMS.yaml
aws cloudformation deploy \
  --template-file Service_IWpro-DMS.yaml \
  --stack-name "$STACK_NAME" \
  --parameter-overrides DaitoRegistrationPluginQueueDepthAlarm="$ALARM_NAME1" DaitoRegistrationPluginQueueTimeAlarm="$ALARM_NAME2" \
  --capabilities CAPABILITY_NAMED_IAM

# 既存のCloudFormationスタック削除：cdspf-stg-ap-ne1-1-11-13-2025-12-03T10-57-17-Service-NPS-Dashboard-Stack
STACK_NAME=cdspf-stg-ap-ne1-1-11-13-2025-12-03T10-57-17-Service-NPS-Dashboard-Stack
aws cloudformation delete-stack --stack-name "$STACK_NAME"
echo "Delete CloudFormation stack: $STACK_NAME"

# アラーム名の取得：Service_NPS
ALARM_NAME1=$(aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName' --output json | \
jq -r '
  map(
    select(test("^cdspf-stg-ap-ne1-1-(.+)-MsofficeToPdfForNpsPluginLambdaStack-(.+)-PluginQueueDepthAlarm-(.+)$"))
  ) | max
')
if [ -z "$ALARM_NAME1" ]; then
  echo "No matching CloudWatch alarm found."
  exit 1
fi
echo "Found alarm name: $ALARM_NAME1"

ALARM_NAME2=$(aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName' --output json | \
jq -r '
  map(
    select(test("^cdspf-stg-ap-ne1-1-(.+)-MsofficeToPdfForNpsPluginLambdaStack-(.+)-PluginQueueTimeAlarm-(.+)$"))
  ) | max
')
if [ -z "$ALARM_NAME2" ]; then
  echo "No matching CloudWatch alarm found."
  exit 1
fi
echo "Found alarm name: $ALARM_NAME2"

# CloudFormationデプロイ。テンプレートファイルは Service_NPS.yaml
aws cloudformation deploy \
  --template-file Service_NPS.yaml \
  --stack-name "$STACK_NAME" \
  --parameter-overrides MsofficeToPdfForNpsPluginLambdaQueueDepthAlarm="$ALARM_NAME1" MsofficeToPdfForNpsPluginLambdaQueueTimeAlarm="$ALARM_NAME2" \
  --capabilities CAPABILITY_NAMED_IAM


# 既存のCloudFormationスタック削除：cdspf-stg-ap-ne1-1-11-13-2025-12-03T10-57-17-Service-attention-Dashboard-Stack
STACK_NAME=cdspf-stg-ap-ne1-1-11-13-2025-12-03T10-57-17-Service-attention-Dashboard-Stack
aws cloudformation delete-stack --stack-name "$STACK_NAME"
echo "Delete CloudFormation stack: $STACK_NAME"

# アラーム名の取得：Service_attention
ALARM_NAME1=$(aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName' --output json | \
jq -r '
  map(
    select(test("^cdspf-stg-ap-ne1-1-(.+)-FormatConversionPluginQueueStack-(.+)-PluginQueueDepthAlarm-(.+)$"))
  ) | max
')
if [ -z "$ALARM_NAME1" ]; then
  echo "No matching CloudWatch alarm found."
  exit 1
fi
echo "Found alarm name: $ALARM_NAME1"

ALARM_NAME2=$(aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName' --output json | \
jq -r '
  map(
    select(test("^cdspf-stg-ap-ne1-1-(.+)-FormatConversionPluginQueueStack-(.+)-PluginQueueTimeAlarm-(.+)$"))
  ) | max
')
if [ -z "$ALARM_NAME2" ]; then
  echo "No matching CloudWatch alarm found."
  exit 1
fi
echo "Found alarm name: $ALARM_NAME2"

ALARM_NAME3=$(aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName' --output json | \
jq -r '
  map(
    select(test("^cdspf-stg-ap-ne1-1-(.+)-ImageOperationPluginQueueStack-(.+)-PluginQueueDepthAlarm-(.+)$"))
  ) | max
')
if [ -z "$ALARM_NAME3" ]; then
  echo "No matching CloudWatch alarm found."
  exit 1
fi
echo "Found alarm name: $ALARM_NAME3"

ALARM_NAME4=$(aws cloudwatch describe-alarms --query 'MetricAlarms[].AlarmName' --output json | \
jq -r '
  map(
    select(test("^cdspf-stg-ap-ne1-1-(.+)-ImageOperationPluginQueueStack-(.+)-PluginQueueTimeAlarm-(.+)$"))
  ) | max
')
if [ -z "$ALARM_NAME4" ]; then
  echo "No matching CloudWatch alarm found."
  exit 1
fi
echo "Found alarm name: $ALARM_NAME4"

# CloudFormationデプロイ。テンプレートファイルは Service-attention.yaml
aws cloudformation deploy \
  --template-file Service_attention.yaml \
  --stack-name "$STACK_NAME" \
  --parameter-overrides FormatConversionPluginQueueDepthAlarm="$ALARM_NAME1" FormatConversionPluginQueueTimeAlarm="$ALARM_NAME2" ImageOperationPluginQueueDepthAlarm="$ALARM_NAME3" ImageOperationPluginQueueTimeAlarm="$ALARM_NAME4"\
  --capabilities CAPABILITY_NAMED_IAM

