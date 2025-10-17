#!/bin/sh

aws ec2 create-security-group --group-name andre-test-sg --description "Security group for EC2.19 finding test"
aws ec2 authorize-security-group-ingress --group-name andre-test-sg --protocol tcp --port 3389 --cidr 0.0.0.0/0

