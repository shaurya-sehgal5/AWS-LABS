#!/bin/bash

# ==========================================

# AWS Lab 01 - VPC & NACL

# ==========================================

# Connect to EC2

ssh -i neww.pem ubuntu@<PUBLIC_IP>

# Update Packages

sudo apt update

# Configure Git

git config --global user.name "YOUR_NAME"
git config --global user.email "YOUR_EMAIL"

# Create Sample Application

mkdir app
cd app

echo "<h1>AWS VPC Lab</h1>" > index.html

# Start Python Web Server

python3 -m http.server 8000

# Access Application

http://<PUBLIC_IP>:8000

# Security Group Rule

Port: 8000
Protocol: TCP
Source: 0.0.0.0/0

# NACL Experiment

Rule 100 - Allow All Traffic
Rule 200 - Deny Port 8000

# NACL Experiment 2

Rule 100 - Deny Port 8000
Rule 200 - Allow All Traffic

# Verify Connectivity

curl http://localhost:8000

