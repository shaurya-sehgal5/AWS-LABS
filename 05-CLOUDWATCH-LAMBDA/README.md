<div align="center">

<img src="https://img.shields.io/badge/Lab-05-FF9900?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/CloudWatch-Monitoring-FF4F8B?style=for-the-badge&logo=amazonaws&logoColor=white"/>
<img src="https://img.shields.io/badge/Lambda-Automation-FF9900?style=for-the-badge&logo=awslambda&logoColor=white"/>
<img src="https://img.shields.io/badge/Status-Complete-28a745?style=for-the-badge"/>

# ☁️ Lab 05 — CloudWatch Monitoring & Lambda Automation

### Monitor infra like a pro. Kill orphaned resources automatically. Two core DevOps responsibilities — one lab.

[← Lab 04: CI/CD Pipeline](../04-CICD-Pipeline/) | [Back to Lab Index](../README.md)

</div>

---

## 🎯 Objective

Two real DevOps responsibilities tackled in one lab:

| Part | Problem | Solution |
|------|---------|----------|
| **01** | EC2 CPU spikes go unnoticed → incidents happen | CloudWatch Alarm → SNS email alert |
| **02** | Orphaned EBS snapshots accumulate → AWS bill grows | Lambda function auto-deletes unused snapshots |

> **The DevOps mindset this lab trains:** Don't watch dashboards manually. Don't clean up resources manually. Write the automation once and let it run forever.

---

## 🧰 AWS Services Used

| Service | Role |
|---------|------|
| Amazon CloudWatch | Metrics collection, alarm evaluation, scheduling |
| Amazon SNS | Email alert delivery when alarm triggers |
| Amazon EC2 | Monitored resource + load test target |
| AWS Lambda | Serverless automation function |
| Amazon EBS | Snapshot source for cleanup job |
| IAM | Execution roles and permission policies |

---

# 📊 Part 01 — CloudWatch Monitoring & Alerts

## Architecture

```
EC2 Instance (CPU load generated)
        │
        │ publishes metric every 60s
        ▼
Amazon CloudWatch
        │
        │ threshold breached → state: ALARM
        ▼
Amazon SNS Topic
        │
        │ publishes to subscriber
        ▼
📧 Email Alert → Admin inbox
```

---

## Step 1 — Create the CloudWatch Alarm

Configured a CloudWatch Alarm against the EC2 CPU Utilization metric:

| Setting | Value | Why |
|---------|-------|-----|
| Metric | `CPUUtilization` | Standard EC2 metric, no agent needed |
| Resource | EC2 Instance ID | Scoped to one instance |
| Statistic | Average | Smooths out momentary spikes |
| Period | 60 seconds | Evaluation window |
| Threshold | `> 50%` | Trigger point |
| Alarm Action | SNS Topic → Email | Notify admin on breach |

> **Why 50%?** In production you'd tune this per workload. 50% is a conservative early warning — gives time to investigate before the instance is actually saturated.

---

## Step 2 — Generate CPU Load

To test the alarm without waiting for real traffic, a Python script was run directly on the EC2 instance to spike CPU artificially:

```python
# cpu_stress.py — artificially saturates CPU for alarm testing
import multiprocessing
import time

def burn_cpu():
    while True:
        pass  # tight loop — pegs the core at 100%

if __name__ == "__main__":
    # spawn one process per CPU core
    procs = [multiprocessing.Process(target=burn_cpu)
             for _ in range(multiprocessing.cpu_count())]
    for p in procs:
        p.start()

    time.sleep(120)  # run for 2 minutes — enough for CloudWatch to detect

    for p in procs:
        p.terminate()
```

```bash
python3 cpu_stress.py
```

> **Add Screenshot:** CloudWatch Alarm Configuration

---

## Step 3 — Alarm Triggered

After the CPU breach was sustained past the evaluation period:

```
State change:  OK → ALARM
Alarm action:  SNS notification published
Email:         alert received in admin inbox ✅
```

> **Add Screenshot:** CloudWatch Alarm in ALARM state

---

## CloudWatch Alarm State Machine

Understanding the three states is important for production alerting:

```
         CPU < 50%           CPU > 50%
OK ─────────────────────► ALARM
 ▲                            │
 │      CPU < 50%             │
 └────────────────────────────┘

INSUFFICIENT_DATA ──► OK or ALARM
(initial state / no data / agent stopped)
```

> **Production note:** `INSUFFICIENT_DATA` is also an alarm state. In real environments, configure actions on `INSUFFICIENT_DATA` too — a stopped metrics agent often means a dead instance, which is itself an incident.

---

## Real-World CloudWatch Use Cases

```
CPUUtilization     > 80%   → scale out trigger / page on-call
MemoryUtilization  > 90%   → memory leak investigation
DiskReadOps        > X     → I/O bottleneck alert
NetworkIn          anomaly → DDoS / traffic spike detection
StatusCheckFailed  = 1     → instance health alert
ALB 5xx errors     > 1%    → application failure alert
```

---

# ⚙️ Part 02 — Lambda-Based EBS Snapshot Cleanup

## The Problem

```bash
# What happens over time in most AWS accounts:
$ aws ec2 describe-snapshots --owner-ids self | jq '.Snapshots | length'
247   # snapshots created for backups

$ aws ec2 describe-instances | jq '[.Reservations[].Instances[]] | length'
12    # only 12 instances still running

# The gap = orphaned snapshots = money burning every month
```

EC2 instances get terminated. Their EBS volumes get deleted. Their snapshots **stay** — and keep billing you until someone manually deletes them. In large orgs this becomes thousands of dollars in wasted storage.

---

## Solution Architecture

```
CloudWatch Events (cron schedule)
           │
           │  triggers on schedule
           ▼
    ┌─────────────────────────────────┐
    │        AWS Lambda               │
    │        (Python runtime)         │
    │                                 │
    │  1. ec2.describe_snapshots()    │
    │     → get all owned snapshots   │
    │                                 │
    │  2. for each snapshot:          │
    │     → get volume_id             │
    │     → ec2.describe_volumes()    │
    │     → check if volume exists    │
    │     → check if attached to      │
    │       running instance          │
    │                                 │
    │  3. if orphaned:                │
    │     → ec2.delete_snapshot()     │
    └─────────────────────────────────┘
           │
           ▼
    Orphaned snapshots deleted ✅
    Active snapshots untouched ✅
```

---

## Lambda Function — Snapshot Cleanup

```python
import boto3

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')

    # get all snapshots owned by this account
    snapshots = ec2.describe_snapshots(OwnerIds=['self'])['Snapshots']

    # get all running instance IDs
    instances = ec2.describe_instances(
        Filters=[{'Name': 'instance-state-name', 'Values': ['running']}]
    )
    running_instance_ids = {
        i['InstanceId']
        for r in instances['Reservations']
        for i in r['Instances']
    }

    deleted = []

    for snap in snapshots:
        snapshot_id = snap['SnapshotId']
        volume_id   = snap.get('VolumeId')

        if not volume_id:
            # snapshot has no associated volume → orphaned
            ec2.delete_snapshot(SnapshotId=snapshot_id)
            deleted.append(snapshot_id)
            continue

        try:
            vols = ec2.describe_volumes(VolumeIds=[volume_id])['Volumes']
            if not vols:
                # volume no longer exists
                ec2.delete_snapshot(SnapshotId=snapshot_id)
                deleted.append(snapshot_id)
                continue

            vol = vols[0]
            attachments = vol.get('Attachments', [])

            if not attachments:
                # volume exists but is detached — no running instance needs this
                ec2.delete_snapshot(SnapshotId=snapshot_id)
                deleted.append(snapshot_id)

            else:
                attached_instance = attachments[0].get('InstanceId')
                if attached_instance not in running_instance_ids:
                    # volume attached to a stopped/terminated instance
                    ec2.delete_snapshot(SnapshotId=snapshot_id)
                    deleted.append(snapshot_id)

        except ec2.exceptions.ClientError:
            # volume ID exists in snapshot but volume is gone
            ec2.delete_snapshot(SnapshotId=snapshot_id)
            deleted.append(snapshot_id)

    print(f"Deleted {len(deleted)} orphaned snapshots: {deleted}")
    return {'deleted_count': len(deleted), 'snapshot_ids': deleted}
```

---

## 🔥 Troubleshooting — Lambda Failures

### Issue 1 — Function Timed Out Before Completing

**Symptom:** Lambda execution stopped mid-run. No snapshots processed.

**Root Cause:** Default Lambda timeout is **3 seconds**. With even a handful of snapshots and API calls per snapshot, this is nowhere near enough.

**Fix:**

```
Lambda → Configuration → General Configuration → Timeout
Default : 3 seconds
Updated : 10 seconds   (dev/test)
Production recommendation : 60–300 seconds depending on snapshot count
```

> **Rule of thumb:** Each `describe_volumes` API call adds ~100–300ms. With 100 snapshots that's 10–30 seconds minimum. Size your timeout to `(snapshot_count × avg_api_latency) + buffer`.

---

### Issue 2 — AccessDenied on `DescribeInstances`

**Symptom:** Function ran but crashed with:

```
botocore.exceptions.ClientError:
An error occurred (UnauthorizedOperation) when calling
the DescribeInstances operation: You are not authorized
to perform this operation.
```

**Root Cause:** The Lambda execution role had `ec2:DescribeSnapshots` but not `ec2:DescribeInstances` or `ec2:DescribeVolumes`. Lambda needs all three to execute the full cleanup logic.

**Fix:** Attached a scoped IAM policy to the Lambda execution role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "SnapshotCleanupPermissions",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeSnapshots",
        "ec2:DescribeVolumes",
        "ec2:DescribeInstances",
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*"
    }
  ]
}
```

> **Note:** `AmazonEC2FullAccess` was used during testing for speed. In production, always scope to the exact actions needed — granting `ec2:*` to a deletion function is a serious blast radius risk.

> **Add Screenshot:** IAM Permission Error → Resolution

---

### Issue 3 — Running Lambda First Time with No Orphans

**Symptom:** Function ran successfully but `deleted_count: 0`. Looked like it wasn't working.

**Root Cause:** There were no orphaned snapshots yet — all snapshots had live associated volumes. This was actually correct behavior.

**Fix:** Created a test snapshot, then terminated the EC2 instance + deleted the volume. Re-ran Lambda — snapshot deleted correctly.

> **Lesson:** Always create a controlled test case. `0 deleted` can mean "working correctly" or "broken silently" — you need to know which.

> **Add Screenshot:** Successful Lambda Execution

---

## ⏱️ Automating with CloudWatch Schedule

Configured a CloudWatch Events rule to trigger the Lambda automatically:

```
CloudWatch Events → Rules → Create Rule
Event Source : Schedule
              cron(0 2 * * ? *)   ← runs daily at 2:00 AM UTC
Target       : Lambda function → snapshot-cleanup
```

| Schedule | Cron | Use Case |
|----------|------|----------|
| Daily | `cron(0 2 * * ? *)` | Active accounts with frequent snapshot churn |
| Weekly | `cron(0 2 ? * MON *)` | Moderate usage — cost review cadence |
| Monthly | `cron(0 2 1 * ? *)` | Compliance and audit runs |

> **Add Screenshot:** CloudWatch Scheduled Event

---

## 🏭 Production Hardening — What to Add Before Going Live

The lab version deletes immediately. In production, add guardrails:

```python
# Option 1 — age-based filter (only delete snapshots older than 30 days)
from datetime import datetime, timezone, timedelta

cutoff = datetime.now(timezone.utc) - timedelta(days=30)
if snap['StartTime'] < cutoff:
    ec2.delete_snapshot(SnapshotId=snapshot_id)

# Option 2 — dry run mode (log what would be deleted, don't actually delete)
DRY_RUN = os.environ.get('DRY_RUN', 'true') == 'true'
if not DRY_RUN:
    ec2.delete_snapshot(SnapshotId=snapshot_id)
else:
    print(f"[DRY RUN] Would delete: {snapshot_id}")

# Option 3 — SNS notification instead of direct delete (human approval flow)
sns.publish(
    TopicArn=os.environ['APPROVAL_TOPIC'],
    Message=f"Orphaned snapshots found: {deleted}. Approve deletion?"
)
```

---

## 📚 Key Learnings

**CloudWatch:**
- Alarms have three states: `OK`, `ALARM`, `INSUFFICIENT_DATA` — all three matter in production
- The evaluation period matters: a 60-second period means CloudWatch waits for one full minute of data before changing state
- SNS + CloudWatch is the standard AWS alerting pattern — Lambda can also be an alarm action for auto-remediation

**Lambda:**
- Default 3-second timeout is designed for simple functions — anything hitting multiple AWS APIs needs more
- Lambda execution roles follow least-privilege — the function can only do what the role explicitly allows
- Always test with a controlled scenario: create the condition, run the function, verify the outcome

**IAM pattern for Lambda:**
- Identify every AWS API call the function makes → those are the exact permissions needed
- Never attach `FullAccess` policies to production Lambda functions
- Use environment variables for config (dry run flag, SNS topic ARN, age threshold) — not hardcoded values

**Cost optimization mindset:**
- Orphaned snapshots are a classic AWS cost leak — real orgs pay thousands/month for snapshots no one needs
- Lambda + CloudWatch schedule is the standard pattern for automated cost governance
- The same pattern applies to: unused EIPs, unattached EBS volumes, idle NAT Gateways

---

## ✅ Lab Completion Checklist

| Objective | Status |
|-----------|--------|
| CloudWatch alarm created on EC2 CPU metric | ✅ |
| SNS topic configured with email subscription | ✅ |
| CPU stress test generated to trigger alarm | ✅ |
| Alarm state changed to ALARM and email received | ✅ |
| Lambda function written for snapshot cleanup | ✅ |
| Lambda timeout increased from 3s → 10s | ✅ |
| IAM execution role updated with required EC2 permissions | ✅ |
| Orphaned snapshot identified and deleted by Lambda | ✅ |
| CloudWatch schedule configured for automated runs | ✅ |
| Production hardening patterns documented | ✅ |

---

<div align="center">

[← Lab 04: CI/CD Pipeline](../04-CICD-Pipeline/) | [Back to Lab Index](../README.md)

*Good DevOps engineers monitor everything. Great ones automate the response.*

</div>
