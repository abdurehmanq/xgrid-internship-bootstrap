# Week 3 — Highly Available WordPress on ECS (Terraform)

## 1. Architecture Explanation

This deployment utilizes a containerized architecture designed to demonstrate foundational High Availability (HA) concepts while strictly adhering to a $0.00 AWS Free Tier budget constraint.

* **Networking:** A custom VPC spans two Availability Zones (Multi-AZ). It consists of two public subnets and an Internet Gateway. To avoid the ~$32/month cost of a NAT Gateway, private subnets were omitted, and resources were placed in public subnets with tightly restricted Security Groups.
* **Compute:** The ECS Cluster uses the EC2 launch type. An Auto Scaling Group (ASG) manages a single `t3.micro` instance across both AZs. If the active AZ fails, the ASG will automatically provision a replacement instance in the healthy AZ.
* **Orchestration:** WordPress and MariaDB are deployed together within a single ECS Task Definition. The ECS Service maintains a `desired_count` of 1, ensuring auto-recovery if a container or task crashes.
* **Database:** To avoid Amazon RDS hourly charges, the database layer is containerized (MariaDB 10.5) and co-located on the same Docker bridge network as the WordPress container. It is not exposed to the public internet.
* **Security:** Security Groups enforce strict ingress, allowing only HTTP (Port 80) and SSH (Port 22). IAM roles follow the principle of least privilege, with the `AmazonSSMManagedInstanceCore` policy attached to allow secure, keyless terminal access via AWS Systems Manager (SSM).


### Design Decisions & Omitted Components 

The Week 3 module provided several architecture options. To strictly enforce the mandatory $0.00 Free Tier constraint and minimize billing risks, the following components were intentionally omitted or explicitly selected:

* **t2.micro vs. t3.micro:** We implemented **`t3.micro`**. The `t2.micro` instance was omitted because AWS returned a Free Tier eligibility error during the initial `terraform apply`. Newer AWS accounts in certain regions default to `t3.micro` for their 750 free monthly hours.
* **Fargate vs. EC2 Launch Type:** We implemented **EC2**. Fargate was omitted because its compute pricing model poses a higher risk of accidental billing compared to the predictable 750 free hours of a single `t3.micro` EC2 instance. Furthermore, using the EC2 launch type gave us host-level access (via SSM) to physically observe Docker behavior and successfully demonstrate the port-conflict scaling failure required by Task 2.
* **ALB (Application Load Balancer):** **Omitted.** ALBs are not covered by the AWS Free Tier and incur a baseline hourly cost (approximately $16-$20/month minimum). To guarantee a $0 bill, we bypassed the ALB entirely and mapped traffic directly to the EC2 instance's public IP over HTTP. 
* **EFS (Elastic File System):** **Omitted.** While EFS has a small free tier, configuring shared network storage introduces a high risk of accidental billing if storage or throughput limits are exceeded. Instead, we used local host-path bind mounts on the EC2 instance to simulate database persistence safely.


## 2. Deployment Steps

**Step 1: Initialize Terraform**
Prepare the working directory and download the required AWS providers.

terraform init

**Step 2: Plan the Infrastructure**
Review the execution plan to verify the networking and ECS resources being created.

terraform plan

**Step 3: Apply Configuration**
Provision the infrastructure. Type yes when prompted.

terraform apply

**Step 4: Access the Application**
Retrieve the public IP address of the EC2 instance dynamically assigned by the ASG:

aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query "Reservations[*].Instances[*].PublicIpAddress" \
  --output text
Navigate to http://<EC2_PUBLIC_IP> in your web browser to access the WordPress installation.

## 3. Known Limitations (Architectural Trade-offs)
HTTP Only (No HTTPS/ALB): To utilize AWS Certificate Manager (ACM) for HTTPS, an Application Load Balancer (ALB) is required. Because ALBs are not covered under the perpetual Free Tier, this architecture maps port 80 directly to the EC2 host. In a production environment with a budget, an ALB would be introduced for SSL termination.

Scaling Constraint (Port Conflicts): The ECS Task Definition maps container port 80 to host port 80. Attempting to scale the desired_count to 2 on a single t3.micro instance results in a port conflict, as the second container cannot bind to the already-occupied host port. Scaling requires dynamic port mapping and an ALB.

Storage Persistence: This deployment utilizes local host-path bind mounts to simulate persistence. Because the storage is local to the EC2 instance, if the EC2 node is terminated, the database and WordPress uploads will reset. A production rollout would replace this with Amazon EFS (Elastic File System) for shared, cross-AZ persistence.

## 4. Cost Analysis (SRE Review)
This architecture is heavily optimized to remain strictly within the AWS Free Tier. Estimated Monthly Cost: $0.00.

Compute (EC2): 750 hours per month of t3.micro instances are included in the Free Tier. By setting the ASG max_size to 1, we guarantee we will not exceed this limit.

Orchestration (ECS): The ECS EC2 Launch Type incurs no additional charges; you only pay for the underlying EC2 instances.

Networking: The VPC, Route Tables, Internet Gateway, and Security Groups are free of charge. Data transfer inbound is free.

Access (SSM): AWS Systems Manager Session Manager is a free service, allowing us to drop SSH keys without increasing costs.

Avoided Costs: By containerizing MariaDB, we avoided RDS charges. By skipping the ALB and NAT Gateway, we avoided an estimated $50+/month in baseline infrastructure fees.

## 5. Troubleshooting Guide (SRE Simulations)
**Scenario 1: Task Scaling Failure (Port Conflict)**

Symptom: Changing desired_count from 1 to 2 results in the second task failing to launch, continuously stuck in a PROVISIONING -> STOPPED loop.

Root Cause: The Task Definition hardcodes host port 80. The single t3.micro instance can only bind port 80 to one container at a time.

Resolution/Production Fix: This is expected behavior for this Free Tier setup. To fix this in production, set hostPort: 0 in the Task Definition to enable dynamic port mapping, and place an Application Load Balancer (ALB) in front of the ASG to route traffic to the ephemeral ports.

**Scenario 2: Container/Task Crash (Self-Healing Recovery)**

Symptom: A container is manually killed on the host (sudo docker stop <container_id>), simulating an application crash.

Recovery Mechanism: The local ecs-agent detects the Docker process termination and alerts the AWS ECS Control Plane. Because the ECS Service monitors a strict desired_count of 1, it registers the task as unhealthy and instantly schedules a new replacement task on the EC2 instance. The application recovers automatically in under 20 seconds with zero human intervention.

**Scenario 3: Auto Scaling Group Creation Failure**

Symptom: terraform apply fails with the error: The specified instance type is not eligible for Free Tier.

Root Cause: AWS blocked the launch of a t2.micro instance as newer accounts default to t3.micro for Free Tier eligibility in certain regions.

Resolution: Updated the instance_type in the aws_launch_template to t3.micro and re-applied the Terraform configuration.

