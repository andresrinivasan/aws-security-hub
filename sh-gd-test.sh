#!/bin/bash

# Set variables
DETECTOR_ID="dcbf680878886043ce9ae007da8d7518"
BUCKET_NAME="andre-guardduty-malware-test-$(date +%Y%m%d-%H%M%S)"
REGION="eu-west-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ROLE="andre-aws-guardduty-malware-protection-service-role"

echo "=== GuardDuty Malware Protection Test ==="
echo "Bucket name: $BUCKET_NAME"
echo "Region: $REGION"
echo

# Step 1: Create bucket
echo "1. Creating S3 bucket..."
aws s3 mb s3://$BUCKET_NAME --region $REGION

# Step 2: Create malware protection plan (correct method for S3)
echo "2. Creating malware protection plan..."
aws guardduty create-malware-protection-plan \
    --role "arn:aws:iam::$ACCOUNT_ID:role/$ROLE"
    --protected-resource S3Bucket="{BucketName=$BUCKET_NAME}" \
    --detector-id $DETECTOR_ID \
    --region $REGION

# Step 3: Download EICAR file
echo "3. Downloading EICAR test file..."
curl -s https://secure.eicar.org/eicar.com.txt -o eicar.com.txt

# Step 4: Upload file
echo "4. Uploading malware test file..."
aws s3 cp eicar.com.txt s3://$BUCKET_NAME/ --region $REGION

echo "5. Malware protection is now active. Upload should trigger a scan."
echo "Check GuardDuty console for findings in 5-10 minutes."
