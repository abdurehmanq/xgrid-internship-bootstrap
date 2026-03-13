# ------------------------------------------------------------------------------
# 1. IAM Permissions: Let our EC2 instance talk to the ECS Control Plane
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "ecs_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_node_role" {
  name               = "ecs-node-role-week3"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_node_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}


resource "aws_iam_role_policy_attachment" "ssm_core_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_instance_profile" "ecs_node_profile" {
  name = "ecs-node-profile-week3"
  role = aws_iam_role.ecs_node_role.name
}


# ------------------------------------------------------------------------------
# 2. ECS Cluster
# ------------------------------------------------------------------------------
resource "aws_ecs_cluster" "main" {
  name = "wordpress-cluster"
}

# ------------------------------------------------------------------------------
# 3. Auto Scaling Group & Launch Template (The t2.micro EC2 Instance)
# ------------------------------------------------------------------------------
# Dynamically grabs the latest Amazon Linux 2 ECS-Optimized image
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

resource "aws_launch_template" "ecs_node" {
  name_prefix   = "ecs-node-"
  image_id      = data.aws_ssm_parameter.ecs_optimized_ami.value
  instance_type = "t3.micro" 

  iam_instance_profile { arn = aws_iam_instance_profile.ecs_node_profile.arn }
  vpc_security_group_ids = [var.ecs_sg_id]

  # This bash script runs when the EC2 starts, telling it to join our specific cluster
  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOF
  )
}

resource "aws_autoscaling_group" "ecs_asg" {
  vpc_zone_identifier = var.public_subnets
  desired_capacity    = 1 # Just 1 server for Free Tier
  max_size            = 2
  min_size            = 1

  launch_template {
    id      = aws_launch_template.ecs_node.id
    version = "$Latest"
  }
}

# ------------------------------------------------------------------------------
# 4. Task Definition: The Blueprint for WordPress & Database Containers
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "wordpress-app"
  network_mode             = "bridge" # Simplest network mode, links containers together
  requires_compatibilities = ["EC2"]

  # NEW: We define the local volume here. This tells the EC2 instance to 
  # set aside a folder on its EBS drive specifically for our database.
  volume {
    name      = "mariadb-persistent-storage"
    host_path = "/ecs/mariadb-data" 
  }

  container_definitions = jsonencode([
    {
      name      = "db"
      image     = "mariadb:10.5"
      cpu       = 256
      memory    = 256
      essential = true
      
      # NEW: We tell the MariaDB container to mount the volume we defined above
      # into the exact folder where MariaDB naturally saves its database files.
      mountPoints = [
        {
          sourceVolume  = "mariadb-persistent-storage"
          containerPath = "/var/lib/mysql"
        }
      ]
      
      environment = [
        { name = "MYSQL_ROOT_PASSWORD", value = "sre-super-secret" },
        { name = "MYSQL_DATABASE", value = "wordpress" },
        { name = "MYSQL_USER", value = "wp_user" },
        { name = "MYSQL_PASSWORD", value = "wp_pass" }
      ]
    },
    {
      name      = "wordpress"
      image     = "wordpress:latest"
      cpu       = 256
      memory    = 256
      essential = true
      links     = ["db"] # This lets WP talk to the DB container directly
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80 # Maps container port 80 directly to EC2's public IP
        }
      ]
      environment = [
        { name = "WORDPRESS_DB_HOST", value = "db" },
        { name = "WORDPRESS_DB_USER", value = "wp_user" },
        { name = "WORDPRESS_DB_PASSWORD", value = "wp_pass" },
        { name = "WORDPRESS_DB_NAME", value = "wordpress" }
      ]
    }
  ])
}

# ------------------------------------------------------------------------------
# 5. ECS Service: Runs the Task!
# ------------------------------------------------------------------------------
resource "aws_ecs_service" "wordpress_svc" {
  name            = "wordpress-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = 1 
  launch_type     = "EC2"
}