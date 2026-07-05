#!/usr/bin/env bash
# ============================================================
# scripts/smoke-test.sh — Verify target group instance health
# Usage: ./smoke-test.sh blue
#        ./smoke-test.sh green
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"
source ./env.sh

ENV=${1:-"blue"}

if [[ "$ENV" == "blue" ]]; then
    TARGET_TG_ARN="$TG_BLUE_ARN"
elif [[ "$ENV" == "green" ]]; then
    TARGET_TG_ARN="$TG_GREEN_ARN"
else
    echo "Error: Please specify 'blue' or 'green' environment to test."
    exit 1
fi

echo ">> Checking health status for [$ENV] target group..."
echo ">> Target Group ARN: $TARGET_TG_ARN"

# Loop and wait for targets to pass health checks (up to 3 minutes)
MAX_ATTEMPTS=18
ATTEMPT=1
HEALTHY=false

while [ $ATTEMPT -le $MAX_ATTEMPTS ]; do
    # Query health descriptions from AWS
    HEALTH_STATES=$(aws elbv2 describe-target-health \
      --region "$AWS_REGION" \
      --target-group-arn "$TARGET_TG_ARN" \
      --query 'TargetHealthDescriptions[].TargetHealth.State' --output text)

    echo ">> Attempt $ATTEMPT/$MAX_ATTEMPTS - Current states: [ $HEALTH_STATES ]"

    # If there are no targets registered yet
    if [ -z "$HEALTH_STATES" ]; then
        echo "Warning: No targets found in this group yet."
    # If all targets return 'healthy'
    elif [[ ! "$HEALTH_STATES" =~ "unhealthy" ]] && [[ ! "$HEALTH_STATES" =~ "initial" ]] && [[ ! "$HEALTH_STATES" =~ "draining" ]]; then
        echo ">> Success! All instances in [$ENV] are healthy."
        HEALTHY=true
        break
    fi

    # Wait 10 seconds before polling AWS again
    sleep 10
    ATTEMPT=$((ATTEMPT + 1))
done

if [ "$HEALTHY" = false ]; then
    echo ">> ERROR: [$ENV] environment failed smoke tests. Some instances are unhealthy."
    exit 1
fi

