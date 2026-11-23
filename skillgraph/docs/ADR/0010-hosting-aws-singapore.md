# ADR-0010: Production hosting on AWS `ap-southeast-1` (Singapore), portable by design

Status: Proposed. Direction approved by the owner (D-5: global market, Singapore as initial primary region candidate). **Provider choice (A-7) requires owner approval**, as does validation of pricing and compliance.
Date: 2026-11-23

## Context
SKILLGRAPH targets a global market. Singapore is the owner's initial candidate primary region, subject to technical, pricing and compliance validation. The criteria are reliability, global latency, security, scalability, PostgreSQL support, object storage, operational complexity and actual cost. The architecture must stay portable for later regional expansion.

## Options evaluated

| Criterion | **AWS ap-southeast-1** | Google Cloud asia-southeast1 | Azure Southeast Asia | DigitalOcean SGP1 |
|---|---|---|---|---|
| Managed PostgreSQL | RDS for PostgreSQL, Multi-AZ, PITR; `pg_trgm`, `pgcrypto`, RLS supported | Cloud SQL, HA, PITR | Azure Database for PostgreSQL Flexible Server, zone-redundant HA | Managed PostgreSQL. **From 30 Nov 2026, Standard Edition no longer supports standby nodes** (DO release notes), so HA needs a different edition |
| Containers | ECS on Fargate (**App Runner closed to new customers since 30 Apr 2026**; AWS points new workloads to ECS Express Mode) | Cloud Run (simplest operations) | Container Apps | App Platform |
| Object storage | S3 (private, SSE-KMS, Block Public Access) | GCS | Blob Storage | Spaces (fewer IAM controls) |
| Security controls | Mature IAM, KMS, Secrets Manager, CloudTrail, GuardDuty; GitHub OIDC federation | Mature | Mature | Basic |
| Global expansion | Largest region footprint | Large | Large | Limited regions |
| Operational complexity | Medium–high (VPC, IAM, ECS) | **Lowest** of the hyperscalers | Medium | **Lowest** overall |
| Cost evidence | **Computed from AWS public price list (below)** | Third-party figures only (not verified) | Not computed | Third-party and vendor figures, partial |

### Recommendation: AWS `ap-southeast-1`
- PostgreSQL, object storage and the security tooling the PRD needs (KMS, secret manager, audit trail, private networking) are all mature.
- It has the largest footprint for later regional cells.
- Pricing could be verified from AWS's machine-readable public price list instead of blog posts.
- **Runner-up: Google Cloud (Cloud Run + Cloud SQL, asia-southeast1).** Operationally simpler, which matters for a small team. Before a final choice, get a like-for-like quote from the GCP pricing calculator; that wasn't possible here.
- DigitalOcean is the cheapest and simplest, but has weaker security controls and an HA change on 30 Nov 2026. Not recommended for credential and personal data at production quality.

## Cost estimate: AWS ap-southeast-1, on-demand list prices
Source: AWS Price List bulk files for `ap-southeast-1`, publication date **2026-11-20**, downloaded and parsed on 2026-11-23 (`AmazonRDS`, `AmazonECS`, `AmazonS3`, `AWSELB`, `AmazonVPC`). Prices are in USD, at 730 hours/month, before tax, with no Savings Plans or Reserved Instances. **These are estimates for an assumed configuration, not measured bills.**

| Unit price (verified from price list) | USD |
|---|---|
| RDS PostgreSQL db.t4g.medium (2 vCPU, 4 GiB), Multi-AZ | 0.2030 /hour |
| RDS PostgreSQL db.t4g.small (2 vCPU, 2 GiB), Single-AZ | 0.0510 /hour |
| RDS PostgreSQL db.m7g.large (2 vCPU, 8 GiB), Multi-AZ | 0.4680 /hour |
| RDS gp3 storage, Multi-AZ / Single-AZ | 0.276 / 0.138 per GB-month |
| RDS backup storage beyond free allocation | 0.095 per GB-month |
| Fargate Linux ARM (Graviton): vCPU / GB | 0.04045 / 0.00442 per hour |
| S3 Standard storage (first 50 TB) | 0.025 per GB-month |
| S3 PUT-class / GET-class requests | 0.005 / 0.0004 per 1,000 |
| Application Load Balancer: hour / LCU-hour | 0.0252 / 0.008 |
| Public IPv4 address in use | 0.005 /hour |

**Pilot production environment (assumed sizing)**

| Item | Calculation | USD/month |
|---|---|---|
| RDS db.t4g.medium Multi-AZ | 0.203 × 730 | 148.19 |
| RDS storage 50 GB gp3 Multi-AZ | 50 × 0.276 | 13.80 |
| API: 2 Fargate tasks × (0.5 vCPU, 1 GB) ARM | 2 × 730 × (0.5×0.04045 + 1×0.00442) | 35.98 |
| Web (Next.js): 2 tasks × (0.5 vCPU, 1 GB) | same | 35.98 |
| Worker: 1 task × (0.25 vCPU, 0.5 GB) | 730 × (0.25×0.04045 + 0.5×0.00442) | 9.00 |
| ALB: 1 load balancer + ~1 LCU average | 730 × (0.0252 + 0.008) | 24.24 |
| Public IPv4: 2 (ALB) + 5 (tasks) | 7 × 0.005 × 730 | 25.55 |
| S3: 50 GB + ~1M GET + 100k PUT | 1.25 + 0.40 + 0.50 | 2.15 |
| **Subtotal (verified unit prices)** | | **≈ 295** |
| Not extracted from the price list: data transfer out, CloudWatch Logs, Secrets Manager, KMS, ECR, Route 53, optional WAF | estimate, **not verified** | 25–60 |
| **Pilot production total (estimate)** | | **≈ 320–355** |

**Staging:** RDS db.t4g.small Single-AZ ($37.23) + 20 GB ($2.76) + 3 single Fargate tasks ($44.98) + ALB ($24.24) + 5 IPv4 ($18.25) + S3 (~$0.50) ≈ **$128**, plus ~$15–30 not verified.

**Identity provider:** ZITADEL Cloud Free ($0, 100 DAU) or Pro ($100/month); Cognito ~$0 below 10k MAU. See ADR-0009.

**Indicative total for pilot production + staging + IdP Pro: ≈ $560–615/month before discounts.** Development runs locally at $0.

Notes:
- Fargate tasks run in public subnets with public IPv4 addresses, and their security groups accept inbound traffic **only from the ALB**. This avoids a NAT gateway, which is hourly plus per-GB and wasn't in the price files parsed (cost **not verified**). RDS sits in private subnets with no public access.
- The cost is dominated by Multi-AZ RDS. A pilot with no availability commitment could run Single-AZ (db.t4g.medium Single-AZ: 0.102/hour = $74.46), but the PRD §5 target of 99.5% favours Multi-AZ.
- Production prices must be re-checked in the AWS Pricing Calculator at approval time. Commitment discounts are deliberately not assumed.

## Global latency
One region serves all users. Latency from Europe and the Americas to Singapore will be noticeably higher than from Asia. **This isn't measured; it's a known property of single-region hosting.** Mitigations:
- serve the web app's static assets via CloudFront;
- keep API payloads small and paginated;
- add regional cells (below) when real usage outside Asia justifies it.

## Portability and regional expansion (design rules from Phase 1)
1. **Cells, not a global multi-master database.** Each region is a complete SKILLGRAPH deployment (API, worker, PostgreSQL, bucket). Organisations and users carry a `home_region` (DATA_MODEL §1–2), and personal and organisation data never leave their home cell except under an explicit transfer.
2. **Public reference data** (published skills, frameworks, approved relationships) is authored in one primary cell and replicated read-only to others, in Phase 5+, when there is a second cell.
3. **Credential verification URLs** include the issuing cell's host, so verifiers reach the right region without a global lookup.
4. **Cloud portability.** Containers are plain OCI images. The database is standard PostgreSQL 16 (no Aurora-specific features). Storage goes through the S3 API behind the `ObjectStorage` interface. Infrastructure is described in OpenTofu/Terraform under `skillgraph/infra/`. No AWS-specific SDK calls outside the storage, email and secrets adapters.

## Consequences
- Phase 1 staging deployment needs an AWS account plus GitHub-to-AWS OIDC federation set up by the owner. Without them, Phase 1 delivers a locally runnable system and IaC that has been validated (`tofu validate` / `plan`) but not applied.
- The PRD §5 availability objective (99.5%) is realistic with Multi-AZ RDS and two tasks per service, but it is a target until measured.

## Sources
- AWS Price List bulk API, `https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/<service>/current/ap-southeast-1/index.json`, publication 2026-11-20
- App Runner availability change: https://docs.aws.amazon.com/apprunner/latest/dg/apprunner-availability-change.html
- DigitalOcean plan changes: https://docs.digitalocean.com/release-notes/upcoming/dbaas-plan-changes/. Pricing: https://docs.digitalocean.com/products/databases/postgresql/details/pricing/
- GCP (third-party, unverified): https://www.usage.ai/blogs/gcp/cloud-sql/pricing/, https://cloud.google.com/run/pricing
