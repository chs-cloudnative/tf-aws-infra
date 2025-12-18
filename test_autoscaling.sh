#!/bin/bash
set -e

# Config
DOMAIN="dev.chs4150.me"
ASG="csye6225-vpc-webapp-asg"
TG="arn:aws:elasticloadbalancing:us-east-1:979067962645:targetgroup/csye6225-vpc-webapp-tg/263f46f09541ce6c"
P="dev"

# Colors
G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; C='\033[0;36m'; N='\033[0m'

ulimit -n 2048 2>/dev/null || true
clear

# ===================================================================
# Step 1: Apply & Health Check
# ===================================================================
echo -e "${B}[1/6] Apply & Health Check${N}"
terraform apply -auto-approve > /dev/null 2>&1
sleep 30

# Auto-fix if ALB broken
for i in {1..3}; do
    curl -s -m 5 http://${DOMAIN}/health > /dev/null 2>&1 && { echo -e "${G}✓ ALB OK${N}"; break; } || {
        echo "⚠ ALB down (attempt $i/3)"
        [ $i -eq 3 ] && { terraform apply -replace="aws_lb.webapp" -replace="aws_lb_listener.http" -auto-approve > /dev/null 2>&1; sleep 120; }
        sleep 10
    }
done

# ===================================================================
# Display Info
# ===================================================================
echo -e "\n${C}========== Configuration ==========${N}"
echo "Domain:  ${DOMAIN}"
echo "ALB:     $(terraform output -raw load_balancer_dns 2>/dev/null)"
echo "ASG:     ${ASG}"
echo ""

aws cloudwatch describe-alarms --alarm-names csye6225-vpc-cpu-high csye6225-vpc-cpu-low --profile ${P} --query 'MetricAlarms[*].[AlarmName,Threshold,StateValue]' --output table 2>/dev/null

echo -e "\n${C}Instances ($(aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=${ASG}" "Name=instance-state-name,Values=running" --query 'length(Reservations[*].Instances[*])' --output text --profile ${P})):${N}"
aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=${ASG}" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[InstanceId,PublicIpAddress]' --output table --profile ${P}

echo -e "\n${C}Targets:${N}"
aws elbv2 describe-target-health --target-group-arn ${TG} --profile ${P} --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' --output table

echo -e "\n${C}Test: ab -r -k -n 900000 -c 200${N}"
echo -e "${C}Expected: 3 → 5 → 3 (~20min)${N}\n"
sleep 3

# ===================================================================
# Step 2: Baseline
# ===================================================================
echo -e "${B}[2/6] Baseline Check${N}"
I=$(aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=${ASG}" "Name=instance-state-name,Values=running" --query 'length(Reservations[*].Instances[*])' --output text --profile ${P})
[ "$I" -ne 3 ] && { echo -e "${R}✗ Found $I, need 3${N}"; exit 1; } || echo -e "${G}✓ 3 instances${N}"

# ===================================================================
# Step 3: Load Test
# ===================================================================
echo -e "\n${B}[3/6] Load Test${N}"
ab -r -k -n 900000 -c 200 http://${DOMAIN}/health > /tmp/ab.txt 2>&1 &
PID=$!

for i in {1..10}; do
    sleep 20
    CPU=$(aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=AutoScalingGroupName,Value=${ASG} --start-time $(date -u -v-5M +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 60 --statistics Average --profile ${P} --query 'Datapoints|sort_by(@,&Timestamp)|[-1].Average' --output text 2>/dev/null)
    C=${CPU:-0}
    printf "[%s] %d/10: CPU=%.2f%%" "$(date +%H:%M:%S)" "$i" "$C"
    (( $(echo "$C>12"|bc -l 2>/dev/null||echo 0) )) && echo -e " ${R}(>12%)${N}" || echo -e " ${G}(<12%)${N}"
done

kill $PID 2>/dev/null || true; wait $PID 2>/dev/null || true
echo -e "${G}✓ Done${N}"

# ===================================================================
# Step 4: Scale Up
# ===================================================================
echo -e "\n${B}[4/6] Scale Up${N}"
P_CNT=$I

for i in {1..15}; do
    CNT=$(aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=${ASG}" "Name=instance-state-name,Values=running,pending" --query 'length(Reservations[*].Instances[*])' --output text --profile ${P})
    echo "[$(date +%H:%M:%S)] $i/15: ${CNT} instances"
    [ "$CNT" -ge 5 ] && { echo -e "${G}✓ Scale Up!${N}"; P_CNT=$CNT; break; }
    P_CNT=$CNT; sleep 20
done

# ===================================================================
# Step 5: Scale Down
# ===================================================================
echo -e "\n${B}[5/6] Scale Down${N}"
F_CNT=$P_CNT

for i in {1..15}; do
    CNT=$(aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=${ASG}" "Name=instance-state-name,Values=running" --query 'length(Reservations[*].Instances[*])' --output text --profile ${P})
    CPU=$(aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --dimensions Name=AutoScalingGroupName,Value=${ASG} --start-time $(date -u -v-5M +%Y-%m-%dT%H:%M:%S) --end-time $(date -u +%Y-%m-%dT%H:%M:%S) --period 60 --statistics Average --profile ${P} --query 'Datapoints|sort_by(@,&Timestamp)|[-1].Average' --output text 2>/dev/null)
    C=${CPU:-0}
    printf "[%s] %d/15: Inst=%d, CPU=%.2f%%" "$(date +%H:%M:%S)" "$i" "$CNT" "$C"
    (( $(echo "$C<8"|bc -l 2>/dev/null||echo 0) )) && echo -e " ${G}(<8%)${N}" || echo -e " ${R}(>8%)${N}"
    
    [ "$CNT" -le 3 ] && { echo -e "${G}✓ Scale Down!${N}"; F_CNT=$CNT; break; }
    F_CNT=$CNT; sleep 40
done

# ===================================================================
# Step 6: Report
# ===================================================================
echo -e "\n${C}========== REPORT ==========${N}"
echo "Initial: $I | Peak: $P_CNT | Final: $F_CNT"
[ "$P_CNT" -gt "$I" ] && echo -e "${G}✓ Scale Up: +$((P_CNT-I))${N}" || echo -e "${R}✗ Scale Up failed${N}"
[ "$F_CNT" -le "$I" ] && echo -e "${G}✓ Scale Down: -$((P_CNT-F_CNT))${N}" || echo -e "${Y}⚠ Scale Down incomplete${N}"

echo -e "\n${C}ASG Activities:${N}"
aws autoscaling describe-scaling-activities --auto-scaling-group-name ${ASG} --max-records 5 --profile ${P} --query 'Activities[*].[StartTime,Description,StatusCode]' --output table

echo -e "\n${C}Targets:${N}"
aws elbv2 describe-target-health --target-group-arn ${TG} --profile ${P} --query 'TargetHealthDescriptions[*].[Target.Id,TargetHealth.State]' --output table

[ "$P_CNT" -gt "$I" ] && [ "$F_CNT" -le 3 ] && echo -e "\n${G}★★★ SUCCESS ★★★${N}\n" || echo -e "\n${Y}⚠ PARTIAL${N}\n"
```
