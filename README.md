<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=FF9900&height=120&section=header&text=AWS-LABS&fontSize=42&fontColor=ffffff&fontAlignY=38&desc=Production-Style%20Cloud%20Infrastructure%20Labs&descAlignY=60&descSize=16" width="100%"/>



<img src="https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white"/>
<img src="https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white"/>
<img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white"/>
<img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black"/>

<br/><br/>

<img src="https://img.shields.io/badge/Labs%20Completed-7-brightgreen?style=flat-square"/>
<img src="https://img.shields.io/badge/Services%20Covered-20%2B-blue?style=flat-square"/>
<img src="https://img.shields.io/badge/Status-Actively%20Building-FF9900?style=flat-square"/>
<img src="https://img.shields.io/badge/Focus-DevOps%20%7C%20SRE%20%7C%20Cloud-blueviolet?style=flat-square"/>

<br/><br/>

> **Real infrastructure. Real problems. Real fixes. Documented like a production engineer.**

</div>

---

## 🔍 What This Repository Is

This isn't a certification prep repo. Every lab here simulates how cloud infrastructure is actually built and maintained inside engineering teams.

Each lab goes through the full lifecycle — **design → provision → break → debug → fix → document** — because that's what cloud engineering actually looks like on the job.

The documentation standard mirrors how production changes are tracked: architecture diagrams, commands with context, real errors encountered, and how they were resolved. Not just "it worked."

---

## ⚡ Lab Index

| # | Lab | Core Services | Difficulty | Status |
|---|-----|--------------|------------|--------|
| [01](./01-VPC-NACL/) | **VPC & Network ACL** | VPC · Public Subnet · EC2 · Security Groups · NACL | 🟡 Intermediate | ✅ Done |
| [02](./02-ALB-ASG-BASTION/) | **ALB + Auto Scaling + Bastion** | ALB · ASG · Launch Template · NAT Gateway · Bastion | 🟡 Intermediate | ✅ Done |
| [03](./03-S3-IAM-HOSTING/) | **S3, IAM & Static Hosting** | S3 · IAM · Bucket Policies · Static Website Hosting | 🟢 Foundational | ✅ Done |
| [04](./04-CODEPIPELINE-CODEDEPLOY/) | **CI/CD Pipeline** | CodePipeline · CodeBuild · CodeDeploy · Docker · SSM | 🔴 Advanced | ✅ Done |
| [05](./05-CLOUDWATCH-LAMBDA/) | **CloudWatch & Lambda Automation** | CloudWatch · SNS · Lambda · IAM · Cost Optimization | 🟡 Intermediate | ✅ Done |
| [06](./06-EKS-ALB-INGRESS/) | **Amazon EKS + ALB Ingress** | EKS · IAM OIDC · Helm · AWS Load Balancer Controller | 🔴 Advanced | ✅ Done |
| [07](./07-TERRAFORM-ALB/) | **Terraform Infrastructure** | Terraform · VPC · EC2 · ALB · Security Groups · S3 | 🔴 Advanced | ✅ Done |
| [08](./08-PRODUCTION-EKS/) | **Production Three-Tier EKS** | Full Stack Deployment on Amazon EKS | 🔴 Advanced | 🚧 In Progress |

---

## 🧠 What Each Lab Actually Covers

Every lab follows the same engineering-grade documentation structure:

```
📁 lab-name/
├── README.md          ← Full implementation breakdown
├── commands.sh        ← Every command used, with comments
├── screenshots/       ← Visual proof of working infrastructure
├── architecture/      ← Diagrams (draw.io / excalidraw)
└── extras/            ← Terraform files, K8s YAMLs, scripts (where applicable)
```

**Documentation per lab includes:**
- Architecture overview with component interaction
- Step-by-step implementation with reasoning (not just commands)
- Real errors hit during the lab and exact fix applied
- Cost considerations and cleanup steps
- Key learnings and what I'd do differently in production

---

## 🏗 Infrastructure Deep Dives

<details>
<summary><b>🌐 Lab 01 — VPC & Network ACL</b></summary>

Built a production-style VPC from scratch with:
- Custom CIDR block, public subnet, internet gateway, and route tables
- EC2 instance deployed inside the subnet with security group rules
- Network ACL configured at subnet level for stateless traffic control
- Tested allow/deny rules and compared behavior with Security Groups (stateful vs stateless)

**Real issue hit:** NACL rule ordering causing SSH block even with correct SG — resolved by understanding that NACLs evaluate rules by number, lowest first.

</details>

<details>
<summary><b>⚖️ Lab 02 — ALB + Auto Scaling Group + Bastion Host</b></summary>

Multi-tier architecture with:
- Application Load Balancer distributing traffic across AZs
- Auto Scaling Group with Launch Template and scaling policies
- NAT Gateway allowing private EC2 instances to reach the internet
- Bastion Host in public subnet for secure SSH access to private instances

**Real issue hit:** ASG instances not registering as healthy in ALB target group — root cause was health check path mismatch. Fixed by aligning ALB health check endpoint with app response.

</details>

<details>
<summary><b>🗂 Lab 03 — S3, IAM & Static Website Hosting</b></summary>

Covered IAM from first principles and S3 as both storage and a hosting layer:
- IAM user creation, policy attachment, least-privilege principle applied
- S3 bucket configured for public static website hosting
- Bucket policy vs ACL behavior — tested both, documented differences
- Explored how CloudFront would sit in front for production use

</details>

<details>
<summary><b>🚀 Lab 04 — Full CI/CD Pipeline (CodePipeline + Docker)</b></summary>

End-to-end automated deployment pipeline:
- CodePipeline triggered on GitHub push
- CodeBuild compiling and building Docker image, pushing to ECR
- CodeDeploy deploying to EC2 with blue/green deployment config
- Secrets managed via AWS Parameter Store (not hardcoded anywhere)

**Real issue hit:** CodeBuild failing due to missing IAM permissions for ECR push — traced via CloudWatch Logs, fixed with precise policy addition.

</details>

<details>
<summary><b>📊 Lab 05 — CloudWatch Monitoring & Lambda Automation</b></summary>

Infrastructure observability and automated cost response:
- CloudWatch alarms on CPU, memory, and billing thresholds
- SNS topic for alert routing to email
- Lambda function triggered by CloudWatch Events to stop idle EC2 instances
- IAM execution role scoped to minimum required permissions

</details>

<details>
<summary><b>☸️ Lab 06 — Amazon EKS + ALB Ingress Controller</b></summary>

Production Kubernetes cluster setup on AWS:
- EKS cluster provisioned with managed node groups
- IAM OIDC provider configured for service account-level AWS permissions
- AWS Load Balancer Controller installed via Helm
- Ingress resource routing HTTP traffic to backend services inside cluster

**Real issue hit:** ALB controller pods in CrashLoopBackOff — cause was incorrect OIDC trust policy. Fixed by regenerating the service account annotation with the correct cluster OIDC URL.

</details>

<details>
<summary><b>🏗 Lab 07 — Terraform Infrastructure as Code</b></summary>

Entire AWS infrastructure defined as code using Terraform:
- VPC, subnets, internet gateway, route tables — all as `.tf` resources
- EC2 instances with security groups
- ALB with target group and listener rules
- Remote state stored in S3 with DynamoDB locking
- Modular structure — reusable across environments

**Real issue hit:** State file lock not released after failed apply — resolved with `terraform force-unlock` and understanding why locking exists.

</details>

---

## 🛠 Tech Stack

```yaml
Cloud Provider:     AWS (primary)
OS / Shell:         Ubuntu Linux · Bash
IaC:                Terraform
Containers:         Docker · Amazon ECR
Orchestration:      Kubernetes · Amazon EKS · Helm
CI/CD:              AWS CodePipeline · CodeBuild · CodeDeploy
Monitoring:         Amazon CloudWatch · SNS · Lambda
Security:           IAM · Security Groups · NACL · Parameter Store
Version Control:    Git · GitHub
Scripting:          Bash · Python
```

---

## 📊 AWS Services Coverage Map

```
NETWORKING          COMPUTE             STORAGE             SECURITY
───────────         ───────────         ───────────         ───────────
✅ VPC              ✅ EC2              ✅ S3               ✅ IAM
✅ Subnets          ✅ Auto Scaling     ✅ ECR              ✅ IAM Roles
✅ Internet GW      ✅ Launch Templates ✅ EBS              ✅ Security Groups
✅ Route Tables     ✅ Bastion Host                         ✅ NACL
✅ NAT Gateway      ✅ Lambda                               ✅ Parameter Store
✅ ALB              ✅ EKS

DEVOPS              MONITORING          CONTAINERS
───────────         ───────────         ───────────
✅ CodePipeline     ✅ CloudWatch        ✅ Docker
✅ CodeBuild        ✅ CloudWatch Alarms ✅ Amazon EKS
✅ CodeDeploy       ✅ SNS               ✅ Helm
✅ Terraform        ✅ EventBridge       ✅ ALB Controller
```

---

## 💡 Why This Repo Exists

Most AWS learning online is theory-heavy — watch a video, click through the console, done. That doesn't translate to being useful on day one at a job.

This repo was built with a different goal: **learn by deploying, breaking, and fixing real infrastructure**, and document everything the way a junior cloud engineer would in a real team.

The objective isn't to have 7 green checkmarks. It's to understand *why* a NAT Gateway sits where it does, *why* CodeBuild needs that IAM permission, and *why* that OIDC trust policy broke the entire Kubernetes controller.

That's the difference between someone who passed a cert and someone who can actually be useful on an SRE team.

---

## 🧭 Learning Path Followed

```
AWS Fundamentals → Networking (VPC) → Compute (EC2 + ASG) → Storage (S3)
      ↓
CI/CD (CodePipeline + Docker) → Monitoring (CloudWatch + Lambda)
      ↓
Containers (EKS + Helm + Ingress) → IaC (Terraform)
      ↓
Production Project (Three-Tier EKS) → [In Progress]
```

Course reference: [DevOps Zero to Hero — Abhishek Veeramalla](https://github.com/iam-veeramalla)

---

<div align="center">

---

**Built by [Shaurya Sehgal](https://github.com/shaurya-sehgal5)**
BCA · UPES Dehradun · 

*Targeting DevOps / SRE / Cloud Engineer roles*

---

`Learn` → `Build` → `Break` → `Fix` → `Document` → `Repeat`

<img src="https://capsule-render.vercel.app/api?type=waving&color=FF9900&height=80&section=footer" width="100%"/>

</div>
