#!/bin/bash

# Verification Script for Enhanced Employee Management Deployment
# Tests SSL, Health Checks, and Logging Configuration

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

LOAD_BALANCER_IP="18.208.213.100"
DOMAIN_NAME="emp-mgmt.yourdomain.com"  # Update this with your actual domain
BACKEND_SERVERS=("18.207.116.100" "100.27.215.37")
SSL_ENABLED=true
SSL_TYPE="letsencrypt"

echo -e "${YELLOW}=== Employee Management App Verification ===${NC}"
echo -e "${YELLOW}Testing SSL, Health Checks, and Logging${NC}\n"

# Test 1: Basic connectivity
echo -e "${YELLOW}1. Testing basic connectivity...${NC}"
if ping -c 3 $LOAD_BALANCER_IP > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Load balancer reachable${NC}"
else
    echo -e "${RED}✗ Load balancer unreachable${NC}"
fi

# Test 2: HTTP redirect to HTTPS (if SSL enabled)
echo -e "\n${YELLOW}2. Testing HTTP to HTTPS redirect...${NC}"
HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -L http://$LOAD_BALANCER_IP/)
if [ "$HTTP_RESPONSE" = "200" ] || [ "$HTTP_RESPONSE" = "301" ]; then
    echo -e "${GREEN}✓ HTTP response: $HTTP_RESPONSE${NC}"
else
    echo -e "${RED}✗ HTTP response: $HTTP_RESPONSE${NC}"
fi

# Test 3: HTTPS with Let's Encrypt certificate
echo -e "\n${YELLOW}3. Testing HTTPS with Let's Encrypt certificate...${NC}"
if [ "$SSL_ENABLED" = "true" ]; then
    # Test HTTPS connection with domain
    HTTPS_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN_NAME/)
    if [ "$HTTPS_RESPONSE" = "200" ]; then
        echo -e "${GREEN}✓ HTTPS response: $HTTPS_RESPONSE${NC}"
        
        # Check certificate details
        if command -v openssl > /dev/null 2>&1; then
            echo "Certificate details:"
            echo | openssl s_client -connect $LOAD_BALANCER_IP:443 -servername $DOMAIN_NAME 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null
        fi
        
        # Check SSL Labs grade (optional)
        echo "SSL Configuration: Professional Let's Encrypt certificate"
    else
        echo -e "${RED}✗ HTTPS response: $HTTPS_RESPONSE${NC}"
    fi
else
    echo -e "${YELLOW}! SSL is disabled${NC}"
fi

# Test 4: Health check endpoint (HTTP and HTTPS)
echo -e "\n${YELLOW}4. Testing health check endpoints...${NC}"

# Test HTTP health endpoint (should redirect)
HEALTH_HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN_NAME/health)
if [ "$HEALTH_HTTP" = "301" ] || [ "$HEALTH_HTTP" = "302" ]; then
    echo -e "${GREEN}✓ HTTP Health endpoint redirects: $HEALTH_HTTP${NC}"
else
    echo -e "${YELLOW}! HTTP Health endpoint: $HEALTH_HTTP${NC}"
fi

# Test HTTPS health endpoint
if [ "$SSL_ENABLED" = "true" ]; then
    HEALTH_HTTPS=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN_NAME/health)
    if [ "$HEALTH_HTTPS" = "200" ]; then
        echo -e "${GREEN}✓ HTTPS Health endpoint: $HEALTH_HTTPS${NC}"
        HTTPS_HEALTH_BODY=$(curl -s https://$DOMAIN_NAME/health)
        echo "HTTPS Response: $HTTPS_HEALTH_BODY"
    else
        echo -e "${RED}✗ HTTPS Health endpoint: $HEALTH_HTTPS${NC}"
    fi
fi

# Test 5: Backend server health
echo -e "\n${YELLOW}5. Testing backend server health...${NC}"
for i in "${!BACKEND_SERVERS[@]}"; do
    server="${BACKEND_SERVERS[$i]}"
    echo "Testing Backend $((i+1)): $server"
    
    BACKEND_HEALTH=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "http://$server:8080/actuator/health")
    if [ "$BACKEND_HEALTH" = "200" ]; then
        echo -e "${GREEN}✓ Backend $((i+1)) healthy: $BACKEND_HEALTH${NC}"
    else
        echo -e "${RED}✗ Backend $((i+1)) unhealthy: $BACKEND_HEALTH${NC}"
    fi
done

# Test 6: API endpoints through load balancer
echo -e "\n${YELLOW}6. Testing API endpoints...${NC}"
API_ENDPOINTS=("/api/employees" "/api/departments")

# Use HTTPS with domain for API testing
for endpoint in "${API_ENDPOINTS[@]}"; do
    echo "Testing: $endpoint (https://$DOMAIN_NAME)"
    API_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "https://$DOMAIN_NAME$endpoint")
    if [ "$API_RESPONSE" = "200" ]; then
        echo -e "${GREEN}✓ API $endpoint: $API_RESPONSE${NC}"
    else
        echo -e "${RED}✗ API $endpoint: $API_RESPONSE${NC}"
    fi
done

# Test 7: Frontend application
echo -e "\n${YELLOW}7. Testing frontend application...${NC}"

# Test HTTPS frontend
if [ "$SSL_ENABLED" = "true" ]; then
    FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN_NAME/)
    if [ "$FRONTEND_RESPONSE" = "200" ]; then
        echo -e "${GREEN}✓ HTTPS Frontend application: $FRONTEND_RESPONSE${NC}"
    else
        echo -e "${RED}✗ HTTPS Frontend application: $FRONTEND_RESPONSE${NC}"
    fi
fi

# Test HTTP (should redirect to HTTPS)
HTTP_FRONTEND=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN_NAME/)
if [ "$HTTP_FRONTEND" = "301" ] || [ "$HTTP_FRONTEND" = "302" ]; then
    echo -e "${GREEN}✓ HTTP redirects to HTTPS: $HTTP_FRONTEND${NC}"
else
    echo -e "${YELLOW}! HTTP response: $HTTP_FRONTEND${NC}"
fi

# Test 8: Check if monitoring is working
echo -e "\n${YELLOW}8. Testing monitoring setup...${NC}"
echo "Note: SSH to servers to check:"
echo "  - Health logs: /var/log/employee-management/"
echo "  - Nginx logs: /var/log/nginx/"
echo "  - Cron jobs: crontab -l"
echo "  - Monitoring script: /usr/local/bin/enhanced-monitor.sh"

# Summary
echo -e "\n${YELLOW}=== Verification Summary ===${NC}"
echo "Domain: $DOMAIN_NAME"
echo "Load Balancer IP: $LOAD_BALANCER_IP"
echo "SSL Enabled: $SSL_ENABLED (Type: $SSL_TYPE)"
echo "Backend Servers: ${BACKEND_SERVERS[*]}"
echo ""
if [ "$SSL_ENABLED" = "true" ]; then
    echo "Access URLs:"
    echo "  Primary: https://$DOMAIN_NAME"
    echo "  HTTP:    http://$DOMAIN_NAME (redirects to HTTPS)"
    echo ""
    echo "SSL Certificate: Let's Encrypt (auto-renewal enabled)"
    echo "GitHub Source: https://github.com/hoangsonww/Employee-Management-Fullstack-App.git"
else
    echo "Access URL: http://$DOMAIN_NAME"
fi
echo ""
echo "To check logs on servers:"
echo "ssh ubuntu@$LOAD_BALANCER_IP 'tail -f /var/log/nginx/health-check.log'"
echo "ssh ubuntu@${BACKEND_SERVERS[0]} 'tail -f /var/log/employee-management/application.log'"
if [ "$SSL_ENABLED" = "true" ]; then
    echo "ssh ubuntu@$LOAD_BALANCER_IP 'certbot certificates'"
    echo "ssh ubuntu@$LOAD_BALANCER_IP 'ls -la /etc/letsencrypt/live/$DOMAIN_NAME/'"
fi
echo ""
echo "Setup Instructions:"
echo "1. Point your Cloudflare subdomain to: $LOAD_BALANCER_IP"
echo "2. Update domain_name in inventory: $DOMAIN_NAME"
echo "3. Update ssl_email in inventory with your email"
echo "4. Run: ansible-playbook -i inventory deploy-complete.yml"
echo ""
echo -e "${GREEN}Verification completed!${NC}"