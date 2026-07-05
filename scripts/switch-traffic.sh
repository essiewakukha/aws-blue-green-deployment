#!/usr/bin/env bash
# ============================================================
# switch-traffic.sh — set ALB listener weights (Blue vs Green)
# Usage:  ./switch-traffic.sh <green_weight_percent>
#   ./switch-traffic.sh 10    -> Blue 90 / Green 10  (canary)
#   ./switch-traffic.sh 50    -> Blue 50 / Green 50
#   ./switch-traffic.sh 100   -> Blue 0  / Green 100 (cutover)
#   ./switch-traffic.sh 0     -> Blue 100 / Green 0  (revert)
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./env.sh
export AWS_DEFAULT_REGION="$AWS_REGION"

GREEN_W="${1:?Usage: $0 <green_weight_0_to_100>}"
[[ "$GREEN_W" =~ ^[0-9]+$ ]] && (( GREEN_W <= 100 )) || { echo "Weight must be 0-100"; exit 1; }
BLUE_W=$((100 - GREEN_W))

echo ">> Setting listener weights: Blue=$BLUE_W  Green=$GREEN_W ..."
START=$(date +%s%3N)
aws elbv2 modify-listener \
  --listener-arn "$LISTENER_ARN" \
  --default-actions '[{"Type":"forward","ForwardConfig":{"TargetGroups":[
    {"TargetGroupArn":"'"$TG_BLUE_ARN"'","Weight":'"$BLUE_W"'},
    {"TargetGroupArn":"'"$TG_GREEN_ARN"'","Weight":'"$GREEN_W"'}]}}]' \
  --query 'Listeners[0].ListenerArn' --output text > /dev/null
END=$(date +%s%3N)
echo ">> Weights applied in $((END - START)) ms."

echo ""
echo ">> Live listener config:"
aws elbv2 describe-listeners --listener-arns "$LISTENER_ARN" \
  --query 'Listeners[0].DefaultActions[0].ForwardConfig.TargetGroups[].[TargetGroupArn,Weight]' \
  --output table

echo ""
echo ">> Waiting 15s for listener propagation..."; sleep 15; echo ">> Sampling 20 requests through the ALB:"
BLUE_HITS=0; GREEN_HITS=0
for i in $(seq 1 20); do
  R=$(curl -s --max-time 5 "http://$ALB_DNS/" || true)
  if echo "$R" | grep -q "GREEN"; then GREEN_HITS=$((GREEN_HITS+1)); else BLUE_HITS=$((BLUE_HITS+1)); fi
done
echo ">> Observed: BLUE=$BLUE_HITS/20  GREEN=$GREEN_HITS/20  (expected ~$BLUE_W%/$GREEN_W%)"
