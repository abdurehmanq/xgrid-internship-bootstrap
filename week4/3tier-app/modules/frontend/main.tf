# 1. Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 2. Deploy the Frontend EC2 Instance
resource "aws_instance" "react_frontend" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro" # Free-tier eligible
  key_name                    = "xgrid-intern-key"
  iam_instance_profile        = "cl-01-backend-profile"
  subnet_id                   = var.public_subnet_ids[0] # Place in the first public subnet
  vpc_security_group_ids      = [var.frontend_sg_id]
  associate_public_ip_address = true # Ensure it gets a public IP

  # User data script to install Docker, configure Nginx, and run the container
  user_data = <<-EOF
              #!/bin/bash
              # Update packages and install Docker
              dnf update -y
              dnf install -y docker
              
              # Start and enable Docker service
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user

              # Create app directory and Nginx config
              mkdir -p /home/ec2-user/app
              cd /home/ec2-user/app

              cat << 'EONX' > default.conf
              server {
                  listen 80;
                  
                  # Serve React static files (Assuming they are copied to /usr/share/nginx/html in your Docker image)
                  location / {
                      root /usr/share/nginx/html;
                      index index.html index.htm;
                      try_files $uri $uri/ /index.html;
                  }

                  # Reverse proxy API requests to the private Flask backend
                  location /api/ {
                      proxy_pass http://${var.backend_private_ip}:5000/;
                      proxy_set_header Host $host;
                      proxy_set_header X-Real-IP $remote_addr;
                  }
              }
              EONX

              # NOTE: In reality, you would pull your custom React+Nginx image here.
              # Example running an Nginx container and mounting the config we just created:
              # docker run -d -p 80:80 \
              #   -v /home/ec2-user/app/default.conf:/etc/nginx/conf.d/default.conf:ro \
              #   --name react_frontend your-dockerhub-username/react-app:latest
              EOF

  tags = {
    Name = "${var.vpc_name}-react-frontend"
  }
}
