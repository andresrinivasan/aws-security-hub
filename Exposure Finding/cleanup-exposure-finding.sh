#!/bin/bash

# --- Configuration ---
# Use the same names as the creation script.
. ./exposure-finding-config.sh

echo "--- Starting Cleanup ---"

echo "Finding instance ID..."
INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=Demo-Vulnerable-Instance" "Name=instance-state-name,Values=running,pending" --query 'Reservations[*].Instances[*].InstanceId' --output text --region "$REGION")

if [ -z "$INSTANCE_ID" ]; then
    echo "No running instance found with tag ${INSTANCE_TAG_KEY}=${INSTANCE_TAG_VALUE}. Exiting."
else
    echo "Terminating EC2 Instance: $INSTANCE_ID..."
    aws ec2 terminate-instances --instance-ids "$INSTANCE_ID" --region "$REGION"
    echo "Waiting for instance to terminate..."
    aws ec2 wait instance-terminated --instance-ids "$INSTANCE_ID" --region "$REGION"
    echo "✅ Instance terminated."
fi

echo "Removing IAM Role from Instance Profile..."
aws iam remove-role-from-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --role-name "$ROLE_NAME" --region "$REGION"

echo "Deleting Instance Profile: $INSTANCE_PROFILE_NAME..."
aws iam delete-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --region "$REGION"

echo "Detaching policy from IAM Role..."
aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --region "$REGION"

echo "Deleting IAM Role: $ROLE_NAME..."
aws iam delete-role --role-name "$ROLE_NAME" --region "$REGION"
echo "✅ IAM resources deleted."

echo "Finding Security Group ID for $SG_NAME..."
SG_ID=$(aws ec2 describe-security-groups --filters Name=group-name,Values="$SG_NAME" --query 'SecurityGroups[0].GroupId' --output text --region "$REGION")

if [ "$SG_ID" != "None" ]; then
    echo "Deleting Security Group: $SG_ID..."
    aws ec2 delete-security-group --group-id "$SG_ID" --region "$REGION"
    echo "✅ Security Group deleted."
else
    echo "Security Group $SG_NAME not found."
fi

echo "Deleting Key Pair: $KEY_NAME..."
aws ec2 delete-key-pair --key-name "$KEY_NAME" --region "$REGION"
rm -f "${KEY_NAME}.pem"
echo "✅ Key Pair deleted locally and from AWS."

echo "--- Cleanup Complete ---"