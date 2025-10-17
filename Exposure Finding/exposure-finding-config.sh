#!/bin/sh

# shellcheck disable=SC2034
REGION="eu-west-1"
KEY_NAME="andre-DemoVulnerableKeyPair"
SG_NAME="andre-DemoInsecureSG"
ROLE_NAME="andre-DemoAdminRole"
INSTANCE_PROFILE_NAME="andre-DemoAdminInstanceProfile"
AMI_ID="ami-02109e2e0c6000b41" # Older Amazon Linux 2 AMI in eu-west-1