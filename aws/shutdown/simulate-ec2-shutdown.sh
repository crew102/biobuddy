#!/bin/bash

# Reminder that you have to update the rule in event bridge after each time
# you redeploy the stack if you want to run the custom.ec2.simulation job

INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].InstanceId" --output text)
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

aws events put-events --entries "[
  {
    \"Source\": \"custom.ec2.simulation\",
    \"DetailType\": \"EC2 Spot Instance Interruption Warning\",
    \"Detail\": \"{\\\"instance-id\\\":\\\"$INSTANCE_ID\\\",\\\"instance-action\\\":\\\"terminate\\\"}\",
    \"Resources\": [\"arn:aws:ec2:$REGION:$ACCOUNT_ID:instance/$INSTANCE_ID\"],
    \"EventBusName\": \"default\"
  }
]"
