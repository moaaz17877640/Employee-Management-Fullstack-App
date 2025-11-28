#!/usr/bin/env python3
"""
DevOps Pipeline Architecture Diagram
Employee Management System - Complete DevOps Workflow

This script generates a visual representation of the DevOps tasks and pipeline
using the diagrams library (https://diagrams.mingrammer.com/)

To run this script:
1. Install diagrams: pip install diagrams
2. Run: python3 devops_pipeline_diagram.py
3. Output: devops_pipeline.png
"""

from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.vcs import Git, Github
from diagrams.onprem.ci import Jenkins
from diagrams.onprem.compute import Server
from diagrams.onprem.network import Nginx
from diagrams.onprem.database import Mysql
from diagrams.programming.language import Java, Javascript
from diagrams.programming.framework import React, Spring
from diagrams.onprem.iac import Ansible
from diagrams.aws.storage import S3
from diagrams.onprem.container import Docker
from diagrams.generic.compute import Rack
from diagrams.generic.network import Firewall
from diagrams.generic.storage import Storage

def create_devops_pipeline():
    """Create comprehensive DevOps pipeline diagram"""
    
    with Diagram("", 
                 show=False, 
                 direction="TB",
                 filename="devops_pipeline"):
        
        # ============= SOURCE CONTROL =============
        with Cluster(""):
            developer = Git("👨‍💻 Developer")
            github_repo = Github("GitHub Repository\nEmployee-Management-App")
            git_push = developer >> Edge(label="git push", style="bold") >> github_repo
        
        # ============= CI/CD PIPELINE =============  
        with Cluster(""):
            jenkins_server = Jenkins("Jenkins CI/CD Server")
            
            with Cluster(""):
                maven_build = Java("Maven Build\n• mvn clean install\n• Unit Tests (JUnit)\n• Integration Tests")
                jar_package = Storage("JAR Package\nemployee-mgmt.jar")
                maven_build >> jar_package
            
            with Cluster(""):
                react_build = React("React Build\n• npm install\n• npm run build\n• Asset optimization")
                static_files = Storage("Static Files\nbuild/ directory")
                react_build >> static_files
            
            # Webhook trigger
            github_repo >> Edge(label="webhook trigger", style="dashed") >> jenkins_server
            jenkins_server >> maven_build
            jenkins_server >> react_build
        
        # ============= INFRASTRUCTURE AS CODE =============
        with Cluster(""):
            ansible_controller = Ansible("Ansible Controller\n• Inventory Management\n• Role-based Deployment")
            
            with Cluster(""):
                backend_role = Rack("Backend Role\n• Java 17 Install\n• MySQL Setup\n• Service Config")
                frontend_role = Rack("Frontend Role\n• Node.js Install\n• React Build Deploy\n• Nginx Config")
                loadbalancer_role = Rack("LoadBalancer Role\n• Nginx Install\n• Reverse Proxy\n• Health Checks")
            
            # Jenkins triggers Ansible
            jenkins_server >> Edge(label="deploy via ansible", style="bold") >> ansible_controller
            ansible_controller >> backend_role
            ansible_controller >> frontend_role  
            ansible_controller >> loadbalancer_role
        
        # ============= TARGET INFRASTRUCTURE =============
        with Cluster(""):
            
            with Cluster(""):
                nginx_lb = Nginx("DigitalOcean LB\n3.230.162.100\n• Reverse Proxy\n• Static File Serving")
                react_app = React("React SPA\nMaterial-UI + Charts")
                nginx_lb >> react_app
            
            with Cluster(""):
                with Cluster("DigitalOcean Droplet 2"):
                    backend1 = Spring("Spring Boot\n3.226.250.69\nPort 8080")
                    mysql1 = Mysql("MySQL 8.0\nemployee_management")
                    backend1 >> mysql1
                
                with Cluster("DigitalOcean Droplet 3"):
                    backend2 = Spring("Spring Boot\n44.221.42.175\nPort 8080") 
                    mysql2 = Mysql("MySQL 8.0\nemployee_management")
                    backend2 >> mysql2
            
            # Load balancer connections
            nginx_lb >> Edge(label="API proxy /api/*") >> backend1
            nginx_lb >> Edge(label="API proxy /api/*") >> backend2
            
            # Ansible deployment arrows
            loadbalancer_role >> Edge(label="configure", style="dashed") >> nginx_lb
            backend_role >> Edge(label="deploy", style="dashed") >> backend1
            backend_role >> Edge(label="deploy", style="dashed") >> backend2
            frontend_role >> Edge(label="build deploy", style="dashed") >> react_app
        
        # ============= MONITORING & OPERATIONS =============
        with Cluster(""):
            health_monitor = Server("Health Monitoring\n• Service Status\n• API Endpoints\n• Database Connectivity")
            logs = Storage("System Logs\n• Application Logs\n• Nginx Logs\n• System Metrics")
            
            nginx_lb >> Edge(label="health checks", style="dotted") >> health_monitor
            backend1 >> Edge(label="metrics", style="dotted") >> health_monitor
            backend2 >> Edge(label="metrics", style="dotted") >> health_monitor
            health_monitor >> logs
        
        # ============= DEVOPS TASKS FLOW =============
        # Add task descriptions as annotations
        
        return "DevOps pipeline diagram generated successfully!"

def create_devops_tasks_breakdown():
    """Create detailed DevOps tasks breakdown diagram"""
    
    with Diagram("", 
                 show=False, 
                 direction="LR",
                 filename="devops_tasks"):
        
        # ============= DEVELOPER TASKS =============
        with Cluster("👨‍💻 Developer Tasks"):
            code_changes = Git("Code Changes\n• Feature Development\n• Bug Fixes\n• Unit Tests")
            git_operations = Github("Git Operations\n• git add .\n• git commit -m\n• git push origin master")
            code_changes >> git_operations
        
        # ============= AUTOMATED CI/CD TASKS =============
        with Cluster("🤖 Automated CI/CD Tasks"):
            trigger = Jenkins("Webhook Trigger\n• GitHub webhook\n• Branch detection\n• Pipeline start")
            
            with Cluster("Build Tasks"):
                backend_tasks = Java("Backend Tasks\n• Maven clean install\n• Run unit tests\n• Package JAR\n• Docker build (optional)")
                frontend_tasks = Javascript("Frontend Tasks\n• npm install\n• npm run build\n• Asset optimization\n• Static file prep")
            
            with Cluster("Test Tasks"):
                unit_tests = Storage("Unit Testing\n• JUnit tests\n• Jest tests\n• Coverage reports\n• Quality gates")
                integration_tests = Storage("Integration Tests\n• API testing\n• Component tests\n• E2E validation")
            
            git_operations >> Edge(label="webhook", style="bold") >> trigger
            trigger >> backend_tasks
            trigger >> frontend_tasks
            backend_tasks >> unit_tests
            backend_tasks >> integration_tests
            frontend_tasks >> unit_tests
            frontend_tasks >> integration_tests
        
        # ============= ANSIBLE CONFIGURATION TASKS =============
        with Cluster("⚙️ Server Configuration Tasks (Ansible)"):
            inventory_mgmt = Ansible("Inventory Management\n• Dynamic IP detection\n• Server grouping\n• SSH key management")
            
            with Cluster("Pre-deployment"):
                pre_checks = Firewall("Pre-deployment Checks\n• System validation\n• Port availability\n• Network connectivity\n• Resource verification")
            
            with Cluster("Deployment Roles"):
                backend_config = Server("Backend Configuration\n• Install Java 17\n• Setup MySQL 8.0\n• Deploy JAR file\n• Configure systemd service")
                frontend_config = Server("Frontend Configuration\n• Install Node.js 18\n• Build React app\n• Configure Nginx\n• Setup static serving")
                lb_config = Server("Load Balancer Config\n• Install Nginx\n• Setup reverse proxy\n• Configure health checks\n• Enable load balancing")
            
            with Cluster("Post-deployment"):
                validation = Storage("Post-deployment Validation\n• Health checks\n• API testing\n• Database connectivity\n• Service status verification")
            
            unit_tests >> inventory_mgmt
            integration_tests >> inventory_mgmt
            inventory_mgmt >> pre_checks
            pre_checks >> backend_config
            pre_checks >> frontend_config 
            pre_checks >> lb_config
            backend_config >> validation
            frontend_config >> validation
            lb_config >> validation
        
        # ============= PRODUCTION DEPLOYMENT =============
        with Cluster("🚀 Production Deployment"):
            with Cluster("Infrastructure"):
                prod_lb = Nginx("Load Balancer\n• Nginx reverse proxy\n• React SPA serving\n• SSL termination")
                prod_backend1 = Spring("Backend Server 1\n• Spring Boot app\n• MySQL database\n• Health endpoints")
                prod_backend2 = Spring("Backend Server 2\n• Spring Boot app\n• MySQL database\n• Health endpoints")
            
            validation >> Edge(label="zero-downtime deployment") >> prod_lb
            validation >> Edge(label="zero-downtime deployment") >> prod_backend1
            validation >> Edge(label="zero-downtime deployment") >> prod_backend2
        
        return "DevOps tasks breakdown generated successfully!"

def create_ansible_workflow():
    """Create detailed Ansible workflow diagram"""
    
    with Diagram("", 
                 show=False, 
                 direction="TB",
                 filename="ansible_workflow"):
        
        # ============= ANSIBLE CONTROLLER =============
        with Cluster("🎛️ Ansible Control Node"):
            ansible_main = Ansible("Ansible Controller\n• Playbook execution\n• Role management\n• Variable handling")
            inventory_file = Storage("Dynamic Inventory\n• Server groups\n• IP detection\n• SSH configuration")
            ansible_main >> inventory_file
        
        # ============= PLAYBOOK EXECUTION =============
        with Cluster("📜 Playbook Execution Flow"):
            pre_deployment = Storage("1. Pre-deployment\n• System checks\n• Port validation\n• Network testing\n• Prerequisite verification")
            
            main_deployment = Storage("2. Main Deployment\n• roles-playbook.yml\n• Role assignment\n• Variable injection\n• Task execution")
            
            post_deployment = Storage("3. Post-deployment\n• Health validation\n• Service verification\n• API testing\n• Monitoring setup")
            
            ansible_main >> pre_deployment >> main_deployment >> post_deployment
        
        # ============= ROLE-BASED TASKS =============
        with Cluster("📦 Ansible Role Tasks"):
            with Cluster("Backend Role Tasks"):
                java_install = Java("Install Java 17\n• Update packages\n• Install OpenJDK\n• Set JAVA_HOME\n• Verify installation")
                mysql_setup = Mysql("Setup MySQL 8.0\n• Install MySQL\n• Create database\n• Setup user/permissions\n• Configure security")
                app_deploy = Spring("Deploy Application\n• Copy JAR file\n• Configure properties\n• Create systemd service\n• Start application")
                
                java_install >> mysql_setup >> app_deploy
            
            with Cluster("Frontend Role Tasks"):
                node_install = Javascript("Install Node.js 18\n• Add NodeSource repo\n• Install Node.js\n• Verify npm\n• Set permissions")
                react_build = React("Build React App\n• Clone repository\n• Install dependencies\n• Run production build\n• Optimize assets")
                
                node_install >> react_build
            
            with Cluster("Load Balancer Role Tasks"):
                nginx_install = Nginx("Install Nginx\n• Update packages\n• Install Nginx\n• Configure firewall\n• Enable service")
                nginx_config = Server("Configure Nginx\n• Setup sites\n• Configure proxy\n• Setup load balancing\n• Enable health checks")
                
                nginx_install >> nginx_config
            
            main_deployment >> java_install
            main_deployment >> node_install
            main_deployment >> nginx_install
        
        # ============= TARGET SERVERS =============
        with Cluster("🎯 Target Server Configuration"):
            with Cluster("Droplet 1 - Load Balancer"):
                lb_server = Server("DigitalOcean Droplet 1\n3.230.162.100\nUbuntu 24.04\n• Nginx\n• React SPA")
                lb_services = Storage("Services\n• nginx.service\n• Health monitoring\n• Log rotation")
                lb_server >> lb_services
            
            with Cluster("Droplet 2 - Backend 1"):
                backend1_server = Server("DigitalOcean Droplet 2\n3.226.250.69\nUbuntu 24.04\n• Java 17\n• MySQL 8.0")
                backend1_services = Storage("Services\n• employee-backend.service\n• mysql.service\n• Log monitoring")
                backend1_server >> backend1_services
            
            with Cluster("Droplet 3 - Backend 2"):
                backend2_server = Server("DigitalOcean Droplet 3\n44.221.42.175\nUbuntu 24.04\n• Java 17\n• MySQL 8.0")
                backend2_services = Storage("Services\n• employee-backend.service\n• mysql.service\n• Log monitoring")
                backend2_server >> backend2_services
            
            # Role to server mapping
            nginx_config >> lb_server
            app_deploy >> backend1_server
            app_deploy >> backend2_server
            react_build >> lb_server
        
        return "Ansible workflow diagram generated successfully!"

if __name__ == "__main__":
    print("🎨 Generating DevOps Pipeline Diagrams...")
    print("=" * 50)
    
    try:
        result1 = create_devops_pipeline()
        print(f"✅ {result1}")
        
        result2 = create_devops_tasks_breakdown()
        print(f"✅ {result2}")
        
        result3 = create_ansible_workflow()
        print(f"✅ {result3}")
        
        print("\n📊 Generated Diagrams:")
        print("• devops_pipeline.png - Complete DevOps workflow")
        print("• devops_tasks.png - Detailed task breakdown")
        print("• ansible_workflow.png - Ansible configuration process")
        print("\n🚀 To install diagrams library:")
        print("pip install diagrams")
        print("\n📖 Documentation: https://diagrams.mingrammer.com/")
        
    except ImportError:
        print("❌ Error: diagrams library not installed")
        print("📥 Install with: pip install diagrams")
        print("🔧 Then run: python3 devops_pipeline_diagram.py")
        
    except Exception as e:
        print(f"❌ Error generating diagrams: {e}")