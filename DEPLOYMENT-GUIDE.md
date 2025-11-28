# Employee Management System - Complete Deployment Guide

This repository contains the complete automated deployment for the Employee Management Fullstack Application using Ansible.

## 🏗️ Architecture

- **Frontend**: React 18 with Material-UI, deployed on Load Balancer (droplet1)
- **Backend**: Spring Boot 2.7.5 with Java 17, deployed on 2 servers (droplet2, droplet3)
- **Database**: MySQL 8.0 on each backend server
- **Load Balancer**: Nginx with reverse proxy and static file serving

## 📋 Prerequisites

1. **Servers**: 3 DigitalOcean droplets (Ubuntu 24.04)
   - droplet1 (Load Balancer): 54.163.208.212
   - droplet2 (Backend): 18.209.24.219
   - droplet3 (Backend): 54.196.237.212

2. **Local Setup**: 
   - Ansible installed
   - SSH key (Key.pem) with access to all servers
   - Employee-Management-Fullstack-App source code

## 🚀 Deployment Instructions

### 1. One-Command Deployment

```bash
cd /home/moaz/test/ansible
ansible-playbook -i inventory deploy-complete.yml
```

### 2. Test Deployment

```bash
cd /home/moaz/test
./test-deployment.sh
```

## 📁 File Structure

```
ansible/
├── deploy-complete.yml    # Main deployment playbook
├── inventory             # Server inventory file
└── templates/           # Configuration templates

Employee-Management-Fullstack-App/
├── frontend/            # React source code
├── backend/            # Spring Boot source code
└── ...
```

## ⚙️ What the Playbook Does

### Backend Servers (droplet2, droplet3):
1. ✅ Installs Java 17 and MySQL 8.0
2. ✅ Configures MySQL with database and user
3. ✅ Deploys Spring Boot JAR file
4. ✅ Creates systemd service for automatic startup
5. ✅ Configures application.properties for MySQL connection

### Load Balancer (droplet1):
1. ✅ Installs Nginx and Node.js 18
2. ✅ Copies React frontend source code
3. ✅ Updates API endpoints to point to load balancer
4. ✅ Installs npm dependencies and builds React app
5. ✅ Configures Nginx for load balancing and static serving
6. ✅ Deploys optimized production build

## 🌐 Access Points

- **Website**: http://54.163.208.212
- **API Endpoints**:
  - Employees: http://54.163.208.212/api/employees
  - Departments: http://54.163.208.212/api/departments

## 🔧 Configuration Variables

Key variables in `deploy-complete.yml`:

```yaml
vars:
  backend_port: 8080
  mysql_root_password: "rootpass123"
  mysql_database: "employee_management"
  mysql_user: "empapp"
  mysql_password: "emppass123"
```

## 📊 Features Deployed

### React Frontend:
- ✅ Material-UI components
- ✅ Employee management interface
- ✅ Department management
- ✅ Dashboard with charts
- ✅ Responsive design
- ✅ Production-optimized build

### Spring Boot Backend:
- ✅ REST API endpoints
- ✅ MySQL database integration
- ✅ Load balanced across 2 servers
- ✅ Health check endpoints
- ✅ CORS configuration

### Infrastructure:
- ✅ Nginx load balancing
- ✅ Systemd service management
- ✅ Automatic startup on reboot
- ✅ Error handling and recovery

## 🛠️ Troubleshooting

1. **Check server connectivity**: `ansible all -i inventory -m ping`
2. **Verify services**: `ansible backend -i inventory -a "systemctl status employee-backend"`
3. **Check logs**: `ansible backend -i inventory -a "journalctl -u employee-backend -n 50"`
4. **Test APIs directly**: `curl http://18.209.24.219:8080/api/employees`

## 🔄 Redeployment

The playbook is idempotent and can be run multiple times safely. It will:
- Update configurations if changed
- Restart services if needed
- Rebuild frontend if source code changes
- Maintain data persistence

## 📈 Performance

- **Load Balancing**: Requests distributed across 2 backend servers
- **Database**: Each backend has its own MySQL instance
- **Frontend**: Optimized React build served via Nginx
- **Caching**: Static assets cached by Nginx

## 🎯 Success Indicators

After deployment, you should see:
- ✅ Website accessible at http://54.163.208.212
- ✅ Employee list loads with 295+ records
- ✅ Department list shows 50+ departments
- ✅ Both backend servers responding to API calls
- ✅ Professional React UI with Material-UI components

---

## 📝 Notes

- The deployment includes sample data (295 employees, 50+ departments)
- All services are configured for automatic startup
- MySQL databases are configured with proper authentication
- React app is built in production mode for optimal performance
- Nginx is configured for both static serving and API proxying