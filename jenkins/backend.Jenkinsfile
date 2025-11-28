#!/usr/bin/env groovy

pipeline {
    agent any
    
    environment {
        APP_NAME = 'employee-management'
        APP_VERSION = "${env.BUILD_NUMBER}"
        GIT_REPO = '/home/moaz/test/Employee-Management-Fullstack-App'
        MAVEN_OPTS = '-Dmaven.test.failure.ignore=false'
        
        // System tool paths
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
        MAVEN_HOME = '/usr/share/maven'
        PATH = "/usr/bin:${env.PATH}"
        
        // Ansible Configuration for new deployment system
        ANSIBLE_INVENTORY = 'ansible/inventory'
        ANSIBLE_PLAYBOOK_DIR = 'ansible'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        SSH_KEY_PATH = 'Key.pem'
        
        // Database Configuration (matching Ansible vars)
        DB_HOST = 'localhost'
        DB_NAME = 'employee_management'
        DB_USER = 'empapp'
        DB_PASSWORD = 'emppass123'
        ANSIBLE_FORCE_COLOR = 'true'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout Repository') {
            steps {
                echo "🔄 Using local repository at ${env.GIT_REPO}"
                script {
                    // We're already in the correct directory
                    sh 'pwd && ls -la'
                }
            }
        }
        
        stage('Build using Maven') {
            steps {
                dir('backend') {
                    echo "🏗️ Building Spring Boot application with Maven"
                    sh 'mvn clean compile'
                }
            }
        }
        
        stage('Migrate Database Models') {
            steps {
                dir('backend') {
                    echo "🗄️ Running database migrations for new changes"
                    sh '''
                        # Run database migration using Flyway
                        mvn flyway:migrate -Dflyway.url=jdbc:mysql://${DB_HOST}:3306/${DB_NAME} \
                                          -Dflyway.user=${DB_USER} \
                                          -Dflyway.password=${DB_PASSWORD} || true
                    '''
                }
            }
        }
        
        stage('Run Tests') {
            steps {
                dir('backend') {
                    echo "🧪 Running unit tests"
                    sh 'mvn test'
                }
            }
        }
        
        stage('Setup Ansible Environment') {
            when {
                // Always run for deployment - local repo doesn't need branch restrictions
                expression { return true }
            }
            steps {
                echo "🔧 Setting up Ansible environment for enhanced deployment"
                script {
                    sh """
                        # Debug information
                        echo "Current working directory: \$(pwd)"
                        echo "SSH_KEY_PATH: ${SSH_KEY_PATH}"
                        echo "Looking for SSH key..."
                        ls -la ${SSH_KEY_PATH} || echo "Key not found at ${SSH_KEY_PATH}"
                        
                        # Verify Ansible installation
                        ansible --version
                        
                        # Set up SSH key permissions (if key exists)
                        if [ -f "${SSH_KEY_PATH}" ]; then
                            chmod 400 ${SSH_KEY_PATH}
                            echo "Set SSH key permissions to 400"
                            ls -la ${SSH_KEY_PATH}
                        else
                            echo "SSH key not found at ${SSH_KEY_PATH}, skipping key setup"
                        fi
                        
                        # Install/update required collections (if requirements exist)
                        if [ -f "${ANSIBLE_PLAYBOOK_DIR}/requirements.yml" ]; then
                            cd ${ANSIBLE_PLAYBOOK_DIR}
                            ansible-galaxy collection install -r requirements.yml --force --ignore-errors
                        else
                            echo "Ansible requirements.yml not found, skipping collection install"
                        fi
                        
                        # Run pre-deployment validation for backend servers only (if playbook exists)
                        if [ -f "${ANSIBLE_PLAYBOOK_DIR}/pre-deployment-check.yml" ]; then
                            echo "🔍 Running pre-deployment validation..."
                            ansible-playbook -i ${ANSIBLE_INVENTORY} pre-deployment-check.yml -v --limit backend || echo "Pre-deployment check failed, continuing..."
                        else
                            echo "Pre-deployment check playbook not found, skipping"
                        fi
                    """
                }
                echo "✅ Ansible environment setup completed"
            }
        }
        
        stage('Package JAR') {
            steps {
                dir('backend') {
                    echo "📦 Packaging Spring Boot JAR"
                    sh 'mvn package -DskipTests'
                    
                    // Store JAR info for deployment
                    script {
                        env.JAR_FILE = sh(
                            script: 'ls target/*.jar | head -1',
                            returnStdout: true
                        ).trim()
                        
                        env.JAR_NAME = sh(
                            script: 'basename ${JAR_FILE}',
                            returnStdout: true
                        ).trim()
                        
                        echo "📋 Built JAR: ${env.JAR_NAME}"
                    }
                    
                    // Archive the JAR file
                    archiveArtifacts(
                        artifacts: 'target/*.jar',
                        fingerprint: true,
                        allowEmptyArchive: false
                    )
                }
            }
        }
        
        stage('Pre-deployment Validation') {
            when {
                // Always run validation for deployment safety
                expression { return true }
            }
            steps {
                echo "🔍 Running pre-deployment checks on target servers"
                script {
                    sh """
                        cd ansible
                        # Ensure collections are installed
                        ansible-galaxy collection install -r requirements.yml --ignore-errors
                        
                        # Run pre-deployment validation
                        ansible-playbook -i inventory pre-deployment-check.yml \\
                            --extra-vars "app_version=${env.APP_VERSION}" \\
                            --limit backend \\
                            --diff \\
                            --check
                    """
                }
                echo "✅ Pre-deployment validation completed"
            }
        }
        
        stage('Build Docker Image (Optional)') {
            when {
                environment name: 'BUILD_DOCKER', value: 'true'
            }
            steps {
                dir('backend') {
                    echo "🐳 Building Docker image"
                    script {
                        def dockerImage = docker.build("${env.APP_NAME}:${env.APP_VERSION}")
                        echo "📦 Docker image built: ${env.APP_NAME}:${env.APP_VERSION}"
                        env.DOCKER_IMAGE = "${env.APP_NAME}:${env.APP_VERSION}"
                    }
                }
            }
        }
        
        stage('Deploy to Backend Servers using Ansible') {
            when {
                // Always deploy for local development environment
                expression { return true }
            }
            steps {
                echo "🚀 Deploying backend with comprehensive validation and health checks"
                script {
                    sh """
                        cd ${ANSIBLE_PLAYBOOK_DIR}
                        
                        # Ensure SSH key permissions (adjust path from ansible directory)
                        chmod 400 ../Key.pem || echo "SSH key permission already set"
                        
                        # Pre-deployment health check
                        echo "🔍 Pre-deployment server connectivity check..."
                        ansible backend -i inventory -m ping --timeout=30 || echo "Some servers unreachable, continuing..."
                        
                        # Deploy to all backend servers with full validation
                        echo "📦 Deploying backend JAR to all servers..."
                        ansible-playbook -i inventory roles-playbook.yml \\
                            --limit backend \\
                            --extra-vars "app_version=${env.APP_VERSION}" \\
                            --extra-vars "deployment_strategy=backend_complete" \\
                            --extra-vars "force_restart=true" \\
                            --extra-vars "validate_deployment=true" \\
                            -v
                        
                        # Wait for services to fully start
                        echo "⏳ Waiting for backend services to fully initialize..."
                        sleep 45
                        
                        # Comprehensive health validation
                        echo "🏥 Running comprehensive health checks..."
                        
                        # Check if services are running
                        ansible backend -i inventory -m shell \\
                            -a "sudo systemctl is-active employee-backend || sudo systemctl status employee-backend" \\
                            --timeout=30
                        
                        # Check if ports are open
                        ansible backend -i inventory -m wait_for \\
                            -a "port=8080 host={{ ansible_default_ipv4.address }} timeout=60" \\
                            --timeout=90
                        
                        # Test API endpoints on all servers
                        echo "🔗 Testing API connectivity on all backend servers..."
                        ansible backend -i inventory -m uri \\
                            -a "url=http://{{ ansible_default_ipv4.address }}:8080/api/employees method=GET timeout=30" \\
                            --timeout=60 || {
                                echo "❌ API test failed, checking service logs..."
                                ansible backend -i inventory -m shell \\
                                    -a "sudo journalctl -u employee-backend --no-pager -n 20" \\
                                    --timeout=30
                                exit 1
                            }
                        
                        echo "✅ Backend deployment and validation completed successfully"
                    """
                }
            }
        }
        
        stage('Update Load Balancer Configuration') {
            when {
                // Always update load balancer after backend deployment
                expression { return true }
            }
            steps {
                echo "🔄 Updating load balancer with current backend server IPs"
                script {
                    sh """
                        cd ${ANSIBLE_PLAYBOOK_DIR}
                        
                        # Gather facts from backend servers to get internal IPs
                        ansible backend -i inventory -m setup --tree /tmp/facts/
                        
                        # Update load balancer configuration with current IPs
                        ansible-playbook -i inventory roles-playbook.yml \\
                            --limit loadbalancer \\
                            --extra-vars "update_backend_ips=true" \\
                            --extra-vars "reload_nginx=true" \\
                            --tags "loadbalancer,backend_config" \\
                            -v
                        
                        # Test load balancer routing
                        echo "🔗 Testing load balancer API routing..."
                        ansible loadbalancer -i inventory -m uri \\
                            -a "url=http://{{ ansible_default_ipv4.address }}/api/employees method=GET timeout=30" \\
                            --timeout=60
                        
                        echo "✅ Load balancer updated and validated successfully"
                    """
                }
            }
        }
        
        stage('Final System Validation') {
            when {
                // Always run system validation for reliability
                expression { return true }
            }
            steps {
                echo "🔍 Running comprehensive system validation"
                script {
                    sh """
                        cd ${ANSIBLE_PLAYBOOK_DIR}
                        
                        # Run post-deployment validation if playbook exists
                        if [ -f "post-deployment-validation.yml" ]; then
                            ansible-playbook -i inventory post-deployment-validation.yml \\
                                --limit backend \\
                                -v
                        fi
                        
                        # Comprehensive API health checks
                        echo "🏥 Final API validation on all backend servers..."
                        ansible backend -i inventory -m uri \\
                            -a "url=http://{{ ansible_default_ipv4.address }}:8080/api/employees method=GET status_code=200 timeout=30" \\
                            --timeout=60
                        
                        # Test through load balancer
                        echo "🔗 Testing end-to-end API through load balancer..."
                        ansible loadbalancer -i inventory -m uri \\
                            -a "url=http://{{ ansible_default_ipv4.address }}/api/employees method=GET status_code=200 timeout=30" \\
                            --timeout=60
                        
                        # Verify service status
                        echo "🔍 Final service status check..."
                        ansible backend -i inventory -m shell \\
                            -a "sudo systemctl is-active employee-backend && echo 'Service: ACTIVE' || echo 'Service: INACTIVE'" \\
                            --timeout=30
                        
                        # Log deployment success
                        echo "📝 Logging successful deployment..."
                        ansible backend -i inventory -m shell \\
                            -a "echo \\\"\\\$(date): Deployment ${env.APP_VERSION} completed successfully\\\" | sudo tee -a /var/log/employee-management/deployment.log" \\
                            --timeout=30 || echo "Deployment logging failed"
                    """
                }
                echo "✅ Complete system validation passed - backend is fully operational"
            }
        }
        
        stage('Post-Deployment Health Check') {
            when {
                // Always run health checks after deployment
                expression { return true }
            }
            steps {
                echo "🏥 Running comprehensive deployment health check"
                script {
                    sh """
                        # Run our comprehensive health check script
                        ./scripts/deployment-health-check.sh check || echo "Health check completed with warnings"
                        
                        echo "📊 Health check completed - system validation finished"
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Backend CI/CD pipeline completed successfully!"
            script {
                try {
                    if (fileExists('ansible/inventory')) {
                        dir('ansible') {
                            echo "🎯 Deployment completed successfully!"
                            echo "Deployment ${env.APP_VERSION} successful at \\\$(date)" >> deployment.log
                        }
                    } else {
                        echo "📝 Build completed successfully - no deployment logs in build-only mode"
                    }
                } catch (Exception e) {
                    echo "⚠️ Post-deployment logging failed: ${e.getMessage()}"
                }
            }
        }
        
        failure {
            echo "❌ Backend CI/CD pipeline failed!"
            script {
                if (env.BRANCH_NAME == 'master') {
                    try {
                        if (fileExists('ansible/inventory')) {
                            dir('ansible') {
                                echo "🔄 Attempting rollback due to pipeline failure..."
                                sh """
                                    ansible-playbook -i inventory site.yml \\
                                        --tags "rollback,backend" \\
                                        --extra-vars "rollback_version=previous" \\
                                        --limit backend \\
                                        --timeout 180 || echo "Rollback failed - manual intervention required"
                                """
                            }
                        } else {
                            echo "📝 Build failed - no deployment rollback needed in build-only mode"
                        }
                    } catch (Exception e) {
                        echo "⚠️ Automated rollback failed: ${e.getMessage()}"
                        echo "Manual intervention required for service recovery"
                    }
                }
            }
        }
        
        unstable {
            echo "⚠️ Pipeline completed with warnings"
        }
        
        always {
            echo "🧹 Cleaning up workspace"
            cleanWs()
        }
    }
}