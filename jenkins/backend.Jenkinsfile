#!/usr/bin/env groovy

pipeline {
    agent any
    
    environment {
        APP_NAME = 'employee-management'
        APP_VERSION = "${env.BUILD_NUMBER}"
        GIT_REPO = 'https://github.com/hoangsonww/Employee-Management-Fullstack-App.git'
        MAVEN_OPTS = '-Dmaven.test.failure.ignore=false'
        
        // Ansible Configuration for new deployment system
        ANSIBLE_INVENTORY = '../test/ansible/inventory'
        ANSIBLE_PLAYBOOK_DIR = '../test/ansible'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        SSH_KEY_PATH = '../test/Key.pem'
        
        // Database Configuration (matching Ansible vars)
        DB_HOST = 'localhost'
        DB_NAME = 'employee_management'
        DB_USER = 'empapp'
        DB_PASSWORD = 'emppass123'
        ANSIBLE_STDOUT_CALLBACK = 'yaml'
        ANSIBLE_FORCE_COLOR = 'true'
    }
    
    tools {
        maven 'Maven-3.9.0'
        jdk 'OpenJDK-17'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout Repository') {
            steps {
                echo "🔄 Checking out code from ${env.GIT_REPO}"
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/master']],
                    doGenerateSubmoduleConfigurations: false,
                    extensions: [[$class: 'CleanCheckout']],
                    submoduleCfg: [],
                    userRemoteConfigs: [[url: env.GIT_REPO]]
                ])
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
                branch 'master'
            }
            steps {
                echo "🔧 Setting up Ansible environment for enhanced deployment"
                script {
                    sh """
                        # Verify Ansible installation
                        ansible --version
                        
                        # Set up SSH key permissions
                        chmod 400 ${SSH_KEY_PATH}
                        
                        # Install/update required collections
                        cd ${ANSIBLE_PLAYBOOK_DIR}
                        ansible-galaxy collection install -r requirements.yml --force --ignore-errors
                        
                        # Run pre-deployment validation for backend servers only
                        echo "🔍 Running pre-deployment validation..."
                        ansible-playbook -i inventory pre-deployment-check.yml -v --limit backend
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
                branch 'master'
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
                branch 'master'
            }
            steps {
                echo "🚀 Deploying backend with zero-downtime rolling deployment"
                script {
                    sh """
                        cd ${ANSIBLE_PLAYBOOK_DIR}
                        
                        # Zero-downtime rolling deployment to backend servers
                        echo "🔄 Starting rolling deployment to backend servers..."
                        
                        # Deploy to first backend server
                        ansible-playbook -i inventory roles-playbook.yml \\
                            --limit droplet2 \\
                            --extra-vars "app_version=${env.APP_VERSION}" \\
                            --extra-vars "deployment_strategy=rolling" \\
                            --extra-vars "enable_zero_downtime=true" \\
                            --tags "backend" \\
                            -v
                        
                        # Wait for first server to be ready
                        echo "⏳ Waiting for first server to be ready..."
                        sleep 30
                        
                        # Verify first server is healthy before deploying to second
                        ansible backend -i inventory -m uri \\
                            -a "url=http://{{ ansible_default_ipv4.address }}:8080/api/employees method=GET" \\
                            --limit droplet2
                        
                        # Deploy to second backend server
                        ansible-playbook -i inventory roles-playbook.yml \\
                            --limit droplet3 \\
                            --extra-vars "app_version=${env.APP_VERSION}" \\
                            --extra-vars "deployment_strategy=rolling" \\
                            --extra-vars "enable_zero_downtime=true" \\
                            --tags "backend" \\
                            -v
                        
                        echo "✅ Rolling deployment completed successfully"
                    """
                }
            }
        }
        
        stage('Post-deployment Validation') {
            when {
                branch 'master'
            }
            steps {
                echo "🔍 Running comprehensive post-deployment validation"
                script {
                    sh """
                        cd ${ANSIBLE_PLAYBOOK_DIR}
                        
                        # Run post-deployment validation for backend servers
                        ansible-playbook -i inventory post-deployment-validation.yml \\
                            --limit backend \\
                            -v
                        
                        # Additional API health checks
                        echo "🏥 Testing API endpoints on all backend servers..."
                        ansible backend -i inventory -m uri \\
                            -a "url=http://{{ ansible_default_ipv4.address }}:8080/api/employees method=GET status_code=200" \\
                            --one-line
                    """
                }
                echo "✅ All backend servers validated successfully"
            }
        }
                script {
                    sh """
                        cd ansible
                        # Run post-deployment validation
                        ansible-playbook -i inventory post-deployment-validation.yml \\
                            --extra-vars "app_version=${env.APP_VERSION}" \\
                            --extra-vars "backend_port=8080" \\
                            --extra-vars "app_name=${env.APP_NAME}" \\
                            --limit backend \\
                            --timeout 120
                    """
                }
                echo "✅ Post-deployment validation completed successfully"
            }
        }
    }
    
    post {
        always {
            echo "🧹 Cleaning up workspace"
            cleanWs()
        }
        
        success {
            echo "✅ Backend CI/CD pipeline completed successfully!"
            script {
                // Tag successful deployment
                sh """
                    cd ansible
                    echo "Deployment ${env.APP_VERSION} successful at \$(date)" >> deployment.log
                """
            }
        }
        
        failure {
            echo "❌ Backend CI/CD pipeline failed!"
            script {
                // Attempt rollback on deployment failure for master branch
                if (env.BRANCH_NAME == 'master') {
                    try {
                        sh """
                            cd ansible
                            echo "🔄 Attempting rollback due to pipeline failure..."
                            ansible-playbook -i inventory site.yml \\
                                --tags "rollback,backend" \\
                                --extra-vars "rollback_version=previous" \\
                                --limit backend \\
                                --timeout 180 || echo "Rollback failed - manual intervention required"
                        """
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
    }
}