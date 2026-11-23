#!/usr/bin/env python3
"""SKILLGRAPH AWS ap-southeast-1 cost model (estimate only).

Every unit price is tagged:
  V = verified from the AWS Price List bulk files for ap-southeast-1
      (publication dates 2026-11-02 .. 2026-11-21, downloaded 2026-11-23; see
      docs/cost/aws-price-snapshot-2026-11.txt)
  A = assumption (not found in the files parsed; taken from general AWS documentation/knowledge,
      must be confirmed in the AWS Pricing Calculator before approval)
Usage quantities are ALWAYS assumptions about pilot load (see USAGE below), not measurements.

Run: python3 scripts/cost/aws_cost_model.py   (prints Markdown tables)
"""

HOURS = 730  # hours per month used by AWS pricing examples

# --- unit prices (USD) ------------------------------------------------------------------
P = {
    # RDS for PostgreSQL (V)
    "rds_t4g_medium_maz_hr": (0.2030, "V"),
    "rds_t4g_small_saz_hr": (0.0510, "V"),
    "rds_t4g_medium_saz_hr": (0.1020, "V"),
    "rds_m7g_large_maz_hr": (0.4680, "V"),
    "rds_gp3_maz_gbmo": (0.276, "V"),
    "rds_gp3_saz_gbmo": (0.138, "V"),
    "rds_backup_gbmo": (0.095, "V"),  # beyond the free allocation
    # Fargate Linux/ARM (V)
    "fargate_arm_vcpu_hr": (0.04045, "V"),
    "fargate_arm_gb_hr": (0.00442, "V"),
    # Load balancer, IPs, NAT (V)
    "alb_hr": (0.0252, "V"),
    "alb_lcu_hr": (0.008, "V"),
    "ipv4_hr": (0.005, "V"),
    "nat_hr": (0.059, "V"),
    "nat_gb": (0.059, "V"),
    # Data transfer (V)
    "egress_gb_first10tb": (0.12, "V"),  # internet egress, beyond the global free tier
    "regional_gb": (0.01, "V"),  # inter-AZ, per GB per direction
    # S3 (V)
    "s3_gbmo": (0.025, "V"),
    "s3_put_per_req": (0.000005, "V"),
    "s3_get_per_req": (0.0000004, "V"),
    # Observability (V)
    "cw_logs_ingest_gb": (0.70, "V"),
    "cw_logs_store_gbmo": (0.03, "V"),
    "cw_metric_mo": (0.30, "V"),
    "cw_alarm_mo": (0.10, "V"),
    # Secrets, registry, email, WAF (V)
    "secret_mo": (0.40, "V"),
    "secrets_api_per_req": (0.000005, "V"),
    "ecr_gbmo": (0.10, "V"),
    "ses_per_email": (0.0001, "V"),
    "waf_acl_mo": (5.00, "V"),
    "waf_rule_mo": (1.00, "V"),
    "waf_per_req": (0.0000006, "V"),
    # Not found in parsed files (A)
    "rds_backup_free_alloc": (0.0, "A"),  # AWS docs: backup storage up to 100% of provisioned storage is free
    "kms_key_mo": (1.00, "A"),
    "route53_zone_mo": (0.50, "A"),
    "route53_queries_mo": (0.40, "A"),  # ~1M public DNS queries
}

# --- usage assumptions (pilot) ------------------------------------------------------------
USAGE = {
    "prod_egress_gb": 50,  # API + web responses to the internet per month
    "prod_interaz_gb": 50,  # ALB<->tasks<->RDS crossing AZs (both directions counted once each)
    "prod_logs_gb": 10,
    "prod_log_store_gb": 10,  # ~30-day retention
    "prod_custom_metrics": 20,
    "prod_alarms": 15,
    "prod_secrets": 8,
    "prod_secret_api_reqs": 100_000,
    "prod_db_storage_gb": 50,
    "prod_extra_backup_gb": 30,  # 12 monthly manual snapshots beyond the free allocation
    "prod_s3_gb": 50,
    "prod_s3_put": 100_000,
    "prod_s3_get": 1_000_000,
    "prod_requests": 2_000_000,  # through WAF
    "emails": 2_000,
    "staging_egress_gb": 5,
    "staging_logs_gb": 3,
    "staging_db_storage_gb": 20,
    "ecr_gb": 5,
}


def p(key):
    return P[key][0]


def tag(keys):
    return "V" if all(P[k][1] == "V" for k in keys) else "A"


def fargate(tasks, vcpu, gb):
    return tasks * HOURS * (vcpu * p("fargate_arm_vcpu_hr") + gb * p("fargate_arm_gb_hr"))


def rows_prod(nat=False):
    u = USAGE
    r = []
    add = lambda cat, item, calc, cost, keys: r.append((cat, item, calc, cost, tag(keys)))
    add("Database", "RDS PostgreSQL db.t4g.medium Multi-AZ", "0.203 × 730 h", p("rds_t4g_medium_maz_hr") * HOURS, ["rds_t4g_medium_maz_hr"])
    add("Database", f"gp3 storage {u['prod_db_storage_gb']} GB Multi-AZ", f"{u['prod_db_storage_gb']} × 0.276", u["prod_db_storage_gb"] * p("rds_gp3_maz_gbmo"), ["rds_gp3_maz_gbmo"])
    add("Backups", "Automated backups / 7-day PITR", "within free allocation (allocation size is an assumption)", 0.0, ["rds_backup_free_alloc"])
    add("Backups", f"Monthly snapshots kept 12 months (~{u['prod_extra_backup_gb']} GB extra)", f"{u['prod_extra_backup_gb']} × 0.095", u["prod_extra_backup_gb"] * p("rds_backup_gbmo"), ["rds_backup_gbmo"])
    add("Backups", "Monthly restore drill (4 h db.t4g.medium Single-AZ)", "4 × 0.102", 4 * p("rds_t4g_medium_saz_hr"), ["rds_t4g_medium_saz_hr"])
    add("Compute", "API: 2 × (0.5 vCPU, 1 GB) Fargate ARM", "2 × 730 × (0.5×0.04045 + 1×0.00442)", fargate(2, 0.5, 1), ["fargate_arm_vcpu_hr"])
    add("Compute", "Web: 2 × (0.5 vCPU, 1 GB)", "same", fargate(2, 0.5, 1), ["fargate_arm_vcpu_hr"])
    add("Compute", "Worker: 1 × (0.25 vCPU, 0.5 GB)", "730 × (0.25×0.04045 + 0.5×0.00442)", fargate(1, 0.25, 0.5), ["fargate_arm_vcpu_hr"])
    add("Network", "Application Load Balancer + ~1 LCU", "730 × (0.0252 + 0.008)", HOURS * (p("alb_hr") + p("alb_lcu_hr")), ["alb_hr", "alb_lcu_hr"])
    if nat:
        add("Network", "Public IPv4: ALB (2) + NAT (1)", "3 × 0.005 × 730", 3 * p("ipv4_hr") * HOURS, ["ipv4_hr"])
        add("Network", "NAT gateway (1, single AZ) + 20 GB processed", "730 × 0.059 + 20 × 0.059", HOURS * p("nat_hr") + 20 * p("nat_gb"), ["nat_hr", "nat_gb"])
    else:
        add("Network", "Public IPv4: ALB (2) + 5 tasks", "7 × 0.005 × 730", 7 * p("ipv4_hr") * HOURS, ["ipv4_hr"])
    add("Network", f"Internet egress {u['prod_egress_gb']} GB", f"{u['prod_egress_gb']} × 0.12 (ignores free tier)", u["prod_egress_gb"] * p("egress_gb_first10tb"), ["egress_gb_first10tb"])
    add("Network", f"Inter-AZ traffic {u['prod_interaz_gb']} GB", f"{u['prod_interaz_gb']} × 0.01", u["prod_interaz_gb"] * p("regional_gb"), ["regional_gb"])
    add("Network", "Route 53 hosted zone + queries", "0.50 + 0.40", p("route53_zone_mo") + p("route53_queries_mo"), ["route53_zone_mo", "route53_queries_mo"])
    add("Storage", f"S3 {u['prod_s3_gb']} GB + requests", "50×0.025 + 100k PUT + 1M GET", u["prod_s3_gb"] * p("s3_gbmo") + u["prod_s3_put"] * p("s3_put_per_req") + u["prod_s3_get"] * p("s3_get_per_req"), ["s3_gbmo"])
    add("Monitoring", f"CloudWatch Logs {u['prod_logs_gb']} GB ingest + {u['prod_log_store_gb']} GB stored", "10×0.70 + 10×0.03", u["prod_logs_gb"] * p("cw_logs_ingest_gb") + u["prod_log_store_gb"] * p("cw_logs_store_gbmo"), ["cw_logs_ingest_gb"])
    add("Monitoring", f"{u['prod_custom_metrics']} custom metrics + {u['prod_alarms']} alarms", "20×0.30 + 15×0.10", u["prod_custom_metrics"] * p("cw_metric_mo") + u["prod_alarms"] * p("cw_alarm_mo"), ["cw_metric_mo", "cw_alarm_mo"])
    add("Security", f"Secrets Manager {u['prod_secrets']} secrets + API calls", "8×0.40 + 100k×0.000005", u["prod_secrets"] * p("secret_mo") + u["prod_secret_api_reqs"] * p("secrets_api_per_req"), ["secret_mo"])
    add("Security", "KMS: 2 customer-managed keys", "2 × 1.00", 2 * p("kms_key_mo"), ["kms_key_mo"])
    add("Security", "WAF: 1 web ACL + 5 rules + 2M requests", "5 + 5×1 + 2M×0.0000006", p("waf_acl_mo") + 5 * p("waf_rule_mo") + u["prod_requests"] * p("waf_per_req"), ["waf_acl_mo"])
    add("Other", "SES 2,000 emails", "2000 × 0.0001", u["emails"] * p("ses_per_email"), ["ses_per_email"])
    return r


def rows_staging():
    u = USAGE
    r = []
    add = lambda cat, item, calc, cost, keys: r.append((cat, item, calc, cost, tag(keys)))
    add("Database", "RDS db.t4g.small Single-AZ", "0.051 × 730", p("rds_t4g_small_saz_hr") * HOURS, ["rds_t4g_small_saz_hr"])
    add("Database", f"gp3 {u['staging_db_storage_gb']} GB Single-AZ", "20 × 0.138", u["staging_db_storage_gb"] * p("rds_gp3_saz_gbmo"), ["rds_gp3_saz_gbmo"])
    add("Compute", "API, web: 1 task each (0.5 vCPU, 1 GB); worker 1 × (0.25, 0.5)", "", fargate(2, 0.5, 1) + fargate(1, 0.25, 0.5), ["fargate_arm_vcpu_hr"])
    add("Network", "ALB + ~1 LCU", "730 × (0.0252 + 0.008)", HOURS * (p("alb_hr") + p("alb_lcu_hr")), ["alb_hr"])
    add("Network", "Public IPv4: ALB (2) + 3 tasks", "5 × 0.005 × 730", 5 * p("ipv4_hr") * HOURS, ["ipv4_hr"])
    add("Network", f"Internet egress {u['staging_egress_gb']} GB", "5 × 0.12", u["staging_egress_gb"] * p("egress_gb_first10tb"), ["egress_gb_first10tb"])
    add("Storage", "S3 ~5 GB", "5 × 0.025", 5 * p("s3_gbmo"), ["s3_gbmo"])
    add("Monitoring", f"Logs {u['staging_logs_gb']} GB + 5 alarms", "3×0.70 + 3×0.03 + 5×0.10", u["staging_logs_gb"] * (p("cw_logs_ingest_gb") + p("cw_logs_store_gbmo")) + 5 * p("cw_alarm_mo"), ["cw_logs_ingest_gb"])
    add("Security", "Secrets Manager 8 secrets", "8 × 0.40", 8 * p("secret_mo"), ["secret_mo"])
    add("Security", "KMS: 1 key", "1 × 1.00", p("kms_key_mo"), ["kms_key_mo"])
    return r


def rows_shared():
    u = USAGE
    return [("Shared", f"ECR images ~{u['ecr_gb']} GB", "5 × 0.10", u["ecr_gb"] * p("ecr_gbmo"), "V"),
            ("Shared", "CloudTrail management events (first copy)", "free per AWS policy (A)", 0.0, "A")]


def table(title, rows):
    out = [f"### {title}", "", "| Category | Item | Calculation | USD/month | Price basis |", "|---|---|---|---:|---|"]
    tot, totv = 0.0, 0.0
    for cat, item, calc, cost, t in rows:
        out.append(f"| {cat} | {item} | {calc} | {cost:,.2f} | {'verified' if t == 'V' else '**assumption**'} |")
        tot += cost
        totv += cost if t == "V" else 0
    out.append(f"| | **Total** | | **{tot:,.2f}** | of which verified-price items: {totv:,.2f} |")
    return "\n".join(out), tot


if __name__ == "__main__":
    parts = []
    t1, a = table("Production (pilot), tasks in public subnets — no NAT", rows_prod(nat=False))
    t2, b = table("Production (pilot), private subnets + 1 NAT gateway — variant", rows_prod(nat=True))
    t3, c = table("Staging (always on)", rows_staging())
    t4, d = table("Shared", rows_shared())
    print("\n\n".join([t1, t2, t3, t4]))
    print(f"\n**Summary:** production {a:,.2f} (or {b:,.2f} with NAT) + staging {c:,.2f} + shared {d:,.2f} "
          f"= **{a + c + d:,.2f}** / month (no NAT) or **{b + c + d:,.2f}** (with NAT), excluding the identity provider.")
