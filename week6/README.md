# End-to-End DevOps & Observability Platform (Zero-Touch)

This repository contains the completely unified implementation for both your **Week 3 (Highly Available WordPress on ECS)** and **Week 6 (SRE-STACK-ONE Monitoring Platform)** milestones.

## Core Objective
> *If the system breaks → the system tells you why.*

We've established a self-observable production system leveraging free-tier components to deploy a scalable WordPress site, monitor AWS infrastructure, track application health, and automatically generate daily reliability reports **entirely hosted in AWS without manual script execution**.

---

## 🏗 Architecture Overview (Zero-Touch Visual)

### Written Overview
1. **Network & Compute**: Custom VPC. EC2 instances automatically join an ECS Cluster. WordPress scales elastically based on an AppAutoScaling policy (CPU > 70%).
2. **Observability Node**: A dedicated `t2.micro` boots up and self-installs the Prometheus/Grafana stack via `user_data`, preloading our custom **SRE JSON Dashboard**.
3. **Lambda Cron**: An AWS Lambda function is provisioned to execute `scripts/daily_reliability_report.py`. EventBridge runs this Lambda daily, securely pulling Prometheus targets and parsing CloudWatch logs utilizing IAM roles (bypassing the need to store AWS credentials locally).

---

## 🚀 Deployment Instructions

### 1. Unified Provisioning
To stand up the *entire* infrastructure, databases, dashboards, and automated email scripts simultaneously:

```bash
cd terraform

export TF_VAR_smtp_email="your_gmail@gmail.com"
export TF_VAR_smtp_password="your_app_password"

terraform init
terraform apply --auto-approve
```

### 2. Accessing the Live Systems
When Terraform completes, it will instantly print out three critical URLs:
1. `wordpress_alb_dns`: The public address to access your Highly Available WordPress installation.
2. `observability_grafana_url`: The address to access your live Grafana Dashboards (`http://<IP>:3000`).
3. `observability_prometheus_url`: The address for Prometheus query debugging (`http://<IP>:9090`).

*(Note: Give the Observability node about 3 minutes to finish pulling the Docker images via its startup scripts before the URL will load).*

### 3. Teardown Instructions (CRITICAL)
To prevent unexpected AWS billing:
```bash
cd terraform
terraform destroy --auto-approve
```

---

## 🛠 GenAI Usage Log

As part of the mandatory GenAI integration for the module, the following tools and prompts were utilized:

| Tool Used | Purpose |
|-----------|---------|
| Google Gemini | Architecture design, Terraform module abstractions, Python Lambda packaging. |

### Reflection
* **Efficiency**: GenAI structured the transition from "local manual scripts" to a purely Serverless Lambda / EC2 User-Data approach in seconds, avoiding enormous amounts of trial-and-error with IAM profiles and CloudWatch integrations.
* **Architecture Influence**: By injecting the dashboard JSONs directly into the EC2 boot sequence using Terraform strings, GenAI successfully eliminated the need for manual configuration of Grafana, achieving 100% automation.
* **Documentation Quality**: SRE documents continue to align perfectly with industry standard Incident templates.
