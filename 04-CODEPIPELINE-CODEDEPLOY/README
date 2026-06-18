<div align="center">

<img src="https://img.shields.io/badge/Lab-04-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/CI%2FCD-CodePipeline-0A66C2?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/Docker-Container%20Deploy-2496ED?style=for-the-badge&logo=docker&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-Complete-28a745?style=for-the-badge"/>

# ☁️ Lab 04 — CI/CD Pipeline with CodePipeline & CodeDeploy

### Full automated pipeline: GitHub push → CodeBuild → Docker Hub → CodeDeploy → EC2. With every real failure documented.

[← Lab 03: S3 & IAM](../03-IAM/) | [Back to Lab Index](../README.md)

</div>

---

## 🎯 Objective

Build a complete CI/CD pipeline using AWS-native DevOps services that:

- Automatically triggers on every GitHub push
- Builds and pushes a Docker image to Docker Hub
- Deploys the updated container to an EC2 instance
- Handles secrets securely — no credentials in code

This lab is less about the happy path and more about the **real failures** that happen when you wire together IAM roles, CodeBuild, CodeDeploy, Docker, and EC2 for the first time.

---

## 🏗️ Architecture

```
Developer pushes code
        │
        ▼
┌───────────────┐
│    GitHub     │  ← Source of truth
└───────┬───────┘
        │  webhook trigger
        ▼
┌───────────────┐
│ CodePipeline  │  ← Orchestrates the entire flow
└───────┬───────┘
        │
        ▼
┌───────────────────────────────────┐
│           CodeBuild               │
│                                   │
│  1. Pull source from GitHub       │
│  2. Fetch Docker creds from SSM   │
│  3. docker build                  │
│  4. docker login (Docker Hub)     │
│  5. docker push                   │
└───────┬───────────────────────────┘
        │  image pushed to Docker Hub
        ▼
┌───────────────┐
│  Docker Hub   │  ← Image registry
└───────┬───────┘
        │
        ▼
┌───────────────────────────────────┐
│           CodeDeploy              │
│                                   │
│  1. Pull deployment scripts       │
│  2. Stop existing container       │
│  3. Remove old container          │
│  4. docker pull (latest image)    │
│  5. docker run                    │
└───────┬───────────────────────────┘
        │
        ▼
┌───────────────┐
│  EC2 Instance │  ← Deployment target
│  (Ubuntu)     │
│  CodeDeploy   │
│  Agent running│
└───────────────┘
```

---

## 🧰 AWS Services Used

| Service | Role in Pipeline |
|---------|----------------|
| AWS CodePipeline | Orchestrates all stages end-to-end |
| AWS CodeBuild | Builds Docker image, pushes to Docker Hub |
| AWS CodeDeploy | Deploys container to EC2 |
| SSM Parameter Store | Stores Docker Hub credentials securely |
| IAM | Service roles for CodeBuild and EC2 |
| Amazon EC2 | Deployment target server |
| GitHub | Source code repository |
| Docker Hub | Container image registry |

---

# 🔁 Phase 1 — Continuous Integration (CI)

## Step 1 — Source Integration

Connected GitHub repository to CodePipeline. Every push to the configured branch automatically triggers the pipeline — no manual intervention required.

---

## Step 2 — Storing Secrets Securely (SSM Parameter Store)

Docker Hub credentials were stored in AWS Systems Manager Parameter Store — **never hardcoded in buildspec.yml**.

```
/myapp/docker-credentials/username   → Docker Hub username
/myapp/docker-credentials/password   → Docker Hub password
/myapp/docker-registry/url           → registry URL
```

> **Why SSM over environment variables?** Environment variables in CodeBuild are visible in build logs. SSM Parameter Store values are fetched at runtime, never printed, and can be encrypted with KMS. This is the correct production pattern.

---

## Step 3 — CodeBuild Configuration

Created a CodeBuild project with a `buildspec.yml` defining the build steps.

---

## 🔥 Troubleshooting — Phase 1

### Issue 1 — CodeBuild Couldn't Read SSM Parameters

**Error:** `AccessDeniedException` when CodeBuild tried to fetch Docker credentials from Parameter Store.

**Root Cause:** The CodeBuild service role had no permission to read SSM parameters. AWS services don't inherit permissions — every role must explicitly declare what it can access.

**Fix — Added this policy to the CodeBuild IAM role:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SSMParameterAccess",
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": [
        "arn:aws:ssm:ap-south-1:114403655679:parameter/myapp/*"
      ]
    },
    {
      "Sid": "KMSDecryptAccess",
      "Effect": "Allow",
      "Action": ["kms:Decrypt"],
      "Resource": "*"
    }
  ]
}
```

> **Note the resource scope:** `parameter/myapp/*` — only the parameters this app needs, not all SSM parameters in the account. Least privilege at the resource level.

> **Add Screenshot:** IAM Permission Error & Resolution

---

### Issue 2 — Docker Push Failed (Missing Login Step)

**Symptom:** `docker build` succeeded. `docker push` failed with authentication error.

**Root Cause:** The `buildspec.yml` was missing the `docker login` step. The image was built locally inside CodeBuild but Docker Hub rejected the push because the session wasn't authenticated.

**Fix:** Added `docker login` using the SSM-fetched credentials before the push command. Build completed successfully after.

**Lesson:** Build success ≠ push success. They are separate operations with separate auth requirements.

---

### Issue 3 — CodeBuild and CodePipeline Running Different Scripts

**Symptom:** Local buildspec tests passed. Pipeline runs failed with different errors.

**Root Cause:** CodeBuild was picking up a different `buildspec.yml` path than what CodePipeline was configured to use. They were executing different build logic.

Additionally, deployment artifacts were configured in the build stage even though they weren't needed there — causing pipeline stage mismatches.

**Fix:** Aligned both services to the same buildspec path, removed unnecessary artifact configuration from the build stage.

**Lesson:** Always verify which buildspec file the pipeline is actually executing — not just which one you think it is.

> **Add Screenshot:** CodeBuild Failure Logs

---

# 🚀 Phase 2 — Continuous Deployment (CD)

## Step 1 — EC2 Setup & CodeDeploy Agent

Launched an Ubuntu EC2 instance as the deployment target and installed the CodeDeploy agent.

---

## 🔥 Troubleshooting — Phase 2

### Issue 4 — CodeDeploy Agent Installation Failed

**Symptom:** Standard CodeDeploy agent install commands returned errors.

**Root Cause:** The commands were written for Amazon Linux. The EC2 instance was running Ubuntu — different package manager, different install method.

**Fix:** Used the Ubuntu-compatible installation method. Added ~10 minutes of troubleshooting.

**Lesson:** AWS documentation often defaults to Amazon Linux examples. Always verify the Ubuntu/Debian equivalent before running install commands.

After successful installation, verified with:

```bash
sudo service codedeploy-agent status
```

> **Add Screenshot:** CodeDeploy Agent Running

---

## Step 2 — EC2 IAM Role

Attached an IAM role to the EC2 instance granting access to:
- CodeDeploy (receive deployment instructions)
- S3 (fetch deployment artifacts)

Without this role, the CodeDeploy agent on the instance has no AWS credentials to pull deployment packages.

---

## Step 3 — Deployment Group & AppSpec

Created a Deployment Group linking the EC2 instance to the CodeDeploy application.

CodeDeploy uses `appspec.yml` to know which scripts to run at each deployment lifecycle hook:

```
BeforeInstall  → stop old container, remove it
AfterInstall   → pull new Docker image
ApplicationStart → docker run new container
ValidateService → health check
```

---

## Step 4 — Docker Deployment Scripts

Scripts executed by CodeDeploy on the EC2 instance:

```bash
# Stop and remove any existing container (prevents port conflicts)
docker ps -q | xargs --no-run-if-empty docker stop
docker ps -aq | xargs --no-run-if-empty docker rm

# Pull the latest image from Docker Hub
docker pull <dockerhub-username>/<image-name>:latest

# Start the new container
docker run -d -p 8000:8000 <dockerhub-username>/<image-name>:latest
```

---

## 🔥 Troubleshooting — Phase 2 (continued)

### Issue 5 — Second Deployment Failed (Port Already in Use)

**Symptom:** First deployment succeeded. Second deployment (triggered by a new push) failed.

**Root Cause:** The first deployment's container was still running and holding port 8000. The new container tried to bind the same port and failed.

**Fix:** Added container cleanup to the `BeforeInstall` hook — stop all running containers and remove them before starting the new deployment.

```bash
docker ps -q | xargs --no-run-if-empty docker stop
docker ps -aq | xargs --no-run-if-empty docker rm
```

> `--no-run-if-empty` prevents the command from failing when no containers exist (e.g., first deployment).

**Lesson:** Deployment scripts must handle both first-run and re-run scenarios. Always clean up state before deploying new state.

> **Add Screenshot:** Port Conflict Failure & Fix

---

# ✅ Final Pipeline — Working State

```
Developer pushes to GitHub
         │
         ▼
   CodePipeline triggered
         │
    ┌────┴────┐
    │  Stage 1 │  Source   → GitHub checkout
    └────┬────┘
    ┌────┴────┐
    │  Stage 2 │  Build    → CodeBuild → Docker build + push to Docker Hub
    └────┬────┘
    ┌────┴────┐
    │  Stage 3 │  Deploy   → CodeDeploy → EC2 container swap
    └────┬────┘
         │
         ▼
  Application running on EC2
  Updated on every push — zero manual steps
```

> **Add Screenshot:** Successful Pipeline Execution

---

## 📚 Key Learnings

**IAM & Secrets:**
- Every AWS service role must explicitly declare its permissions — no implicit inheritance
- SSM Parameter Store is the correct way to handle secrets in CodeBuild — not env vars, not hardcoded values
- Scope resource ARNs tightly: `parameter/myapp/*` not `parameter/*`

**CI/CD Architecture:**
- CodePipeline is the orchestrator — it doesn't build or deploy itself, it coordinates CodeBuild and CodeDeploy
- `buildspec.yml` path must match between CodeBuild project config and CodePipeline stage config
- Artifact configuration must match what each stage actually produces and consumes

**Docker in CI/CD:**
- `docker build` and `docker push` are separate operations with separate auth
- Always run `docker login` before `docker push` in automated pipelines
- Container cleanup before deployment prevents port conflict failures on re-deployments

**CodeDeploy:**
- Agent must be running on EC2 *before* the first deployment — CodeDeploy has no way to install it remotely
- EC2 must have an IAM role — the agent needs AWS credentials to receive deployment instructions
- Installation commands differ by OS — Amazon Linux ≠ Ubuntu

---

## ✅ Lab Completion Checklist

| Objective | Status |
|-----------|--------|
| GitHub connected to CodePipeline | ✅ |
| Docker Hub credentials stored in SSM Parameter Store | ✅ |
| CodeBuild IAM role updated with SSM + KMS permissions | ✅ |
| Docker build + push working in CodeBuild | ✅ |
| CodeDeploy agent installed and running on EC2 | ✅ |
| EC2 IAM role configured for CodeDeploy + S3 | ✅ |
| Deployment group created and linked to EC2 | ✅ |
| Docker container cleanup scripts configured | ✅ |
| Port conflict on re-deployment resolved | ✅ |
| Full pipeline trigger-to-deploy working end-to-end | ✅ |

---

<div align="center">

[← Lab 03: S3 & IAM](../03-IAM/) | [Back to Lab Index](../README.md)

*Automation isn't magic. It's just every manual step written down and executed reliably.*

</div>
