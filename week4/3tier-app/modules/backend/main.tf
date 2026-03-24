# 1. Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 2. Deploy the Backend EC2 Instance
resource "aws_instance" "flask_backend" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro" # Free-tier eligible / low cost
  key_name                    = "xgrid-intern-key"
  subnet_id              = var.private_app_subnet_ids[0] # Place in the first private app subnet
  vpc_security_group_ids = [var.backend_sg_id]
  iam_instance_profile   = var.iam_instance_profile_name

  # User data script to install Docker and run your Flask app
  user_data = <<-EOF
              #!/bin/bash
              # Update packages and install Docker
              dnf update -y
              dnf install -y docker
              
              # Start and enable Docker service
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # Create a directory for the app
              mkdir -p /home/ec2-user/app
              cd /home/ec2-user/app

              # NOTE: In a real scenario, you would pull your Docker image from ECR or DockerHub here.
              # Example command to run your container, passing the DB connection details:
              # docker run -d -p 5000:5000 \
              #   -e DB_HOST=${var.db_endpoint} \
              #   -e DB_NAME=${var.db_name} \
              #   -e DB_PORT=5432 \
              #   --name flask_backend your-dockerhub-username/flask-app:latest
              EOF

  tags = {
    Name = "${var.vpc_name}-flask-backend"
  }
}
