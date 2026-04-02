#!/bin/bash
# Update and install dependencies
yum update -y
yum install -y httpd php php-mysqlnd mariadb105 amazon-efs-utils wget tar jq

# Start Apache
systemctl start httpd
systemctl enable httpd

# Mount EFS to the html directory
mkdir -p /var/www/html
mount -t efs -o tls ${efs_id}:/ /var/www/html

# Fetch database password from AWS Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id "${db_secret_arn}" \
  --query 'SecretString' \
  --output text | jq -r '.password')

# Check if WordPress is already installed
if [ ! -f /var/www/html/wp-config.php ]; then
  cd /tmp
  wget https://wordpress.org/latest.tar.gz
  tar -xzf latest.tar.gz
  cp -r wordpress/* /var/www/html/

  # Configure WordPress Database Connection
  cd /var/www/html
  cp wp-config-sample.php wp-config.php
  sed -i "s/database_name_here/${db_name}/g" wp-config.php
  sed -i "s/username_here/${db_username}/g" wp-config.php
  sed -i "s/password_here/$DB_PASSWORD/g" wp-config.php

  DB_HOST=$(echo ${db_endpoint} | cut -f1 -d":")
  sed -i "s/localhost/$DB_HOST/g" wp-config.php
fi

chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html