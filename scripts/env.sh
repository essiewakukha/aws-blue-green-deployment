#!/usr/bin/env bash
# ============================================================
# env.sh - shared configuration for the blue-green capstone
# Source this at the top of every script:  source ./env.sh
# Scripts append created resource IDs/ARNs below as they run.
# ============================================================

export AWS_REGION="us-east-1"          
export PROJECT="bluegreen-capstone"
export KEY_NAME=""                      your EC2 key pair name for SSH
export INSTANCE_TYPE="t3.micro"
export INSTANCES_PER_ENV=2
export IMAGE_ID="ami-06067086cf86c58e6" 

# Resolved automatically by deploy-stack.sh (CloudFormation wrapper)
export VPC_ID=""
export SUBNET_IDS="subnet-03a7e15b260c4e5ba,subnet-05a9f3e0cd1af9591,subnet-02860e9db32e8a554,subnet-07fafc03a6d0339f0,subnet-00bd89cd83def91ad,subnet-044e259324c679e25"
export ALB_SG_ID=""
export APP_SG_ID="sg-0ed5e12ea08c70e93"

# Populated by deploy-stack.sh
export TG_BLUE_ARN="arn:aws:elasticloadbalancing:us-east-1:207567786898:targetgroup/bluegreen-capstone-tg-blue/5abc556e2ef9ae27"
export TG_GREEN_ARN="arn:aws:elasticloadbalancing:us-east-1:207567786898:targetgroup/bluegreen-capstone-tg-green/fde24a909ee4cff3"
export ALB_ARN=""
export ALB_DNS="bluegreen-capstone-alb-1694547311.us-east-1.elb.amazonaws.com"
export LISTENER_ARN="arn:aws:elasticloadbalancing:us-east-1:207567786898:listener/app/bluegreen-capstone-alb/543129a34a89a0a6/0a8822f7e24109c4"

# Populated by launch-env.sh (comma-separated instance IDs)
export BLUE_INSTANCE_IDS="i-0a31987686421ae61,i-0fdd6b7681eef1386"
export GREEN_INSTANCE_IDS="i-0f2fff4f2cc98c323,i-0350da29954d07c06"

# Populated by auto-rollback.sh
export ROLLBACK_LAMBDA_ARN=""
