variable "vpc_id" {}
variable "private_subnet_ids" { type = list(string) }
variable "target_group_arn" {}
variable "ecs_sg_id" {}
variable "db_endpoint" {}
variable "db_secret_arn" {}
variable "project_name" {}
variable "efs_id" {}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"
}

# CloudWatch Log Group for Application Logs
resource "aws_cloudwatch_log_group" "wp_logs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7
}

# IAM Role for EC2 Instances to join ECS
data "aws_iam_policy_document" "ecs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_node_role" {
  name_prefix        = "ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = "ecs-node-profile"
  role        = aws_iam_role.ecs_node_role.name
}

# ECS Task Execution Role for Secrets Manager access
data "aws_iam_policy_document" "ecs_execution_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution_role" {
  name_prefix        = "ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution_basic" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_execution_secrets" {
  name = "${var.project_name}-secrets-policy"
  role = aws_iam_role.ecs_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [var.db_secret_arn]
      }
    ]
  })
}

# ECS Optimized AMI
data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# EC2 Launch Template
resource "aws_launch_template" "ecs_node" {
  name_prefix   = "${var.project_name}-ecs-"
  image_id      = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type = "t3.micro" # Strictly aligning with AWS Free Tier constraints

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_node.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.ecs_sg_id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOF
  )
}

# Auto Scaling Group for ECS Nodes
resource "aws_autoscaling_group" "ecs_nodes" {
  vpc_zone_identifier = var.private_subnet_ids
  desired_capacity    = 2
  max_size            = 2
  min_size            = 1

  launch_template {
    id      = aws_launch_template.ecs_node.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
  tag {
    key                 = "Name"
    value               = "${var.project_name}-ecs-node"
    propagate_at_launch = true
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "ecs_nodes" {
  name = "${var.project_name}-cas"
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_nodes.arn
    managed_scaling {
      maximum_scaling_step_size = 2
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_nodes.name]
}

# WordPress Task Definition
resource "aws_ecs_task_definition" "wp" {
  family                   = "${var.project_name}-wp-task"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "512"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "wordpress"
    image     = "wordpress:latest"
    cpu       = 512
    memory    = 512
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 0 # Dynamic port mapping for ALB
    }]
    mountPoints = [
      { sourceVolume = "wp_data", containerPath = "/var/www/html/wp-content" }
    ]
    environment = [
      { name = "WORDPRESS_DB_HOST", value = var.db_endpoint },
      { name = "WORDPRESS_DB_USER", value = "admin" },
      { name = "WORDPRESS_DB_NAME", value = "wordpressdb" },
      { name = "WORDPRESS_CONFIG_EXTRA", value = "define('WP_HOME', 'http://' . $_SERVER['HTTP_HOST'] . '/'); define('WP_SITEURL', 'http://' . $_SERVER['HTTP_HOST'] . '/');" }
    ]
    secrets = [
      { name = "WORDPRESS_DB_PASSWORD", valueFrom = var.db_secret_arn }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.wp_logs.name
        awslogs-region        = "us-east-1"
        awslogs-stream-prefix = "wordpress"
      }
    }
  }])

  volume {
    name = "wp_data"

    efs_volume_configuration {
      file_system_id     = var.efs_id
      transit_encryption = "ENABLED"
    }
  }
}

# ECS Service
resource "aws_ecs_service" "wp_service" {
  name            = "${var.project_name}-wp-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.wp.arn
  desired_count   = 2

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_nodes.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "wordpress"
    container_port   = 80
  }
}

# Autoscaling for the ECS Service based on CPU
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 2
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.wp_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Node Exporter Daemon Service
resource "aws_ecs_task_definition" "node_exporter" {
  family                   = "${var.project_name}-node-exporter"
  network_mode             = "host"
  requires_compatibilities = ["EC2"]
  cpu                      = 128
  memory                   = 128

  container_definitions = jsonencode([{
    name      = "node-exporter"
    image     = "prom/node-exporter:latest"
    cpu       = 128
    memory    = 128
    essential = true
    portMappings = [{
      containerPort = 9100
      hostPort      = 9100
    }]
    mountPoints = [
      { sourceVolume = "proc", containerPath = "/host/proc", readOnly = true },
      { sourceVolume = "sys", containerPath = "/host/sys", readOnly = true },
      { sourceVolume = "root", containerPath = "/rootfs", readOnly = true }
    ]
    command = [
      "--path.procfs=/host/proc",
      "--path.sysfs=/host/sys",
      "--path.rootfs=/rootfs",
      "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)"
    ]
  }])

  volume {
    name      = "proc"
    host_path = "/proc"
  }
  volume {
    name      = "sys"
    host_path = "/sys"
  }
  volume {
    name      = "root"
    host_path = "/"
  }
}

resource "aws_ecs_service" "node_exporter" {
  name                = "${var.project_name}-node-exporter"
  cluster             = aws_ecs_cluster.main.id
  task_definition     = aws_ecs_task_definition.node_exporter.arn
  scheduling_strategy = "DAEMON"
}

