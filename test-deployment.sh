#!/bin/bash

# Test deployment script for Employee Management System
echo "🚀 Testing Complete Deployment Process..."

cd /home/moaz/test/ansible

# Test connectivity first
echo "1. Testing server connectivity..."
ansible all -i inventory -m ping

if [ $? -ne 0 ]; then
    echo "❌ Server connectivity failed!"
    exit 1
fi

echo "✅ All servers are reachable"

# Run the complete deployment
echo "2. Running complete deployment..."
ansible-playbook -i inventory deploy-complete.yml

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed!"
    exit 1
fi

echo "3. Verifying deployment..."

# Test website access
echo "Testing website..."
curl -s http://54.163.208.212/ | head -n 1 | grep -q "doctype html"
if [ $? -eq 0 ]; then
    echo "✅ Website is accessible"
else
    echo "❌ Website not accessible"
fi

# Test API endpoints
echo "Testing API endpoints..."
curl -s http://54.163.208.212/api/employees | grep -q "firstName"
if [ $? -eq 0 ]; then
    echo "✅ Employee API is working"
else
    echo "❌ Employee API not working"
fi

curl -s http://54.163.208.212/api/departments | grep -q "name"
if [ $? -eq 0 ]; then
    echo "✅ Department API is working"
else
    echo "❌ Department API not working"
fi

echo ""
echo "🎉 Deployment Test Complete!"
echo "Access your application at: http://54.163.208.212"