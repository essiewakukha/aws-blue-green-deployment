#!/usr/bin/env bash
# ============================================================
# scripts/deploy-stack.sh — Deploy infrastructure with CloudFormation
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./env.sh
export AWS_DEFAULT_REGION="$AWS_REGION"

STACK_NAME="${PROJECT}-infra-stack"

echo ">> Fetching default network configuration..."
VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true --query 'Vpcs[0].VpcId' --output text)
SUBNET_IDS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" Name=default-for-az,Values=true --query 'Subnets[].SubnetId' --output text | tr '\t' ',')

echo ">> Deploying CloudFormation template (infra.yml)..."
aws cloudformation deploy \
  --template-file ../infra/infra.yml \
  --stack-name "$STACK_NAME" \
  --parameter-overrides ProjectName="$PROJECT" VpcId="$VPC_ID" Subnets="$SUBNET_IDS" \
  --capabilities CAPABILITY_NAMED_IAM \
  --no-fail-on-empty-changeset

echo ">> Extracting stack outputs..."
LISTENER_ARN=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='ListenerArn'].OutputValue" --output text)
TG_BLUE_ARN=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='TgBlueArn'].OutputValue" --output text)
TG_GREEN_ARN=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='TgGreenArn'].OutputValue" --output text)
APP_SG_ID=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='AppSecurityGroupId'].OutputValue" --output text)
ALB_DNS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query "Stacks[0].Outputs[?OutputKey=='AlbDns'].OutputValue" --output text)

# Sync dynamic configuration back to env.sh
sed -i "s|^export LISTENER_ARN=.*|export LISTENER_ARN=\"$LISTENER_ARN\"|" env.sh
sed -i "s|^export TG_BLUE_ARN=.*|export TG_BLUE_ARN=\"$TG_BLUE_ARN\"|" env.sh
sed -i "s|^export TG_GREEN_ARN=.*|export TG_GREEN_ARN=\"$TG_GREEN_ARN\"|" env.sh
sed -i "s|^export APP_SG_ID=.*|export APP_SG_ID=\"$APP_SG_ID\"|" env.sh
sed -i "s|^export SUBNET_IDS=.*|export SUBNET_IDS=\"$SUBNET_IDS\"|" env.sh
sed -i "s|^export ALB_DNS=.*|export ALB_DNS=\"$ALB_DNS\"|" env.sh

if grep -qE 'LISTENER_ARN=""|ALB_DNS=""' env.sh; then
  echo "!! env.sh sync failed - check that env.sh declares all variables"
  exit 1
fi

echo ">> Done. Application URL: http://$ALB_DNS"
