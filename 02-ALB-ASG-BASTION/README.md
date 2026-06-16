# ☁️ AWS Lab 02 - Production-Style Application Deployment on AWS

## Overview

This lab demonstrates how to deploy a highly available and secure web application on AWS using industry-standard cloud architecture.

The deployment leverages multiple AWS services including VPC, Private Subnets, NAT Gateways, Bastion Hosts, Auto Scaling Groups, Launch Templates, Security Groups, Target Groups, and an Application Load Balancer.

The objective was to design an environment where application servers remain private and secure while still being accessible to users through a public Load Balancer.

---

## Architecture

```text
Internet
    │
    ▼
Application Load Balancer
    │
    ▼
Auto Scaling Group
 ┌─────────────┐
 │ EC2 Instance│
 └─────────────┘
 ┌─────────────┐
 │ EC2 Instance│
 └─────────────┘
    │
    ▼
Private Subnets
    │
    ▼
NAT Gateway
    │
    ▼
Internet Gateway

Management Access
       │
       ▼
  Bastion Host
       │
       ▼
 Private EC2 Instances
```

<img src="./screenshots/vpc-architecture.png" width="900">

---

## VPC Setup

A custom VPC was created with:

* Public Subnets
* Private Subnets
* Internet Gateway
* NAT Gateway (One per Availability Zone)

The NAT Gateways allow instances in private subnets to access the internet for package updates and downloads without exposing them to inbound public traffic.

This setup follows common production networking practices.

---

## Launch Template & Auto Scaling

A Launch Template was created containing:

* Ubuntu AMI
* Instance Type
* Security Group Configuration
* Network Settings

The template was then attached to an Auto Scaling Group.

### Auto Scaling Configuration

| Setting          | Value |
| ---------------- | ----- |
| Minimum Capacity | 2     |
| Desired Capacity | 2     |
| Maximum Capacity | 4     |

This ensures high availability and automatic scaling based on workload requirements.

<img src="./screenshots/autoscaling-group.png" width="900">

---

## Private Application Servers

The EC2 instances created by the Auto Scaling Group were launched inside private subnets.

These instances were intentionally configured without public IP addresses to reduce the attack surface and improve security.

As a result, they could not be accessed directly from the internet.

---

## Bastion Host Implementation

To securely manage the private instances, a Bastion Host was deployed inside a public subnet.

The Bastion Host acts as a jump server that provides controlled administrative access to the private EC2 instances.

### Transfer Key to Bastion Host

```bash
scp -i "C:\Users\shaur\Downloads\neww.pem" "C:\Users\shaur\Downloads\neww.pem" ubuntu@<BASTION_PUBLIC_IP>:/home/ubuntu/
```

### Connect to Private Instance

```bash
chmod 400 neww.pem
```

```bash
ssh -i neww.pem ubuntu@<PRIVATE_INSTANCE_IP>
```

Using this approach, administrative access was achieved without exposing the application servers to the internet.

<img src="./screenshots/bastion-access.png" width="900">

---

## Application Deployment

After connecting to the private EC2 instances, a sample HTML application was deployed.

A lightweight Python web server was used to host the application.

```bash
python3 -m http.server 8000
```

The application was deployed on all backend instances managed by the Auto Scaling Group.

---

## Application Load Balancer

An Application Load Balancer (ALB) was created to distribute incoming traffic across multiple EC2 instances.

Benefits of using an ALB include:

* High Availability
* Load Distribution
* Fault Tolerance
* Improved User Experience

A Target Group was configured and the Auto Scaling instances were registered as backend targets.

Health checks were enabled to ensure traffic is routed only to healthy instances.

<img src="./screenshots/load-balancer-target-group.png" width="900">

---

## Security Group Configuration

### Load Balancer Security Group

| Type | Port | Source    |
| ---- | ---- | --------- |
| HTTP | 80   | 0.0.0.0/0 |

### Application Server Security Group

| Type | Port | Source                       |
| ---- | ---- | ---------------------------- |
| TCP  | 8000 | Load Balancer Security Group |

This configuration ensures that backend instances only accept traffic originating from the Load Balancer.

---

## Application Testing

After configuring the Load Balancer and Security Groups, the application became accessible through the ALB DNS endpoint.

```text
http://aws-prod-1056527831.ap-south-1.elb.amazonaws.com/
```

The Load Balancer successfully distributed requests to the backend EC2 instances running in private subnets.

<img src="./screenshots/final-application.png" width="900">

---

## AWS Services Used

* Amazon VPC
* Public Subnets
* Private Subnets
* Internet Gateway
* NAT Gateway
* EC2
* Launch Templates
* Auto Scaling Groups
* Bastion Host
* Application Load Balancer
* Target Groups
* Security Groups

---

## Key Learnings

* Designing secure AWS network architectures
* Deploying EC2 instances inside private subnets
* Using NAT Gateways for outbound internet access
* Accessing private servers through a Bastion Host
* Creating Launch Templates
* Configuring Auto Scaling Groups
* Implementing Load Balancers and Target Groups
* Applying Security Group best practices
* Building highly available AWS infrastructure

---

## Conclusion

This lab demonstrates a production-style AWS deployment architecture where application servers remain private and secure while still serving traffic through an Application Load Balancer. The implementation combines networking, security, scalability, and high availability concepts that are commonly used in real-world cloud environments.

