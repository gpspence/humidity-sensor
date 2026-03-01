#!/bin/bash
# Script Name   : user-data.sh
# Description   : EC2 initialisation script
# Creation Date : 2026-02-27
# Version       : 1.0

# --- Install Docker ---
sudo yum update -y
sudo yum install docker -y
sudo service docker start
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# --- Setup CloudWatch Logs Agent ---
sudo yum install amazon-cloudwatch-agent -y
aws s3 cp s3://${S3_CONFIG_BUCKET_NAME}/cloudwatch-agent-config.json \
  /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  --region ${REGION}
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -s