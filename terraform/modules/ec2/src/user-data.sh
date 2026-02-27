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

