<div align="center">

<img src="https://img.shields.io/badge/Lab-01-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/VPC-Networking-0A66C2?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/EC2-Ubuntu-E95420?style=for-the-badge&logo=ubuntu&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-Complete-28a745?style=for-the-badge"/>

# ☁️ Lab 01 — VPC, EC2 & Network ACLs

### Building AWS networking from scratch and breaking it on purpose to understand how it actually works.

[← Back to Lab Index](../README.md)

</div>

---

## 🎯 Objective

Deploy a custom VPC with a public subnet, launch an EC2 instance running a Python HTTP server, then deliberately trigger and resolve access failures using Security Groups and Network ACLs.

The goal wasn't just to get the server running — it was to **understand exactly what blocks traffic and why**, at each layer of the AWS network stack.

---

## 🏗️ Architecture

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
┌─────────────────────────────┐
│         project-vpc          │
│   CIDR: (your VPC CIDR)     │
│                              │
│  ┌───────────────────────┐  │
│  │    Public Subnet       │  │
│  │                        │  │
│  │  ┌─────────────────┐  │  │
│  │  │   EC2 Instance   │  │  │
│  │  │   Ubuntu Linux   │  │  │
│  │  │   Port: 8000     │  │  │
│  │  │   Python Server  │  │  │
│  │  └─────────────────┘  │  │
│  │                        │  │
│  │  Security Group ──────── Layer 1 (instance-level) │
│  │  Network ACL ─────────── Layer 2 (subnet-level)   │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

---

## ⚙️ Infrastructure

| Component | Configuration | Notes |
|-----------|-------------|-------|
| VPC | `project-vpc` | Custom, not default VPC |
| Subnet | Public | Auto-assign public IP enabled |
| EC2 AMI | Ubuntu Linux | t2.micro (Free Tier) |
| Web Server | Python HTTP Server | Built-in, no install needed |
| Port | `8000` | Custom TCP, not standard 80/443 |
| Internet Gateway | Attached | Route table configured |

---

## 🚀 Implementation

### Step 1 — Create the VPC

Created a custom VPC (`project-vpc`) instead of using the default — this forces you to configure every networking component manually, which is the point.

- Created VPC with a custom CIDR block
- Created a public subnet
- Created and attached an Internet Gateway
- Updated the route table: `0.0.0.0/0 → igw-xxxxxxxx`

📸 *Screenshot: VPC Creation*
<img src="./Screenshots/vpc.png" width="900">

---

### Step 2 — Launch EC2

Launched an Ubuntu EC2 instance inside the public subnet with a public IP assigned.

📸 *Screenshot: EC2 Launch*
<img src="./Screenshots/ec2.png" width="900">

---

### Step 3 — Prepare the Instance

SSH into the instance and set up the environment:

```bash
# Update package list
sudo apt update

# Configure Git identity (for any lab scripts pushed later)
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

---

### Step 4 — Start Python HTTP Server

```bash
python3 -m http.server 8000
```

Server started. Terminal showed incoming requests. Browser showed — nothing.

📸 *Screenshot: Python Server Running*
<img src="./Screenshots/python-server.png" width="900">

---

## 🔒 Troubleshooting — Security Group Block

### Problem

Python server was running and accepting connections locally. Browser at `http://<public-ip>:8000` timed out.

### Root Cause

The default Security Group had **no inbound rule for port 8000**. Security Groups are **deny-by-default** — if a port isn't explicitly allowed, all traffic to it is silently dropped.

### Fix

Added a custom inbound rule to the Security Group:

| Type | Protocol | Port | Source | Why |
|------|----------|------|--------|-----|
| Custom TCP | TCP | `8000` | `0.0.0.0/0` | Allow HTTP access from anywhere |

> **Note:** `0.0.0.0/0` is fine for a lab. In production, always scope source IPs to what actually needs access.

### Result

Browser now loads the Python server response.

📸 *Screenshot: Website Accessible*
<img src="./Screenshots/browser.png" width="900">

---

## 🔥 Network ACL Experiment — Subnet-Level Control

Once the Security Group was working, the next question: **what happens when the subnet itself blocks traffic?**

Network ACLs operate at the subnet boundary — they evaluate traffic before it even reaches the Security Group on the instance.

### The Key Rule: Lowest Number Wins

NACLs process rules **in ascending order by rule number**. The first matching rule is applied. Everything after it is ignored.

### Test 1 — Allow wins (rule 100 < 200)

| Rule # | Type | Port | Action | Result |
|--------|------|------|--------|--------|
| 100 | All Traffic | All | ✅ ALLOW | **Applied** |
| 200 | Custom TCP | 8000 | ❌ DENY | Ignored — rule 100 matched first |

→ **Server accessible** ✅

---

### Test 2 — Deny wins (rule 100 < 200)

| Rule # | Type | Port | Action | Result |
|--------|------|------|--------|--------|
| 100 | Custom TCP | 8000 | ❌ DENY | **Applied** |
| 200 | All Traffic | All | ✅ ALLOW | Ignored — rule 100 matched first |

→ **Server blocked** ❌

📸 *Screenshot: NACL Rules*
<img src="./Screenshots/nacl.png" width="900">

---

## 🔑 Security Groups vs Network ACLs

This lab makes the difference concrete:

| | Security Group | Network ACL |
|-|----------------|-------------|
| **Operates at** | Instance level | Subnet level |
| **Default behavior** | Deny all inbound | Allow all |
| **Rule evaluation** | All rules evaluated | Lowest number first |
| **Stateful?** | ✅ Yes — return traffic auto-allowed | ❌ No — must explicitly allow both directions |
| **When to use** | Fine-grained instance control | Broad subnet-level protection |

> **Real-world pattern:** Use Security Groups for primary access control. Use NACLs as a secondary defense — for example, blocking a malicious IP range at the subnet level without touching individual instances.

---

## 📚 Key Learnings

**Networking**
- VPCs don't route to the internet until you attach an Internet Gateway *and* update the route table — both steps are required
- Public subnets need auto-assign public IP enabled, or EC2 instances won't get a reachable address

**Security Groups**
- Default SGs block all inbound traffic — this is correct behavior, not a bug
- Opening port 8000 specifically (vs "All Traffic") is the right call even in a lab

**Network ACLs**
- NACLs are **stateless** — allowing inbound port 8000 doesn't automatically allow the response back out; you need an outbound rule too (or use the default allow-all outbound)
- Rule numbering is a real design decision — leave gaps (100, 200, 300) so you can insert rules later without renumbering

**Troubleshooting instinct**
- Server running locally ≠ server reachable externally. Always check: SG → NACL → Route Table → IGW, in that order

---

## ✅ Lab Complete

| Objective | Status |
|-----------|--------|
| Custom VPC created (not default) | ✅ |
| EC2 deployed in public subnet | ✅ |
| Internet Gateway + route table configured | ✅ |
| Python HTTP server running | ✅ |
| Security Group unblocked — port 8000 | ✅ |
| NACL rule priority behavior tested and confirmed | ✅ |

---

<div align="center">

[← Back to Lab Index](../README.md) | [Lab 02 — EC2 & Security Groups →](../02-EC2-SecurityGroups/)

*Every timeout is a lesson. Every blocked port is a teacher.*

</div>
