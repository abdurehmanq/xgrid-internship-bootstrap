# IAM Role for WordPress EC2 instances
# Grants access to Secrets Manager (for RDS password) and SSM Session Manager (SSH replacement)

resource "aws_iam_role" "ec2_role" {
  name = "wp-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "wp-ec2-role" }
}

# Allows SSM Session Manager (free, replaces SSH bastion host need)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allows EC2 to fetch the RDS managed password from Secrets Manager
resource "aws_iam_role_policy" "secrets_manager" {
  name = "wp-secretsmanager-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = var.db_secret_arn
    }]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "wp-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}
