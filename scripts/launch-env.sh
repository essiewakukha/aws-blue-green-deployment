#!/usr/bin/env bash
# ============================================================
# scripts/launch-env.sh — Launch EC2 clusters and register to Target Groups
# Usage: ./launch-env.sh blue
#        ./launch-env.sh green
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./env.sh

ENV=${1:-""}

if [[ "$ENV" == "blue" ]]; then
    TARGET_TG_ARN="$TG_BLUE_ARN"
    USERDATA_FILE="../userdata/blue-v1.sh"
    VAR_NAME="BLUE_INSTANCE_IDS"
elif [[ "$ENV" == "green" ]]; then
    TARGET_TG_ARN="$TG_GREEN_ARN"
    USERDATA_FILE="../userdata/green-v2.sh"
    VAR_NAME="GREEN_INSTANCE_IDS"
else
    echo "Error: Please specify 'blue' or 'green' environment."
    exit 1
fi

# Convert comma-separated subnets into a bash array and select the first subnet
SUBNET_ARRAY=(${SUBNET_IDS//,/ })
LAUNCH_SUBNET="${SUBNET_ARRAY[0]}"

echo ">> Launching $INSTANCES_PER_ENV EC2 instances for [$ENV] environment..."
INSTANCE_IDS=$(aws ec2 run-instances --region "$AWS_REGION" \
  --image-id "$IMAGE_ID" \
  --instance-type "$INSTANCE_TYPE" \
  --subnet-id "$LAUNCH_SUBNET" \
  --security-group-ids "$APP_SG_ID" \
  --user-data "file://$USERDATA_FILE" \
  --count "$INSTANCES_PER_ENV" \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${PROJECT}-${ENV}},{Key=Environment,Value=${ENV}}]" \
  --query 'Instances[].InstanceId' --output text | tr '\t' ' ')

echo ">> Provisioned Instance IDs: $INSTANCE_IDS"

# Wait for instances to enter the running state
echo ">> Waiting for instances to stabilize..."
aws ec2 wait instance-running --region "$AWS_REGION" --instance-ids $INSTANCE_IDS

# Convert space separated list back to comma separated list for target group syntax
TARGET_ARG=""
for id in $INSTANCE_IDS; do
    TARGET_ARG+="Id=$id "
done

echo ">> Registering instances with Target Group..."
aws elbv2 register-targets --region "$AWS_REGION" \
  --target-group-arn "$TARGET_TG_ARN" \
  --targets $TARGET_ARG

# Persist instance IDs back to env.sh for smoke testing and teardown scripts
COMMA_IDS=$(echo "$INSTANCE_IDS" | tr ' ' ',')
sed -i "s|^export ${VAR_NAME}=.*|export ${VAR_NAME}=\"$COMMA_IDS\"|" env.sh

echo ">> Done! [$ENV] environment launched and attached to target group."

