# Cloudflare Domain Setup Guide

This guide explains how to configure a Cloudflare subdomain for your Employee Management application with Let's Encrypt SSL.

## Prerequisites
- A domain registered with Cloudflare (free account is sufficient)
- Access to Cloudflare DNS management

## Step 1: Configure Cloudflare DNS

1. **Login to Cloudflare Dashboard**
   - Go to https://dash.cloudflare.com
   - Select your domain

2. **Add A Record**
   ```
   Type: A
   Name: emp-mgmt (or your preferred subdomain)
   Content: 18.208.213.100 (your load balancer IP)
   Proxy status: DNS only (gray cloud, not proxied)
   TTL: Auto
   ```

3. **Important: Disable Cloudflare Proxy**
   - Click the orange cloud to make it gray (DNS only)
   - This is crucial for Let's Encrypt certificate generation

## Step 2: Update Ansible Configuration

1. **Edit inventory file:**
   ```ini
   # Replace these values with your actual domain and email
   domain_name=emp-mgmt.yourdomain.com
   ssl_email=your-email@yourdomain.com
   ssl_type=letsencrypt
   enable_ssl=true
   ```

2. **Example configuration:**
   ```ini
   domain_name=emp-mgmt.mydomain.com
   ssl_email=admin@mydomain.com
   ssl_type=letsencrypt
   enable_ssl=true
   ```

## Step 3: Deploy with SSL

1. **Run the deployment:**
   ```bash
   cd /home/moaz/test/ansible
   ansible-playbook -i inventory deploy-complete.yml
   ```

2. **The deployment will:**
   - Clone the React app from GitHub
   - Generate Let's Encrypt SSL certificate
   - Configure Nginx with HTTPS
   - Set up automatic certificate renewal

## Step 4: Verification

1. **Run verification script:**
   ```bash
   cd /home/moaz/test
   ./verify-enhanced-deployment.sh
   ```

2. **Manual verification:**
   ```bash
   # Test HTTPS
   curl -I https://emp-mgmt.yourdomain.com

   # Test HTTP redirect
   curl -I http://emp-mgmt.yourdomain.com

   # Check SSL certificate
   openssl s_client -connect emp-mgmt.yourdomain.com:443 -servername emp-mgmt.yourdomain.com
   ```

## Step 5: Enable Cloudflare Proxy (Optional)

After SSL is working correctly, you can optionally enable Cloudflare proxy:

1. **In Cloudflare DNS:**
   - Change the A record from gray cloud to orange cloud
   - This enables Cloudflare's CDN and DDoS protection

2. **Configure SSL in Cloudflare:**
   - Go to SSL/TLS tab
   - Set encryption mode to "Full (strict)"
   - Enable "Always Use HTTPS"

## Troubleshooting

### DNS Issues
```bash
# Check DNS propagation
nslookup emp-mgmt.yourdomain.com
dig emp-mgmt.yourdomain.com

# Test from different locations
https://whatsmydns.net/
```

### SSL Certificate Issues
```bash
# Check certificate status
ssh ubuntu@18.208.213.100 'certbot certificates'

# Manual certificate generation
ssh ubuntu@18.208.213.100 'certbot certonly --nginx -d emp-mgmt.yourdomain.com'

# Check nginx configuration
ssh ubuntu@18.208.213.100 'nginx -t'
```

### Port Access Issues
```bash
# Ensure ports 80 and 443 are open in security groups
# AWS Security Groups should allow:
# - Port 80 (HTTP) from 0.0.0.0/0
# - Port 443 (HTTPS) from 0.0.0.0/0
```

## Security Best Practices

1. **Cloudflare Settings:**
   - Enable "Always Use HTTPS"
   - Set minimum TLS version to 1.2
   - Enable HSTS
   - Configure security headers

2. **Certificate Monitoring:**
   - Certificates auto-renew via cron job
   - Monitor renewal in `/var/log/letsencrypt/`
   - Set up alerts for certificate expiry

3. **Firewall Rules:**
   - Only expose ports 80, 443, and SSH (22)
   - Restrict SSH access to known IPs
   - Use fail2ban for SSH protection

## URLs After Setup

- **Primary Site:** https://emp-mgmt.yourdomain.com
- **API Endpoints:** https://emp-mgmt.yourdomain.com/api/employees
- **Health Check:** https://emp-mgmt.yourdomain.com/health
- **HTTP (redirects):** http://emp-mgmt.yourdomain.com

## Maintenance

### Certificate Renewal
Automatic renewal is configured, but you can manually check:
```bash
ssh ubuntu@18.208.213.100 'certbot renew --dry-run'
```

### Update Application
To update from GitHub:
```bash
cd /home/moaz/test/ansible
ansible-playbook -i inventory deploy-complete.yml --tags=frontend
```

### Monitor Logs
```bash
# Application logs
ssh ubuntu@18.208.213.100 'tail -f /var/log/nginx/access.log'

# SSL renewal logs
ssh ubuntu@18.208.213.100 'tail -f /var/log/letsencrypt/letsencrypt.log'

# Health monitoring
ssh ubuntu@18.208.213.100 'tail -f /var/log/nginx/health-check.log'
```