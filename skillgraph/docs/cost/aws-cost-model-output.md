### Production (pilot), tasks in public subnets — no NAT

| Category | Item | Calculation | USD/month | Price basis |
|---|---|---|---:|---|
| Database | RDS PostgreSQL db.t4g.medium Multi-AZ | 0.203 × 730 h | 148.19 | verified |
| Database | gp3 storage 50 GB Multi-AZ | 50 × 0.276 | 13.80 | verified |
| Backups | Automated backups / 7-day PITR | within free allocation (allocation size is an assumption) | 0.00 | **assumption** |
| Backups | Monthly snapshots kept 12 months (~30 GB extra) | 30 × 0.095 | 2.85 | verified |
| Backups | Monthly restore drill (4 h db.t4g.medium Single-AZ) | 4 × 0.102 | 0.41 | verified |
| Compute | API: 2 × (0.5 vCPU, 1 GB) Fargate ARM | 2 × 730 × (0.5×0.04045 + 1×0.00442) | 35.98 | verified |
| Compute | Web: 2 × (0.5 vCPU, 1 GB) | same | 35.98 | verified |
| Compute | Worker: 1 × (0.25 vCPU, 0.5 GB) | 730 × (0.25×0.04045 + 0.5×0.00442) | 9.00 | verified |
| Network | Application Load Balancer + ~1 LCU | 730 × (0.0252 + 0.008) | 24.24 | verified |
| Network | Public IPv4: ALB (2) + 5 tasks | 7 × 0.005 × 730 | 25.55 | verified |
| Network | Internet egress 50 GB | 50 × 0.12 (ignores free tier) | 6.00 | verified |
| Network | Inter-AZ traffic 50 GB | 50 × 0.01 | 0.50 | verified |
| Network | Route 53 hosted zone + queries | 0.50 + 0.40 | 0.90 | **assumption** |
| Storage | S3 50 GB + requests | 50×0.025 + 100k PUT + 1M GET | 2.15 | verified |
| Monitoring | CloudWatch Logs 10 GB ingest + 10 GB stored | 10×0.70 + 10×0.03 | 7.30 | verified |
| Monitoring | 20 custom metrics + 15 alarms | 20×0.30 + 15×0.10 | 7.50 | verified |
| Security | Secrets Manager 8 secrets + API calls | 8×0.40 + 100k×0.000005 | 3.70 | verified |
| Security | KMS: 2 customer-managed keys | 2 × 1.00 | 2.00 | **assumption** |
| Security | WAF: 1 web ACL + 5 rules + 2M requests | 5 + 5×1 + 2M×0.0000006 | 11.20 | verified |
| Other | SES 2,000 emails | 2000 × 0.0001 | 0.20 | verified |
| | **Total** | | **337.44** | of which verified-price items: 334.54 |

### Production (pilot), private subnets + 1 NAT gateway — variant

| Category | Item | Calculation | USD/month | Price basis |
|---|---|---|---:|---|
| Database | RDS PostgreSQL db.t4g.medium Multi-AZ | 0.203 × 730 h | 148.19 | verified |
| Database | gp3 storage 50 GB Multi-AZ | 50 × 0.276 | 13.80 | verified |
| Backups | Automated backups / 7-day PITR | within free allocation (allocation size is an assumption) | 0.00 | **assumption** |
| Backups | Monthly snapshots kept 12 months (~30 GB extra) | 30 × 0.095 | 2.85 | verified |
| Backups | Monthly restore drill (4 h db.t4g.medium Single-AZ) | 4 × 0.102 | 0.41 | verified |
| Compute | API: 2 × (0.5 vCPU, 1 GB) Fargate ARM | 2 × 730 × (0.5×0.04045 + 1×0.00442) | 35.98 | verified |
| Compute | Web: 2 × (0.5 vCPU, 1 GB) | same | 35.98 | verified |
| Compute | Worker: 1 × (0.25 vCPU, 0.5 GB) | 730 × (0.25×0.04045 + 0.5×0.00442) | 9.00 | verified |
| Network | Application Load Balancer + ~1 LCU | 730 × (0.0252 + 0.008) | 24.24 | verified |
| Network | Public IPv4: ALB (2) + NAT (1) | 3 × 0.005 × 730 | 10.95 | verified |
| Network | NAT gateway (1, single AZ) + 20 GB processed | 730 × 0.059 + 20 × 0.059 | 44.25 | verified |
| Network | Internet egress 50 GB | 50 × 0.12 (ignores free tier) | 6.00 | verified |
| Network | Inter-AZ traffic 50 GB | 50 × 0.01 | 0.50 | verified |
| Network | Route 53 hosted zone + queries | 0.50 + 0.40 | 0.90 | **assumption** |
| Storage | S3 50 GB + requests | 50×0.025 + 100k PUT + 1M GET | 2.15 | verified |
| Monitoring | CloudWatch Logs 10 GB ingest + 10 GB stored | 10×0.70 + 10×0.03 | 7.30 | verified |
| Monitoring | 20 custom metrics + 15 alarms | 20×0.30 + 15×0.10 | 7.50 | verified |
| Security | Secrets Manager 8 secrets + API calls | 8×0.40 + 100k×0.000005 | 3.70 | verified |
| Security | KMS: 2 customer-managed keys | 2 × 1.00 | 2.00 | **assumption** |
| Security | WAF: 1 web ACL + 5 rules + 2M requests | 5 + 5×1 + 2M×0.0000006 | 11.20 | verified |
| Other | SES 2,000 emails | 2000 × 0.0001 | 0.20 | verified |
| | **Total** | | **367.09** | of which verified-price items: 364.19 |

### Staging (always on)

| Category | Item | Calculation | USD/month | Price basis |
|---|---|---|---:|---|
| Database | RDS db.t4g.small Single-AZ | 0.051 × 730 | 37.23 | verified |
| Database | gp3 20 GB Single-AZ | 20 × 0.138 | 2.76 | verified |
| Compute | API, web: 1 task each (0.5 vCPU, 1 GB); worker 1 × (0.25, 0.5) |  | 44.98 | verified |
| Network | ALB + ~1 LCU | 730 × (0.0252 + 0.008) | 24.24 | verified |
| Network | Public IPv4: ALB (2) + 3 tasks | 5 × 0.005 × 730 | 18.25 | verified |
| Network | Internet egress 5 GB | 5 × 0.12 | 0.60 | verified |
| Storage | S3 ~5 GB | 5 × 0.025 | 0.12 | verified |
| Monitoring | Logs 3 GB + 5 alarms | 3×0.70 + 3×0.03 + 5×0.10 | 2.69 | verified |
| Security | Secrets Manager 8 secrets | 8 × 0.40 | 3.20 | verified |
| Security | KMS: 1 key | 1 × 1.00 | 1.00 | **assumption** |
| | **Total** | | **135.07** | of which verified-price items: 134.07 |

### Shared

| Category | Item | Calculation | USD/month | Price basis |
|---|---|---|---:|---|
| Shared | ECR images ~5 GB | 5 × 0.10 | 0.50 | verified |
| Shared | CloudTrail management events (first copy) | free per AWS policy (A) | 0.00 | **assumption** |
| | **Total** | | **0.50** | of which verified-price items: 0.50 |

**Summary:** production 337.44 (or 367.09 with NAT) + staging 135.07 + shared 0.50 = **473.01** / month (no NAT) or **502.66** (with NAT), excluding the identity provider.
