#!/bin/bash

# 設定錯誤處理
set -e

# 記錄開始時間
echo "User Data script started at $(date)" >> /var/log/user-data.log

# 建立應用程式環境變數檔案
cat > /opt/csye6225/.env << 'EOF'
# Database Configuration
DB_HOST=${db_host}
DB_PORT=${db_port}
DB_NAME=${db_name}
DB_USER=${db_user}
DB_PASSWORD=${db_password}

# S3 Configuration
S3_BUCKET=${s3_bucket}
AWS_REGION=${aws_region}

# Application Configuration
SPRING_PROFILES_ACTIVE=prod
EOF

# 設定檔案權限
chown csye6225:csye6225 /opt/csye6225/.env
chmod 600 /opt/csye6225/.env

# 記錄環境變數已設定（不記錄敏感資訊）
echo "Environment variables configured" >> /var/log/user-data.log
echo "DB_HOST=${db_host}" >> /var/log/user-data.log
echo "S3_BUCKET=${s3_bucket}" >> /var/log/user-data.log

# 重新載入 systemd 並重啟應用程式
systemctl daemon-reload
systemctl enable csye6225.service
systemctl restart csye6225.service

# 等待服務啟動
sleep 5

# 檢查服務狀態
if systemctl is-active --quiet csye6225.service; then
    echo "Application service started successfully" >> /var/log/user-data.log
else
    echo "Application service failed to start" >> /var/log/user-data.log
    systemctl status csye6225.service >> /var/log/user-data.log 2>&1
fi

# 記錄完成時間
echo "User Data script completed at $(date)" >> /var/log/user-data.log