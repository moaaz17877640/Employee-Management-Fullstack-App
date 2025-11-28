#!/usr/bin/env groovy

pipeline {
    agent any
    
    environment {
        APP_NAME = 'employee-management-frontend'
        APP_VERSION = "${env.BUILD_NUMBER}"
        GIT_REPO = 'https://github.com/hoangsonww/Employee-Management-Fullstack-App.git'
        NODE_VERSION = '18'
        REACT_APP_API_URL = '/api'
        REACT_APP_ENVIRONMENT = 'production'
        
        // Enhanced Ansible Configuration
        ANSIBLE_INVENTORY = '../test/ansible/inventory'
        ANSIBLE_PLAYBOOK_DIR = '../test/ansible'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        SSH_KEY_PATH = '../test/Key.pem'
    }
    
    tools {
        nodejs "NodeJS-${env.NODE_VERSION}"
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 20, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout Code') {
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
        
        stage('Install Dependencies') {
            steps {
                dir('frontend') {
                    echo "📦 Installing npm dependencies"
                    sh 'npm ci'
                }
            }
        }
        
        stage('Build React Production Bundle') {
            steps {
                dir('frontend') {
                    echo "🏗️ Building React application for production"
                    
                    // Create production environment file
                    writeFile(
                        file: '.env.production',
                        text: """
                            REACT_APP_API_URL=${env.REACT_APP_API_URL}
                            REACT_APP_ENVIRONMENT=${env.REACT_APP_ENVIRONMENT}
                            REACT_APP_VERSION=${env.APP_VERSION}
                            GENERATE_SOURCEMAP=false
                        """.stripIndent()
                    )
                    
                    sh 'npm run build'
                    sh 'ls -la build/'
                    
                    // Archive build artifacts
                    tar(
                        file: "frontend-build-${env.BUILD_NUMBER}.tar.gz",
                        archive: true,
                        dir: 'build'
                    )
                }
            }
        }
        
        stage('Deploy Build Files to LB Server (Ansible)') {
            when {
                branch 'master'
            }
            steps {
                echo "🚀 Deploying React frontend to Load Balancer with zero-downtime"
                script {
                    sh """
                        # Set up SSH key permissions
                        chmod 400 ${SSH_KEY_PATH}
                        
                        cd ${ANSIBLE_PLAYBOOK_DIR}
                        
                        # Pre-deployment validation for load balancer
                        echo "🔍 Running pre-deployment validation for load balancer..."
                        ansible-playbook -i inventory pre-deployment-check.yml -v --limit loadbalancer
                        
                        # Deploy frontend using roles-based system
                        echo "📦 Deploying frontend build to load balancer..."
                        ansible-playbook -i inventory roles-playbook.yml \\
                            --limit loadbalancer \\
                            --extra-vars "app_version=${env.APP_VERSION}" \\
                            --extra-vars "build_number=${env.BUILD_NUMBER}" \\
                            --extra-vars "deployment_strategy=frontend_only" \\
                            --tags "frontend,loadbalancer" \\
                            -v
                        
                        # Post-deployment validation
                        echo "✅ Running post-deployment validation..."
                        ansible-playbook -i inventory post-deployment-validation.yml \\
                            --limit loadbalancer \\
                            -v
                    """
                }
                echo "✅ Frontend deployment completed successfully with zero downtime"
            }
        }
    }
    
    post {
        always {
            echo "🧹 Cleaning up workspace"
            cleanWs()
        }
        
        success {
            echo "✅ Frontend CI/CD pipeline completed successfully!"
        }
        
        failure {
            echo "❌ Frontend CI/CD pipeline failed!"
        }
    }
}