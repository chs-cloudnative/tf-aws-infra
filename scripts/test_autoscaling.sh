#!/bin/bash
set -e

# ===================================================================
# Auto Scaling Test Script - Product Service
# ===================================================================
# Purpose: Test auto scaling behavior under load
# Expected: Scale 3 → 5 → 3 instances (~20 minutes)
# ===================================================================

# ===================================================================
# Configuration - Auto-detected from Terraform
# ===================================================================
DOMAIN=$(terraform output -raw application_url | sed 's|http://||')
ASG=$(terraform output -raw autoscaling_group_name)
TG=$(terraform output -raw target_group_arn)
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
# Display Configuration
# ===================================================================
echo -e "${C}========== Configuration ==========${N}"
echo "Domain:  ${DOMAIN}"
echo "ASG:     ${ASG}"
echo "TG:      ${TG}"
echo "Profile: ${P}"
echo ""

# ===================================================================
# Step 1: Infrastructure Deployment and Health Verification
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
            terraform apply -replace="module.compute.aws_lb.webapp" -replace="module.compute.aws_lb_listener.http" -auto-approve > /dev/null 2>&1
            sleep 120
        fi
        sleep 10
    }
done

# ===================================================================
# Display Current Infrastructure
# ===================================================================
echo ""

# Display CloudWatch alarms (auto-detect alarm names)
ALARM_HIGH="product-service-${P}-cpu-high"
ALARM_LOW="product-service-${P}-cpu-low"

aws cloudwatch describe-alarms \
    --alarm-names ${ALARM_HIGH} ${ALARM_LOW} \
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