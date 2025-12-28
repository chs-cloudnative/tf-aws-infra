#!/bin/bash
# =================================================================================
# Route53 Name Server Verification Script
# =================================================================================
# Purpose:
#   Check if Route53 Name Servers need to be updated in domain registrar
#
# Usage:
#   ./scripts/check-nameservers.sh
#
# Workflow:
#   1. Retrieve current Name Servers from Terraform state
#   2. Query live Name Servers from DNS
#   3. Compare and determine if update is needed
#   4. Test DNS resolution and API health if NS are up to date
#
# Expected Output:
#   - ✅ NS are up to date → Test DNS and API
#   - ⚠️  NS have changed → Display update instructions
#   - ⚠️  No live NS found → First deployment instructions
#
# Notes:
#   - Run this after every terraform apply
#   - Name Servers change when Hosted Zone is recreated
#   - DNS propagation takes 15-30 minutes after NS update
# =================================================================================

# =================================================================================
# Configuration
# =================================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOMAIN="chs4150.me"

echo -e "${BLUE}🔍 Checking Route53 Name Servers...${NC}"
echo ""

# =================================================================================
# Step 1: Retrieve Terraform Name Servers
# =================================================================================

TERRAFORM_NS=$(terraform output -json root_name_servers 2>/dev/null | jq -r '.[]' | sort)

if [ -z "$TERRAFORM_NS" ]; then
    echo -e "${RED}❌ Error: Cannot get Name Servers from Terraform${NC}"
    echo "   Run 'terraform apply' first"
    exit 1
fi

# =================================================================================
# Step 2: Query Live Name Servers from DNS
# =================================================================================

LIVE_NS=$(dig +short NS $DOMAIN | sed 's/\.$//' | sort)

echo -e "${BLUE}📋 Current Terraform Name Servers:${NC}"
echo "$TERRAFORM_NS"
echo ""

if [ -z "$LIVE_NS" ]; then
    echo -e "${YELLOW}⚠️  No live Name Servers found for $DOMAIN${NC}"
    echo "   Root Zone Name Servers not configured in Namecheap yet"
    echo ""
    echo -e "${YELLOW}👉 ACTION REQUIRED (One-time):${NC}"
    echo "   Update ROOT Zone Name Servers in Namecheap:"
    echo "   https://ap.www.namecheap.com/domains/domaincontrolpanel/chs4150.me/domain"
    exit 0
fi

echo -e "${BLUE}📡 Live Name Servers (from DNS):${NC}"
echo "$LIVE_NS"
echo ""

# =================================================================================
# Step 3: Compare Name Servers
# =================================================================================

if [ "$TERRAFORM_NS" == "$LIVE_NS" ]; then
    echo -e "${GREEN}✅ Name Servers are up to date!${NC}"
    echo ""
    echo -e "${GREEN}👍 No action needed${NC}"
    echo ""
    
    # Test DNS resolution
    echo "🌐 Testing DNS resolution..."
    ALB_IP=$(dig +short dev.$DOMAIN | head -n 1)
    if [ -n "$ALB_IP" ]; then
        echo -e "${GREEN}✅ dev.$DOMAIN resolves to: $ALB_IP${NC}"
        
        # Test API
        echo ""
        echo "🧪 Testing API health check..."
        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://dev.$DOMAIN/health 2>/dev/null)
        if [ "$HTTP_CODE" == "200" ]; then
            echo -e "${GREEN}✅ API is responding (HTTP $HTTP_CODE)${NC}"
            echo ""
            echo -e "${GREEN}🎉 Everything is working!${NC}"
        else
            echo -e "${YELLOW}⚠️  API returned HTTP $HTTP_CODE${NC}"
            echo "   Application might still be starting up"
        fi
    else
        echo -e "${YELLOW}⚠️  Cannot resolve dev.$DOMAIN${NC}"
    fi
else
    echo -e "${RED}⚠️  Name Servers have CHANGED!${NC}"
    echo ""
    echo -e "${YELLOW}👉 ACTION REQUIRED:${NC}"
    echo "1. Login to Namecheap: https://www.namecheap.com/myaccount/login/"
    echo "2. Go to: Domain List → Manage (chs4150.me)"
    echo "3. Select: Custom DNS"
    echo "4. Update to the new Name Servers (shown above)"
    echo "5. Save changes"
    echo ""
    echo "⏱️  DNS propagation will take 15-30 minutes"
    echo ""
    echo "🔍 After updating, check propagation with:"
    echo "   dig dev.$DOMAIN"
    echo "   or visit: https://www.whatsmydns.net/#A/dev.$DOMAIN"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
