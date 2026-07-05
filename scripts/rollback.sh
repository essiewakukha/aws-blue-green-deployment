#!/usr/bin/env bash
# ============================================================
# scripts/rollback.sh — Instant emergency rollback to Blue
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./env.sh

echo ">> EMERGENCY: Rolling traffic back to Blue environment..."
aws elbv2 modify-listener --region "$AWS_REGION" \
  --listener-arn "$LISTENER_ARN" \
  --default-actions Type=forward,TargetGroupArn="$TG_BLUE_ARN"

echo ">> ROLLBACK SUCCESSFUL: Live traffic returned safely to Blue V1."
echo ">> Live URL: http://$ALB_DNS"

