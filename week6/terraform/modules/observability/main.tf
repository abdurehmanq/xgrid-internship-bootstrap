variable "vpc_id" {}
variable "public_subnet_id" {}
variable "project_name" {}

data "aws_ssm_parameter" "amazon_linux" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_iam_policy_document" "obs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "obs_node_role" {
  name_prefix        = "obs-node-role"
  assume_role_policy = data.aws_iam_policy_document.obs_node_doc.json
}

resource "aws_iam_role_policy_attachment" "obs_node_role_policy" {
  role       = aws_iam_role.obs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "obs_node_ssm_policy" {
  role       = aws_iam_role.obs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "obs_node" {
  name_prefix = "obs-node-profile"
  role        = aws_iam_role.obs_node_role.name
}

resource "aws_security_group" "obs_sg" {
  name        = "${var.project_name}-observability-sg"
  description = "Allows Grafana and Prometheus inbound"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Can restrict to specific IP in prod
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "observability" {
  ami           = data.aws_ssm_parameter.amazon_linux.value
  instance_type = "t3.micro"
  subnet_id     = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.obs_sg.id]
  associate_public_ip_address = true
  iam_instance_profile = aws_iam_instance_profile.obs_node.name

  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo amazon-linux-extras install docker -y
    sudo service docker start
    sudo systemctl enable docker
    sudo usermod -a -G docker ec2-user
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    mkdir -p /home/ec2-user/sre-stack/prometheus /home/ec2-user/sre-stack/grafana/provisioning/dashboards /home/ec2-user/sre-stack/grafana/provisioning/datasources
    cd /home/ec2-user/sre-stack

    # Prom Config
    cat << 'YML' > prometheus/prometheus.yml
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: "prometheus"
        static_configs:
          - targets: ["localhost:9090"]
      - job_name: "ecs_nodes"
        ec2_sd_configs:
          - region: us-east-1
            port: 9100
            filters:
              - name: "tag:AmazonECSManaged"
                values: ["true"]
    YML

    # Grafana Prov
    cat << 'YML' > grafana/provisioning/datasources/prometheus.yml
    apiVersion: 1
    datasources: [{ name: Prometheus, type: prometheus, url: 'http://prometheus:9090', isDefault: true }]
    YML

    cat << 'YML' > grafana/provisioning/dashboards/dashboards.yml
    apiVersion: 1
    providers: [{ name: 'default', orgId: 1, folder: '', type: file, options: { path: /etc/grafana/provisioning/dashboards } }]
    YML

    # Dashboard JSON
    cat << 'YML' > grafana/provisioning/dashboards/dash.json
    {"annotations":{"list":[]},"editable":true,"panels":[{"datasource":"Prometheus","gridPos":{"h":8,"w":12,"x":0,"y":0},"id":2,"targets":[{"expr":"100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)","refId":"A"}],"title":"CPU Usage (%)","type":"timeseries"},{"datasource":"Prometheus","gridPos":{"h":8,"w":12,"x":12,"y":0},"id":3,"targets":[{"expr":"sum(changes(process_start_time_seconds[1h]))","refId":"A"}],"title":"Container Restarts (Last 1hr)","type":"timeseries"},{"datasource":"Prometheus","gridPos":{"h":8,"w":12,"x":0,"y":8},"id":4,"targets":[{"expr":"100 * (1 - ((node_memory_MemAvailable_bytes) / (node_memory_MemTotal_bytes)))","refId":"A"}],"title":"Memory Usage (%)","type":"timeseries"},{"datasource":"Prometheus","gridPos":{"h":8,"w":12,"x":12,"y":8},"id":5,"targets":[{"expr":"100 - ((node_filesystem_avail_bytes{mountpoint=\"/\"} / node_filesystem_size_bytes{mountpoint=\"/\"}) * 100)","refId":"A"}],"title":"Disk Usage (%)","type":"timeseries"}],"schemaVersion":38,"title":"SRE Dashboard"}
    YML

    # Fix Permissions
    sudo chmod -R 777 /home/ec2-user/sre-stack

    # Native Docker Deployment
    sudo docker network create sre_network
    
    sudo docker run -d --name prometheus --network sre_network \
      -p 9090:9090 \
      -v /home/ec2-user/sre-stack/prometheus:/etc/prometheus \
      prom/prometheus:latest \
      --config.file=/etc/prometheus/prometheus.yml

    sudo docker run -d --name grafana --network sre_network \
      -p 3000:3000 \
      -v /home/ec2-user/sre-stack/grafana/provisioning:/etc/grafana/provisioning \
      -e GF_SECURITY_ADMIN_USER=admin \
      -e GF_SECURITY_ADMIN_PASSWORD=admin \
      grafana/grafana:latest
  EOF

  tags = {
    Name = "${var.project_name}-observability"
  }
}

output "observability_ip" {
  value = aws_instance.observability.public_ip
}

