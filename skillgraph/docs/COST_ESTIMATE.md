# AWS Singapore (ap-southeast-1) Cost Estimate: Pilot

**Status:** Estimate for owner Decision 4. **No infrastructure has been provisioned, and none will be without explicit approval.**
**Date:** 2026-11-23 · **Currency:** USD, before tax · **Pricing:** on-demand list prices (no Savings Plans or Reserved Instances) · **Month:** 730 hours

## Evidence rules
- **Verified price:** the unit price was read from the **official AWS Price List bulk files** for `ap-southeast-1` (publication dates 2026-11-02 to 2026-11-21), downloaded and parsed on 2026-11-23. The raw extract is [`cost/aws-price-snapshot-2026-11.txt`](cost/aws-price-snapshot-2026-11.txt).
- **Assumption (price):** not found in the parsed files; based on general AWS pricing knowledge. Confirm in the AWS Pricing Calculator.
- **Assumption (usage):** every quantity (GB, requests, users, task sizes) is an assumption about pilot load, not a measurement. They're listed in §4.
- Reproducible: `python3 scripts/cost/aws_cost_model.py` prints every line item. Full output: [`cost/aws-cost-model-output.md`](cost/aws-cost-model-output.md).

## 1. Summary

| Environment | Monthly estimate | Of which items with assumption-priced units |
|---|---:|---:|
| Production (pilot), public subnets, no NAT gateway | **$337.44** | $2.90 (KMS, Route 53) |
| Production variant: private subnets + 1 NAT gateway | $367.09 | $2.90 |
| Staging, always on | **$135.07** | $1.00 (KMS) |
| Staging, scheduled (12 h × 22 weekdays; RDS and tasks stopped otherwise) | ≈ $75.63 | $1.00 |
| Shared (container registry) | $0.50 | — |
| **Total: production + staging (always on), no NAT** | **$473.01** | |
| Total with NAT variant | $502.66 | |
| *Not included:* identity provider ([IDP_COMPARISON.md](IDP_COMPARISON.md): Cognito ≈ $0–4 at pilot scale; ZITADEL Free or $100), AWS Support plan, domain registration, GuardDuty, error-monitoring SaaS, CloudFront, tax | | |

## 2. Production by category (no-NAT design)

| Category | USD/month | What's in it |
|---|---:|---|
| Database | 161.99 | RDS for PostgreSQL db.t4g.medium **Multi-AZ** ($0.203/h) + 50 GB gp3 Multi-AZ ($0.276/GB-mo) |
| Backups | 3.26 | Automated backups with 7-day point-in-time recovery: **$0, assuming** they fit in the free allocation (AWS documents it as equal to provisioned storage; the price file confirms a "free allocation" exists but not its size). 12 monthly snapshots ≈ 30 GB extra × $0.095. A monthly 4-hour restore drill ($0.41) |
| Compute | 80.96 | Fargate ARM: API 2 × (0.5 vCPU, 1 GB), web 2 × (0.5, 1), worker 1 × (0.25, 0.5) at $0.04045 per vCPU-h and $0.00442 per GB-h |
| Network | 57.19 | ALB $0.0252/h + 1 LCU ($0.008/LCU-h) = $24.24; 7 public IPv4 × $0.005/h = $25.55; internet egress 50 GB × $0.12 = $6.00 (ignores AWS's free egress allowance); inter-AZ 50 GB × $0.01 = $0.50; Route 53 ≈ $0.90 (assumption) |
| Storage | 2.15 | S3 Standard 50 GB × $0.025 + 100k PUT ($0.005/1k) + 1M GET ($0.0004/1k) |
| Monitoring | 14.80 | CloudWatch Logs 10 GB ingest × $0.70 + 10 GB stored × $0.03; 20 custom metrics × $0.30; 15 alarms × $0.10 |
| Security | 16.90 | Secrets Manager 8 × $0.40 + API calls; KMS 2 keys × $1 (assumption); **WAF** web ACL $5 + 5 rules × $1 + 2M requests × $0.60/M |
| Email | 0.20 | SES 2,000 emails × $0.0001 |
| **Total** | **337.44** | |

**NAT variant (+$29.65):** tasks in private subnets need a NAT gateway for outbound calls (IdP, email, status lists). Verified price: NAT gateway $0.059/h + $0.059/GB processed → $44.25 for one gateway with 20 GB, while task public IPs (−$14.60) are no longer needed. A NAT gateway per Availability Zone (for high availability) would add a further ~$43/month.

## 3. Staging (always on): $135.07

| Category | USD/month |
|---|---:|
| Database: db.t4g.small Single-AZ ($0.051/h) + 20 GB gp3 Single-AZ ($0.138) | 39.99 |
| Compute: 1 API + 1 web task (0.5 vCPU, 1 GB) + 1 worker (0.25, 0.5) | 44.98 |
| Network: ALB + 1 LCU ($24.24), 5 IPv4 ($18.25), egress 5 GB ($0.60) | 43.09 |
| Storage: S3 ~5 GB | 0.12 |
| Monitoring: 3 GB logs + 5 alarms | 2.69 |
| Security: 8 secrets + 1 KMS key (KMS is an assumption) | 4.20 |

**Scheduled staging:** RDS can be stopped and Fargate tasks scaled to zero outside 12 h × 22 working days, which is 36.2% of the month. The ALB and its IPs still bill hourly. Stoppable items cost $93.16; 63.8% of that is saved, giving about **$75.63/month**. A stopped RDS instance restarts automatically after 7 days (AWS behaviour, assumption), so the scheduler must re-stop it.

## 4. Usage assumptions (all are assumptions)

| Assumption | Value |
|---|---|
| Internet egress (API + web) | 50 GB/month production, 5 GB staging |
| Inter-AZ traffic | 50 GB/month |
| Requests through the load balancer and WAF | 2 million/month |
| ALB load | ~1 LCU average |
| Database storage | 50 GB production, 20 GB staging |
| Object storage | 50 GB, 100k PUT, 1M GET |
| Logs | 10 GB/month ingested, ~30-day retention |
| Email | 2,000/month (invitations, notifications) |
| Secrets | 8 per environment |
| Task sizes | API and web 0.5 vCPU / 1 GB; worker 0.25 / 0.5. To be validated by Phase 4 load tests |

## 5. Sensitivity (verified unit prices)

| Change | Effect |
|---|---|
| Database → db.m7g.large Multi-AZ (2 vCPU, 8 GiB) | $341.64 instead of $148.19 (**+$193.45**) |
| Production database Single-AZ (no automatic failover; weakens the 99.5% target) | $74.46 instead of $148.19 (−$73.73), storage $0.138/GB instead of $0.276 |
| Egress at 500 GB/month | +$54.00 |
| Logs at 50 GB/month | +$29.20 (ingest) |
| WAF removed | −$11.20 (not recommended for a public API) |

## 6. Not yet priced or verified
- **AWS free tiers** (egress allowance, CloudWatch basics, CloudTrail first trail): ignored, so the estimate is conservative.
- **AWS Support plan:** none assumed. Production support plans have monthly minimums; owner decision.
- **GuardDuty, Security Hub, Config:** recommended later; usage-based and not estimated.
- **Commitment discounts** (Savings Plans, RDS Reserved Instances): not applied. Revisit after the pilot sizing is measured.
- **Multi-account setup** (separate production, staging and test accounts under AWS Organizations; recommended): no direct cost, but configuration work.
