CL-01: 3-Tier Web Application on AWS
Internship Project: Automated API Poller & Monitoring System

**Project Overview**
This project is a fully automated 3-tier web application deployed on AWS using Terraform. It consists of a React-based frontend, a Dockerized Flask backend, and an Amazon Aurora (PostgreSQL) database. The system allows users to input a public REST API, set a polling frequency, and store the results in a private database with real-time monitoring via CloudWatch.

**System Architecture**
Presentation Tier: A React.js application served via Nginx on a Public EC2 instance. It acts as the entry point for user input (API URL, frequency, duration).

Application Tier: A Python Flask worker running inside a Docker container on a Private EC2 instance. It handles the polling logic and database commits.

Data Tier: An Amazon Aurora Serverless (PostgreSQL) database isolated in private subnets, accessible only by the backend application.

Monitoring: AWS CloudWatch Dashboards tracking successful API calls and HTTP errors via custom Metric Filters.

**Tech Stack**
Infrastructure: Terraform, AWS VPC, EC2, RDS (Aurora), IAM, Security Groups.

Frontend: React.js, Nginx, Docker.

Backend: Python 3.9, Flask, Psycopg2, Docker.

Database: PostgreSQL (Amazon Aurora Serverless).

Monitoring: CloudWatch Logs & Dashboards.

**GenAI Usage Documentation**
As per the mandatory project requirements, GenAI (Gemini 1.5 Flash) was utilized for system design and debugging.

Tools Used
Gemini 1.5 Flash: For architectural guidance and error resolution.

Specific Prompts & Questions
"How do I fix FATAL: password authentication failed when my psql manual test works but Docker fails?"

"Why is my CloudWatch Metric Filter not showing any data in the 'Custom Namespaces' list?"

"How do I configure Nginx to forward traffic from Port 80 on a Public EC2 to a Flask app on a Private EC2?"

Reflection
The GenAI tool was instrumental in solving "environment ghosting" issues. Specifically, it identified that Docker was caching old environment variables and that CloudWatch filters require double quotes for patterns containing spaces. It saved approximately 4–6 hours of manual troubleshooting by providing immediate feedback on AWS-specific networking hurdles.

**Proof of Implementation**
(Note: Replace these placeholders with your actual screenshots before submission)

1. Presentation Tier (React UI)
Shows the UI successfully triggering the polling logic.

2. Data Persistence (PostgreSQL)
Shows SELECT * FROM api_results; output with live Cat Fact data.

3. Monitoring (CloudWatch Dashboard)
Shows the TotalAPICalls graph tracking successful requests.

4. Infrastructure Cleanup (Terraform Destroy)
Proof of successful resource termination.

**Deployment Instructions**
Initialize Infrastructure:

terraform init
terraform apply -auto-approve
Access the UI:
Open the Public IP of the Frontend EC2 in your browser.

Monitor Logs:
Check CloudWatch Log Group api-poller-log-group for real-time processing.

Cleanup:

terraform destroy