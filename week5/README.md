# CL-05 & SRE-102: Highly Available WordPress on AWS with SLO Monitoring

## Project Overview
This project provisions a highly available, fault-tolerant, and scalable WordPress deployment on AWS entirely via Terraform. The infrastructure is built within AWS Free Tier limits where possible and includes an automated monitoring suite using Amazon CloudWatch for Service Level Objective (SLO) tracking and alerting.

## Architecture Description
The application architecture spans multiple Availability Zones to ensure high availability and is divided into several modular components:

1. **Networking (`modules/networking`)**: 
   - A custom VPC (`10.0.0.0/16`) spanning two Availability Zones (`us-east-1a`, `us-east-1b`).
   - Public subnets host the Application Load Balancer and NAT Gateway.
   - Private subnets securely house the EC2 instances, EFS, and RDS database.

2. **Security (`modules/security`)**:
   - Strict Security Groups ensuring traffic only flows top-down:
     - `alb_sg`: Allows 80/443 from `0.0.0.0/0`.
     - `ec2_sg`: Allows 80 only from the `alb_sg`.
     - `rds_sg`: Allows 3306 only from the `ec2_sg`.
     - `efs_sg`: Allows 2049 only from the `ec2_sg`.

3. **Compute & Storage (`modules/compute`)**:
   - An Auto Scaling Group (ASG) maintaining a desired capacity of 2 instances but capable of scaling to 4.
   - An Application Load Balancer (ALB) distributing traffic across the ASG.
   - Amazon Elastic File System (EFS) mounted at `/var/www/html` to ensure all EC2 instances share the same media library and WordPress core files perfectly.
   - Target Tracking Scaling Policy automatically adds instances when average CPU utilization hits 40%.

4. **Database (`modules/database`)**:
   - An RDS MySQL instance deployed in private subnets.
   - Secured automatically via **RDS Managed Passwords** (AWS Secrets Manager integrates directly with RDS, rotating passwords automatically without plaintext secrets in Terraform state).

5. **IAM (`modules/iam`)**:
   - Least privilege IAM roles attached to the EC2 instances granting access to AWS Systems Manager (SSM) and read access to the Secrets Manager DB password.

## SRE-102: SLOs and Monitoring Infrastructure

As part of the Site Reliability Engineering requirements, a dedicated monitoring module (`modules/monitoring`) was constructed using Terraform. 

### Defined SLOs (Service Level Objectives)
1. **Capacity (CPU)**: ASG Average CPU Utilization > 80% for 4 minutes.
2. **Capacity (DB)**: RDS Database Connections > 50 for 4 minutes.
3. **Availability (Errors)**: ALB 5xx Error Rate > 5 errors in 2 minutes.
4. **Composite Latency SLO**: Triggers only if Web Response Latency is > 2s AND Database Read Latency > 100ms simultaneously.

### Infrastructure as Code (IaC) Monitoring
- All Alarm configurations are defined in `modules/monitoring/main.tf` and are wired to Amazon SNS to dispatch email alerts on state changes.
- A central **CloudWatch Dashboard** (`WordPress-SRE-Dashboard`) was programmatically generated using `modules/monitoring/dashboard.tf` to display graphs of the four SLOs along with their critical threshold annotations.

### Synthetic Event Simulation (Challenge)
A load simulation was performed to test the alarm and autoscaling system:
1. Accessed the EC2 instance securely via AWS Systems Manager.
2. Installed and ran `stress --cpu 4 --timeout 300` to artificially max out the CPU.
3. **Result**: The CloudWatch CPU metric spiked, sending an SNS alert for SLO violation. Concurrently, the ASG Target Tracking policy correctly recognized the 50% average CPU breach and provisioned a 3rd EC2 instance automatically. The WordPress site remained stable and correctly served media files from EFS across the new instances.

---

## 🤖 Mandatory GenAI Usage Summary

**What GenAI tool(s) you used:**
I utilized Google DeepMind's Antigravity (Agentic AI) as a pair programming assistant.

**Specific prompts/questions asked:**
1. *"Understand the directory first."*
2. *"Is this done using RDS managed passwords via terraform? Yes, update it to RDS managed pass."*
3. *"Here are my module requirements... SRE-102: Setting Up SLOs and Monitoring with CloudWatch... First complete CL-05 and keep in mind to keep it in free tier... then we will move to complete sre-102."*
4. *"How to check if db is connected correctly?"*

**Reflection on GenAI Assistance:**
- **Did the tools save you time?** Yes, significantly. Updating the existing Terraform module to use RDS Managed Passwords alongside Secrets Manager IAM permissions from scratch would have taken hours of AWS documentation review. The AI implemented the proper `jq` script natively in the `user_data.sh` bash script in seconds.
- **SRE & SLO Design:** The AI assisted by analyzing the requirements and immediately designing 4 relevant SLOs covering latency, capacity, and error rates aligned to AWS specific metric names (`HTTPCode_Target_5XX_Count`, `TargetResponseTime`, etc.). 
- **Dashboard Generation:** The AI completely scaffolds the complex JSON body required by `aws_cloudwatch_dashboard` via Terraform automatically.
- **Debugging & Commands:** When I could not access log files, the AI instantly pointed out the correct `sudo` usage, and supplied the `stress` installation commands specifically optimized for Amazon Linux 2023 (`dnf install stress`), saving time on environment troubleshooting.

---

## Deployment Instructions

1. Initialize Terraform:
   ```bash
   terraform init
   ```
2. Deploy the Infrastructure (provide your email for CloudWatch alerts):
   ```bash
   terraform apply -var="sns_email=your.email@example.com" -auto-approve
   ```
3. *Confirm the SNS Subscription email you receive.*
4. Access the WordPress site via the ALB DNS Output:
   ```bash
   terraform output wordpress_url
   ```
5. Tear down to avert continuing charges (important: NAT Gateway is NOT free tier):
   ```bash
   terraform destroy -var="sns_email=your.email@example.com" -auto-approve
   ```
