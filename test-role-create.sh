#!/bin/bash

# --- Configuration ---
ROLE_NAME="andre-TestAdminRole"

echo "--- Step 1: Defining the Trust Policy ---"
# This policy allows the AWS EC2 service to assume this role.
cat > ec2-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ec2.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
echo "Trust policy file 'ec2-trust-policy.json' created."
echo

echo "--- Step 2: Creating the IAM Role ---"
aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://ec2-trust-policy.json
echo

echo "--- Step 3: Attaching the AdministratorAccess Policy ---"
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
echo

# Clean up the temporary policy file
rm ec2-trust-policy.json

echo "✅ Success! The IAM role '$ROLE_NAME' has been created with AdministratorAccess."
echo "This role is now available in your AWS account but is not yet attached to any resource."