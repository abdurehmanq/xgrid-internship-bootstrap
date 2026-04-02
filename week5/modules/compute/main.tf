# Shared EFS Storage
resource "aws_efs_file_system" "wp_efs" {
  creation_token = "wp-shared-storage"
  tags = { Name = "wp-efs" }
}

resource "aws_efs_mount_target" "efs_mt" {
  count           = length(var.private_subnet_ids)
  file_system_id  = aws_efs_file_system.wp_efs.id
  subnet_id       = var.private_subnet_ids[count.index]
  security_groups = [var.efs_sg_id]
}

# Application Load Balancer
resource "aws_lb" "wp_alb" {
  name               = "wp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "wp_tg" {
  name     = "wp-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    path                = "/wp-login.php"
    healthy_threshold   = 2
    unhealthy_threshold = 5
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.wp_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wp_tg.arn
  }
}

# Launch Template & Auto Scaling Group
resource "aws_launch_template" "wp_lt" {
  name_prefix   = "wp-template-"
  image_id      = "ami-0ebfd941bbafe70c6" # Amazon Linux 2023 in us-east-1
  instance_type = "t3.micro"
  vpc_security_group_ids = [var.ec2_sg_id]

  iam_instance_profile {
    name = var.instance_profile_name
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    efs_id        = aws_efs_file_system.wp_efs.id
    db_endpoint   = var.db_endpoint
    db_name       = var.db_name
    db_username   = var.db_username
    db_secret_arn = var.db_secret_arn
  }))
}

resource "aws_autoscaling_group" "wp_asg" {
  name                = "wp-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.wp_tg.arn]
  min_size            = 1
  max_size            = 4
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.wp_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "wp-asg-instance"
    propagate_at_launch = true
  }
}

# CPU-based target tracking policy — scales out when avg CPU > 40%, scales in when CPU drops
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "wp-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.wp_asg.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 40.0
  }
}