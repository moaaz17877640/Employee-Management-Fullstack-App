#!/usr/bin/env groovy

// Pipeline Version: 2.1 - Password auth from Jenkins credentials

pipeline {
    agent any
    
    environment {
        // Application Configuration
        APP_NAME = 'employee-management'
        APP_VERSION = "${env.BUILD_NUMBER}"
        GIT_REPO = 'https://github.com/moaaz17877640/Employee-Management-Fullstack-App.git'
        
        // Java/Maven Configuration (Java 17 as per requirements)
        JAVA_HOME = '/usr/lib/jvm/java-17-openjdk-amd64'
        MAVEN_HOME = '/usr/share/maven'
        PATH = "${JAVA_HOME}/bin:${MAVEN_HOME}/bin:/usr/bin:${env.PATH}"
        
        // Ansible Configuration
        ANSIBLE_INVENTORY = 'ansible/inventory'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        
        // Server credentials from Jenkins secrets
        DROPLET1_PASS = credentials('droplet1-password')
        DROPLET2_PASS = credentials('droplet2-password')
        DROPLET3_PASS = credentials('droplet3-password')
        
        // Database Configuration
        DB_HOST = 'localhost'
        DB_NAME = 'employee_management'
        DB_USER = 'employee_user'
        DB_PASSWORD = 'emppass123'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }
    
    stages {
        /**
         * Stage 1: Checkout Repository
         */
        stage('Checkout Repository') {
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
         * Stage 2: Build using Maven & Migrate Database Models
         */
        stage('Build & Migrate DB') {
            steps {
                dir('backend') {
                    echo "🏗️ Building Spring Boot application with Maven"
                    sh 'mvn clean compile'
                    
                    echo "🗄️ Running database migrations for new model changes"
                    sh '''
                        # Run Flyway migrations if configured
                        mvn flyway:migrate \
                            -Dflyway.url=jdbc:mysql://${DB_HOST}:3306/${DB_NAME} \
                            -Dflyway.user=${DB_USER} \
                            -Dflyway.password=${DB_PASSWORD} || echo "Flyway migration skipped"
                    '''
                }
            }
        }
        
        /**
         * Stage 3: Run Tests
         */
        stage('Run Tests') {
            steps {
                dir('backend') {
                    echo "🧪 Running unit tests"
                    sh 'mvn test'
                }
            }
            post {
                always {
                    junit(
                        testResults: 'backend/target/surefire-reports/*.xml',
                        allowEmptyResults: true
                    )
                }
            }
        }
        
        /**
         * Stage 4: Package JAR
         */
        stage('Package JAR') {
            steps {
                dir('backend') {
                    echo "📦 Packaging Spring Boot JAR"
                    sh 'mvn package -DskipTests'
                    
                    script {
                        env.JAR_FILE = sh(
                            script: 'ls target/*.jar | grep -v original | head -1',
                            returnStdout: true
                        ).trim()
                        echo "📋 Built JAR: ${env.JAR_FILE}"
                    }
                    
                    archiveArtifacts(
                        artifacts: 'target/*.jar',
                        fingerprint: true
                    )
                }
            }
        }
        
        /**
         * Stage 5: Build Docker Image (Optional)
         */
        stage('Build Docker Image') {
            when {
                environment name: 'BUILD_DOCKER', value: 'true'
            }
            steps {
                dir('backend') {
                    echo "🐳 Building Docker image"
                    script {
                        docker.build("${env.APP_NAME}:${env.APP_VERSION}")
                        echo "📦 Docker image built: ${env.APP_NAME}:${env.APP_VERSION}"
                    }
                }
            }
        }
        
        /**
         * Stage 6: Deploy to Backend Servers using Ansible
         * Rolling deployment with zero-downtime (one server at a time)
         */
        stage('Deploy to Backend Servers') {
            steps {
                echo "🚀 Deploying to backend servers with zero-downtime rolling restart"
                
                // Ensure sshpass is installed for password authentication
                sh "which sshpass || sudo apt-get update && sudo apt-get install -y sshpass"
                
                script {
                    // Verify the JAR exists (it's already in backend/target/ from Package stage)
                    sh """
                        echo "Checking JAR file..."
                        ls -la backend/target/*.jar
                    """
                    
                    // Rolling Deployment: Server 1 first, then Server 2
                    
                    // Deploy to Backend Server 1 (Droplet 2)
                    echo "📦 [1/2] Deploying to Backend Server 1 (Droplet 2)..."
                    sh """
                        cd ansible
                        ansible-playbook -i inventory roles-playbook.yml \\
                            --limit droplet2 \\
                            --extra-vars "app_version=${env.APP_VERSION}" \\
                            --extra-vars "ansible_password=${DROPLET2_PASS}" \\
                            -v
                    """
                    
                    // Wait for service to start
                    sleep(time: 30, unit: 'SECONDS')
                    
                    // Health check Server 1
                    echo "🏥 Health check Backend Server 1..."
                    sh """
                        cd ansible
                        ansible droplet2 -i inventory -m shell \
                            -a "curl -sf http://localhost:8080/api/employees || exit 1" \
                            --extra-vars "ansible_password=${DROPLET2_PASS}" \
                            --timeout=60
                    """
                    echo "✅ Backend Server 1 healthy"
                    
                    // Deploy to Backend Server 2 (Droplet 3)
                    echo "📦 [2/2] Deploying to Backend Server 2 (Droplet 3)..."
                    sh """
                        cd ansible
                        ansible-playbook -i inventory roles-playbook.yml \
                            --limit droplet3 \
                            --extra-vars "app_version=${env.APP_VERSION}" \
                            --extra-vars "ansible_password=${DROPLET3_PASS}" \
                            -v
                    """
                    
                    // Wait for service to start
                    sleep(time: 30, unit: 'SECONDS')
                    
                    // Health check Server 2
                    echo "🏥 Health check Backend Server 2..."
                    sh """
                        cd ansible
                        ansible droplet3 -i inventory -m shell \
                            -a "curl -sf http://localhost:8080/api/employees || exit 1" \
                            --extra-vars "ansible_password=${DROPLET3_PASS}" \
                            --timeout=60
                    """
                    echo "✅ Backend Server 2 healthy"
                }
            }
        }
        
        /**
         * Stage 7: Update Load Balancer & Validate
         */
        stage('Update Load Balancer') {
            steps {
                echo "🔄 Updating load balancer with backend servers"
                sh """
                    cd ansible
                    ansible-playbook -i inventory roles-playbook.yml \
                        --limit loadbalancer \
                        --extra-vars "reload_nginx=true" \
                        --extra-vars "ansible_password=${DROPLET1_PASS}" \
                        -v
                """
                
                echo "🔗 Validating load balancer API routing..."
                sh """
                    cd ansible
                    ansible loadbalancer -i inventory -m shell \
                        -a "curl -sf http://localhost:8080/api/employees" \
                        --extra-vars "ansible_password=${DROPLET1_PASS}" \
                        --timeout=60
                """
                echo "✅ Load balancer routing verified"
            }
        }
        
        /**
         * Final Health Check
         */
        stage('Final Validation') {
            steps {
                echo "🏥 Running final system validation"
                sh """
                    cd ansible
                    
                    echo "=== Backend Server 1 ==="
                    ansible droplet2 -i inventory -m shell \
                        -a "systemctl is-active employee-backend" \
                        --extra-vars "ansible_password=${DROPLET2_PASS}"
                    
                    echo "=== Backend Server 2 ==="
                    ansible droplet3 -i inventory -m shell \
                        -a "systemctl is-active employee-backend" \
                        --extra-vars "ansible_password=${DROPLET3_PASS}"
                    
                    echo "=== Load Balancer ==="
                    ansible loadbalancer -i inventory -m shell \
                        -a "nginx -t && curl -sf http://localhost/api/employees" \
                        --extra-vars "ansible_password=${DROPLET1_PASS}"
                """
                echo "✅ All systems operational"
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
            Backend Server 1 (Droplet 2): ✅
            Backend Server 2 (Droplet 3): ✅
            Load Balancer Updated: ✅
            Zero-Downtime Deploy: ✅
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
