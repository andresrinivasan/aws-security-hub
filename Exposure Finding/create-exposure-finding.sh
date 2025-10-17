#!/bin/bash

## The following is sufficient for an exposure finding
##  - EC2.19
##  - Unpatched AMI
##
## Note having a public IP address is not necessary

# --- Configuration ---
. ./exposure-finding-config.sh

echo "--- Step 1: Creating a new EC2 Key Pair: $KEY_NAME ---"
aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text --region "$REGION" > "${KEY_NAME}.pem"
chmod 400 "${KEY_NAME}.pem"
echo "✅ Key Pair '${KEY_NAME}.pem' created and permissions set."
echo

echo "--- Step 2: Creating an Insecure Security Group: $SG_NAME ---"

# Create the security group
SG_ID=$(aws ec2 create-security-group --group-name "$SG_NAME" --description "Allow all RDP access for demo" --region "$REGION" --query 'GroupId' --output text)

# Add a rule to allow RDP from anywhere (0.0.0.0/0)
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 3389 --cidr 0.0.0.0/0 --region "$REGION"
echo "✅ Security Group '$SG_NAME' created with ID: $SG_ID. Port 3389 is open to the world."
echo

echo "--- Step 3: Creating the Administrative IAM Role and Instance Profile ---"
# Create a trust policy file for the EC2 service
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

# Create the IAM role
aws iam create-role --role-name "$ROLE_NAME" --assume-role-policy-document file://ec2-trust-policy.json --region "$REGION" > /dev/null
echo "IAM Role '$ROLE_NAME' created."

# Attach the AdministratorAccess policy to the role
aws iam attach-role-policy --role-name "$ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/AdministratorAccess --region "$REGION"
echo "Attached AdministratorAccess policy to '$ROLE_NAME'."

# Create the instance profile
aws iam create-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --region "$REGION" > /dev/null
echo "Instance Profile '$INSTANCE_PROFILE_NAME' created."

# Add the role to the instance profile
aws iam add-role-to-instance-profile --instance-profile-name "$INSTANCE_PROFILE_NAME" --role-name "$ROLE_NAME" --region "$REGION"
echo "✅ Added role to instance profile. Waiting for propagation..."
# Wait for 15 seconds to ensure the instance profile is available across AWS services
sleep 15
echo

echo "--- Step 4: Launching the Vulnerable EC2 Instance ---"
INSTANCE_ID=$(aws ec2 run-instances \
    --region "$REGION" \
    --image-id "$AMI_ID" \
    --instance-type t3.micro \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --iam-instance-profile Name="$INSTANCE_PROFILE_NAME" \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Demo-Vulnerable-Instance}]' \
    --query 'Instances[0].InstanceId' --output text)
    
echo "🚀 Instance launch initiated! Instance ID: $INSTANCE_ID"
echo "Waiting for the instance to enter the 'running' state..."
aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$REGION"
INSTANCE_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text --region "$REGION")

echo "✅ Instance is running with Public IP: $INSTANCE_PUBLIC_IP"
echo

echo "--- Setup Complete! ---"
echo "The instance is now running. It may take several hours for Amazon Inspector to scan the instance and for AWS Security Hub to correlate the findings into an exposure."

# Clean up the trust policy file
rm ec2-trust-policy.json