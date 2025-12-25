#!/bin/bash
# =================================================================================
# EC2 User Data Script - Application Initialization
# =================================================================================
# Purpose: Configure and start application on EC2 instance launch
# Execution: Automatically run by cloud-init on first boot

set -e

# =================================================================================
# Logging Setup
# =================================================================================

LOG_FILE="/var/log/user-data.log"

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

log_message "User Data script started"

# =================================================================================
# Retrieve Database Password from Secrets Manager
# =================================================================================

log_message "Retrieving database password from Secrets Manager"

DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id ${db_password_secret_arn} \
  --region ${aws_region} \
  --query SecretString \
  --output text)

if [ -z "$DB_PASSWORD" ]; then
    log_message "ERROR: Failed to retrieve database password"
    exit 1
fi

log_message "Database password retrieved successfully"

# =================================================================================
# Create Application Environment File
# =================================================================================

log_message "Creating application environment file"

cat > /opt/productservice/.env << EOF
# Database Configuration
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=$DB_PASSWORD

# S3 Configuration
S3_BUCKET=${s3_bucket}
AWS_REGION=${aws_region}

# SNS Configuration
SNS_TOPIC_ARN=${sns_topic_arn}

# Application Configuration
SPRING_PROFILES_ACTIVE=prod
EOF

# Set file permissions
chown productservice:productservice /opt/productservice/.env
chmod 600 /opt/productservice/.env

log_message "Environment file created and configured"
log_message "DB_HOST=${db_host}"
log_message "DB_PASSWORD retrieved from Secrets Manager"
log_message "S3_BUCKET=${s3_bucket}"
log_message "SNS_TOPIC_ARN configured"

# =================================================================================
# Start Application Service
# =================================================================================

log_message "Starting application service"

# Reload systemd daemon
systemctl daemon-reload

# Enable service to start on boot
systemctl enable productservice.service

# Start the service
systemctl restart productservice.service

# Wait for service to initialize
sleep 5

# Verify service status
if systemctl is-active --quiet productservice.service; then
    log_message "Application service started successfully"
else
    log_message "ERROR: Application service failed to start"
    systemctl status productservice.service >> $LOG_FILE 2>&1
fi

# =================================================================================
# Configure and Start CloudWatch Agent
# =================================================================================

log_message "Configuring CloudWatch Agent"

# Create logs directory if not exists
mkdir -p /opt/productservice/logs
chown productservice:productservice /opt/productservice/logs
chmod 755 /opt/productservice/logs

# Start CloudWatch Agent with configuration
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json

# Wait for agent to initialize
sleep 3

# Verify CloudWatch Agent status
if /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a query \
  -m ec2 \
  -c default | grep -q "running"; then
    log_message "CloudWatch Agent started successfully"
else
    log_message "WARNING: CloudWatch Agent may not be running properly"
fi

# =================================================================================
# Script Completion
# =================================================================================

log_message "User Data script completed successfully"