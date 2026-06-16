#!/bin/bash

# ==========================================

# AWS Lab 02 - ALB ASG Bastion

# ==========================================

# Connect to Bastion Host

ssh -i neww.pem ubuntu@<BASTION_PUBLIC_IP>

# Copy Key to Bastion

scp -i "neww.pem" neww.pem ubuntu@<BASTION_PUBLIC_IP>:/home/ubuntu/

# Update Permissions

chmod 400 neww.pem

# Connect to Private EC2 Instance

ssh -i neww.pem ubuntu@<PRIVATE_INSTANCE_IP>

# Update Packages

sudo apt update

# Clone Sample Application

git clone <REPOSITORY_URL>

cd <APP_DIRECTORY>

# Alternative Sample Application

mkdir app
cd app

# Copy the html file from the git 

# Start Python Server

python3 -m http.server 8000

# Verify Application

curl http://localhost:8000

# Auto Scaling Group

Desired Capacity : 2
Minimum Capacity : 2
Maximum Capacity : 4

# Application Load Balancer

Listener Port : 80

# Target Group

Protocol : HTTP
Target Port : 8000

# Security Group Rules

# ALB Security Group

HTTP 80 -> 0.0.0.0/0

# Application Server Security Group

TCP 8000 -> ALB Security Group

# Test Through ALB

curl http://aws-prod-1056527831.ap-south-1.elb.amazonaws.com

# Verify Targets

# AWS Console

# Target Groups -> Health Checks

# Verify Auto Scaling

# AWS Console

# Auto Scaling Groups -> Activity

