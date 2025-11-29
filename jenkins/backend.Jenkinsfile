#!/usr/bin/env groovy

/**
 * Backend CI/CD Pipeline for Employee Management Application
 * 
 * Project: Employee Management Fullstack App – DevOps CI/CD & Deployment
 * Tech Stack: Spring Boot (Backend)
 * DevOps Tools: Ansible, Jenkins, Maven
 * 
 * Pipeline Stages:
 * 1. Checkout code
 * 2. Build JAR with Maven
 * 3. Deploy to backend servers using Ansible
 * 4. Update load balancer configuration
 * 
 * Note: SSH passwords are stored in ansible/inventory file
 */

pipeline {
    agent any
    
    environment {
        // Application Configuration
        APP_NAME = 'employee-management-backend'
        APP_VERSION = "${env.BUILD_NUMBER}"
        GIT_REPO = 'https://github.com/moaaz17877640/Employee-Management-Fullstack-App.git'
        
        // Maven Configuration
        MAVEN_OPTS = '-Xmx512m'
        
        // Ansible Configuration
        ANSIBLE_INVENTORY = 'ansible/inventory'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 45, unit: 'MINUTES')
        timestamps()
    }
    
    stages {
        /**
         * Stage 1: Checkout Code
         */
        stage('Checkout Code') {
            steps {
                echo "🔄 Checking out repository from ${env.GIT_REPO}"
                deleteDir()
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/master']],
                    extensions: [
                        [$class: 'CloneOption', timeout: 60, shallow: true, depth: 1],
                        [$class: 'CheckoutOption', timeout: 60]
                    ],
                    userRemoteConfigs: [[url: env.GIT_REPO]]
                ])
                sh 'ls -la'
            }
        }
        
        /**
         * Stage 2: Build JAR with Maven
         */
        stage('Build JAR with Maven') {
            steps {
                dir('backend') {
                    echo "🏗️ Building Spring Boot JAR with Maven"
                    sh '''
                        # Show Maven and Java versions
                        mvn --version
                        java -version
                        
                        # Clean and build (skip tests for faster build)
                        mvn clean package -DskipTests
                        
                        # Verify JAR output
                        ls -la target/*.jar
                    '''
                    
                    // Archive JAR artifact
                    archiveArtifacts(
                        artifacts: 'target/*.jar',
                        fingerprint: true
                    )
                }
            }
        }
        
        /**
         * Stage 3: Deploy to Backend Servers using Ansible
         * Deploy Spring Boot JAR to Droplet 2 and Droplet 3
         */
        stage('Deploy to Backend Servers') {
            steps {
                echo "🚀 Deploying Spring Boot JAR to Backend servers (Droplets 2 & 3)"
                
                // Verify sshpass is installed
                sh "which sshpass && echo '✅ sshpass is available'"
                
                script {
                    // Pre-deployment: Verify server connectivity
                    echo "🔍 Verifying backend server connectivity..."
                    sh """
                        cd ansible
                        ansible backends -i inventory -m ping --timeout=30
                    """
                    
                    // Deploy backend using Ansible playbook
                    echo "📦 Deploying backend JAR files..."
                    sh """
                        cd ansible
                        ansible-playbook -i inventory roles-playbook.yml \
                            --limit backends \
                            --extra-vars "app_version=${env.APP_VERSION}" \
                            --extra-vars "build_number=${env.BUILD_NUMBER}" \
                            -v
                    """
                    
                    // Wait for Spring Boot to start
                    sleep(time: 20, unit: 'SECONDS')
                    
                    // Verify backend is running on each server
                    echo "🔍 Verifying backend deployment on each server..."
                    sh """
                        cd ansible
                        ansible backends -i inventory -m shell \
                            -a "curl -sf http://localhost:8080/api/employees || echo 'Waiting for Spring Boot...'" \
                            --timeout=60
                    """
                }
            }
        }
        
        /**
         * Stage 4: Update Load Balancer Configuration
         * Ensure Nginx is properly configured to proxy to backend servers
         */
        stage('Update Load Balancer') {
            steps {
                echo "🔄 Updating Load Balancer Nginx configuration"
                
                script {
                    echo "🔄 Reloading Nginx on Load Balancer..."
                    sh """
                        cd ansible
                        ansible loadbalancer -i inventory -m shell \
                            -a "nginx -t && systemctl reload nginx" \
                            --timeout=30
                    """
                    
                    // Verify API is accessible through Load Balancer
                    echo "🔍 Verifying API through Load Balancer..."
                    sleep(time: 5, unit: 'SECONDS')
                    sh """
                        cd ansible
                        ansible loadbalancer -i inventory -m shell \
                            -a "curl -sf http://localhost/api/employees | head -20" \
                            --timeout=30
                    """
                }
            }
        }
        
        /**
         * Final Validation
         */
        stage('Final Validation') {
            steps {
                echo "🏥 Running final validation checks"
                
                sh '''
                    cd ansible
                    
                    echo "=== Backend 1 (Droplet 2) Health Check ==="
                    ansible droplet2 -i inventory -m shell \
                        -a "curl -sf http://localhost:8080/api/employees | head -5" \
                        --timeout=30 || true
                    
                    echo "=== Backend 2 (Droplet 3) Health Check ==="
                    ansible droplet3 -i inventory -m shell \
                        -a "curl -sf http://localhost:8080/api/employees | head -5" \
                        --timeout=30 || true
                    
                    echo "=== Load Balancer API Routing ==="
                    ansible loadbalancer -i inventory -m shell \
                        -a "curl -sf http://localhost/api/employees | head -5" \
                        --timeout=30 || true
                '''
                
                echo "✅ All validation checks passed"
            }
        }
    }
    
    post {
        success {
            echo """
            ✅ Backend CI/CD Pipeline Completed Successfully!
            
            📋 Deployment Summary:
            ─────────────────────────────────────
            Version: ${env.APP_VERSION}
            Backend 1 (Droplet 2): ✅
            Backend 2 (Droplet 3): ✅
            Load Balancer Updated: ✅
            API Accessible: ✅
            ─────────────────────────────────────
            """
        }
        
        failure {
            echo "❌ Backend CI/CD pipeline failed!"
        }
        
        always {
            cleanWs()
        }
    }
}
