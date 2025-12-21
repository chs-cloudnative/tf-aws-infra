#!/bin/bash
set -e

# ===================================================================
# Configuration
# ===================================================================
DOMAIN="dev.chs4150.me"
ASG="csye6225-vpc-webapp-asg"
TG="arn:aws:elasticloadbalancing:us-east-1:979067962645:targetgroup/csye6225-vpc-webapp-tg/263f46f09541ce6c"
P="dev"

# ===================================================================
# Color Definitions
# ===================================================================
G='\033[0;32m'  # Green
Y='\033[1;33m'  # Yellow
R='\033[0;31m'  # Red
B='\033[0;34m'  # Blue
C='\033[0;36m'  # Cyan
N='\033[0m'     # No Color

# ===================================================================
# System Setup
# ===================================================================
ulimit -n 2048 2>/dev/null || true
clear

# ===================================================================
# Step 1: Infrastructure Deployment and Health Verification
# 部署 Terraform 基礎設施並驗證 ALB 和應用程式的健康狀態
# ===================================================================
echo -e "${B}[1/6] Apply & Health Check${N}"

# Apply Terraform configuration
terraform apply -auto-approve > /dev/null 2>&1
sleep 30

# Auto-fix ALB if health check fails
for i in {1..3}; do
    curl -s -m 5 http://${DOMAIN}/health > /dev/null 2>&1 && {
        echo -e "${G}✓ ALB OK${N}"
        break
    } || {
        echo "⚠ ALB down (attempt $i/3)"
        if [ $i -eq 3 ]; then
            terraform apply -replace="aws_lb.webapp" -replace="aws_lb_listener.http" -auto-approve > /dev/null 2>&1
            sleep 120
        fi
        sleep 10
    }
done

# ===================================================================
# Display Current Infrastructure Information
# 顯示當前環境配置、CloudWatch 警報狀態、運行中的實例和目標組健康狀況
# ===================================================================
echo -e "\n${C}========== Configuration ==========${N}"
echo "Domain:  ${DOMAIN}"
echo "ALB:     $(terraform output -raw load_balancer_dns 2>/dev/null)"
echo "ASG:     ${ASG}"
echo ""

# Display CloudWatch alarms
aws cloudwatch describe-alarms \
    --alarm-names csye6225-vpc-cpu-high csye6225-vpc-cpu-low \
    --profile ${P} \
    --query 'MetricAlarms[*].[AlarmName,Threshold,StateValue]' \
    --output table \
    2>/dev/null

# Display running instances
echo -e "\n${C}Instances ($(aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=${ASG}" "Name=instance-state-name,Values=running" --query 'length(Reservations[*].Instances[*])' --output text --profile ${P})):${N}"
aws ec2 describe-instances \
    --filters "Name=tag:aws:autoscaling:groupName,Values=${ASG}" "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]' \
    --output table \
    --profile ${P}

# Display target group health
echo -e "\n${C}Targets:${N}"
aws elbv2 describe-target-health \
    --target-group-arn ${TG} \
    --profile ${P} \
    --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
    --output table

# Display test information
echo -e "\n${C}Test: ab -r -k -n 900000 -c 200${N}"
echo -e "${C}Expected: 3 → 5 → 3 (~20min)${N}\n"
sleep 3

# ===================================================================
# Step 2: Baseline Verification
# 驗證初始狀態確保 ASG 有正確的 3 個運行實例作為測試基準
# ===================================================================
echo -e "${B}[2/6] Baseline Check${N}"

I=$(aws ec2 describe-instances \
    --filters "Name=tag:aws:autoscaling:groupName,Values=${ASG}" "Name=instance-state-name,Values=running" \
    --query 'length(Reservations[*].Instances[*])' \
    --output text \
    --profile ${P})

if [ "$I" -ne 3 ]; then
    echo -e "${R}✗ Found $I, need 3${N}"
    exit 1
else
    echo -e "${G}✓ 3 instances${N}"
fi

# ===================================================================
# Step 3: Load Testing and CPU Monitoring
# 執行 Apache Bench 負載測試並持續監控 CPU 使用率以觸發 Scale Up
# ===================================================================
echo -e "\n${B}[3/6] Load Test${N}"

# Start load test in background
ab -r -k -n 900000 -c 200 http://${DOMAIN}/health > /tmp/ab.txt 2>&1 &
PID=$!

# Monitor CPU utilization during load test
for i in {1..10}; do
    sleep 20
    
    CPU=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/EC2 \
        --metric-name CPUUtilization \
        --dimensions Name=AutoScalingGroupName,Value=${ASG} \
        --start-time $(date -u -v-5M +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 60 \
        --statistics Average \
        --profile ${P} \
        --query 'Datapoints|sort_by(@,&Timestamp)|[-1].Average' \
        --output text \
        2>/dev/null)
    
    C=${CPU:-0}
    printf "[%s] %d/10: CPU=%.2f%%" "$(date +%H:%M:%S)" "$i" "$C"
    
    if (( $(echo "$C>12"|bc -l 2>/dev/null||echo 0) )); then
        echo -e " ${R}(>12%)${N}"
    else
        echo -e " ${G}(<12%)${N}"
    fi
done

# Stop load test
kill $PID 2>/dev/null || true
wait $PID 2>/dev/null || true
echo -e "${G}✓ Done${N}"

# ===================================================================
# Step 4: Scale Up Verification
# 監控並驗證 ASG 是否成功擴展到 5 個實例以應對高負載
# ===================================================================
echo -e "\n${B}[4/6] Scale Up${N}"

P_CNT=$I

for i in {1..15}; do
    CNT=$(aws ec2 describe-instances \
        --filters "Name=tag:aws:autoscaling:groupName,Values=${ASG}" "Name=instance-state-name,Values=running,pending" \
        --query 'length(Reservations[*].Instances[*])' \
        --output text \
        --profile ${P})
    
    echo "[$(date +%H:%M:%S)] $i/15: ${CNT} instances"
    
    if [ "$CNT" -ge 5 ]; then
        echo -e "${G}✓ Scale Up!${N}"
        P_CNT=$CNT
        break
    fi
    
    P_CNT=$CNT
    sleep 20
done

# ===================================================================
# Step 5: Scale Down Verification
# 監控 CPU 降低後 ASG 是否成功縮減回 3 個實例
# ===================================================================
echo -e "\n${B}[5/6] Scale Down${N}"

F_CNT=$P_CNT

for i in {1..15}; do
    CNT=$(aws ec2 describe-instances \
        --filters "Name=tag:aws:autoscaling:groupName,Values=${ASG}" "Name=instance-state-name,Values=running" \
        --query 'length(Reservations[*].Instances[*])' \
        --output text \
        --profile ${P})
    
    CPU=$(aws cloudwatch get-metric-statistics \
        --namespace AWS/EC2 \
        --metric-name CPUUtilization \
        --dimensions Name=AutoScalingGroupName,Value=${ASG} \
        --start-time $(date -u -v-5M +%Y-%m-%dT%H:%M:%S) \
        --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
        --period 60 \
        --statistics Average \
        --profile ${P} \
        --query 'Datapoints|sort_by(@,&Timestamp)|[-1].Average' \
        --output text \
        2>/dev/null)
    
    C=${CPU:-0}
    printf "[%s] %d/15: Inst=%d, CPU=%.2f%%" "$(date +%H:%M:%S)" "$i" "$CNT" "$C"
    
    if (( $(echo "$C<8"|bc -l 2>/dev/null||echo 0) )); then
        echo -e " ${G}(<8%)${N}"
    else
        echo -e " ${R}(>8%)${N}"
    fi
    
    if [ "$CNT" -le 3 ]; then
        echo -e "${G}✓ Scale Down!${N}"
        F_CNT=$CNT
        break
    fi
    
    F_CNT=$CNT
    sleep 40
done

# ===================================================================
# Step 6: Test Report and Summary
# 生成完整測試報告包含擴展統計、ASG 活動記錄和最終結果評估
# ===================================================================
echo -e "\n${C}========== REPORT ==========${N}"
echo "Initial: $I | Peak: $P_CNT | Final: $F_CNT"

# Evaluate scale up result
if [ "$P_CNT" -gt "$I" ]; then
    echo -e "${G}✓ Scale Up: +$((P_CNT-I))${N}"
else
    echo -e "${R}✗ Scale Up failed${N}"
fi

# Evaluate scale down result
if [ "$F_CNT" -le "$I" ]; then
    echo -e "${G}✓ Scale Down: -$((P_CNT-F_CNT))${N}"
else
    echo -e "${Y}⚠ Scale Down incomplete${N}"
fi

# Display recent ASG activities
echo -e "\n${C}ASG Activities:${N}"
aws autoscaling describe-scaling-activities \
    --auto-scaling-group-name ${ASG} \
    --max-records 5 \
    --profile ${P} \
    --query 'Activities[*].[StartTime,Description,StatusCode]' \
    --output table

# Display final target group health
echo -e "\n${C}Targets:${N}"
aws elbv2 describe-target-health \
    --target-group-arn ${TG} \
    --profile ${P} \
    --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' \
    --output table

# Display final result
if [ "$P_CNT" -gt "$I" ] && [ "$F_CNT" -le 3 ]; then
    echo -e "\n${G}★★★ SUCCESS ★★★${N}\n"
else
    echo -e "\n${Y}⚠ PARTIAL${N}\n"
fi