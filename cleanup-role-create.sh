#!/bin/bash

# --- Configuration ---
ROLE_NAME="TestAdminRole"

echo "--- Starting Cleanup for IAM Role: $ROLE_NAME ---"
echo

echo "--- Step 1: Detaching AdministratorAccess Policy ---"
aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
echo "Policy detached."
echo

echo "--- Step 2: Deleting the IAM Role ---"
aws iam delete-role --role-name "$ROLE_NAME"
echo

echo "✅ Success! The IAM role '$ROLE_NAME' has been deleted from your account."