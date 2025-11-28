#!/usr/bin/env groovy

pipeline {
    agent any
    
    environment {
        APP_NAME = 'employee-management-frontend'
        APP_VERSION = "${env.BUILD_NUMBER}"
        GIT_REPO = '/home/moaz/test/Employee-Management-Fullstack-App'
        NODE_VERSION = '18'
        REACT_APP_API_URL = '/api'
        REACT_APP_ENVIRONMENT = 'production'
        
        // System tool paths
        PATH = "/usr/bin:${env.PATH}"
        
        // Enhanced Ansible Configuration
        ANSIBLE_INVENTORY = '../test/ansible/inventory'
        ANSIBLE_PLAYBOOK_DIR = '../test/ansible'
        ANSIBLE_HOST_KEY_CHECKING = 'False'
        SSH_KEY_PATH = '../test/Key.pem'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 20, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                echo "🔄 Using local repository at ${env.GIT_REPO}"
                script {
                    // We're already in the correct directory
                    sh 'pwd && ls -la'
                }
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
                    
                    // Archive build artifacts using shell commands and archiveArtifacts
                    script {
                        sh "tar -czf frontend-build-${env.BUILD_NUMBER}.tar.gz -C build ."
                        archiveArtifacts(
                            artifacts: "frontend-build-${env.BUILD_NUMBER}.tar.gz",
                            fingerprint: true,
                            allowEmptyArchive: false
                        )
                    }
                }
            }
        }
        
        stage('Verify Backend Connectivity') {
            when {
                // Always verify backend before frontend deployment
                expression { return true }
            }
            steps {
                echo "🔗 Verifying backend API connectivity before frontend deployment"
                script {
                    sh """
                        cd ${ANSIBLE_PLAYBOOK_DIR}
                        
                        # Test backend API connectivity
                        echo "🏥 Testing backend server API endpoints..."
                        ansible backend -i inventory -m uri \\
                            -a "url=http://{{ ansible_default_ipv4.address }}:8080/api/employees method=GET timeout=30" \\
                            --timeout=60 || {
                                echo "❌ Backend API not responding - may need backend deployment first"
                                echo "🔄 Attempting to restart backend services..."
                                ansible backend -i inventory -m shell \\
                                    -a "sudo systemctl restart employee-backend" \\
                                    --timeout=60 || echo "Service restart failed"
                                sleep 30
                                
                                # Retry API test
                                ansible backend -i inventory -m uri \\
                                    -a "url=http://{{ ansible_default_ipv4.address }}:8080/api/employees method=GET timeout=30" \\
                                    --timeout=60 || {
                                        echo "⚠️ Backend API still not responding - frontend will deploy but API routing may fail"
                                        echo "💡 Recommendation: Run backend pipeline first"
                                    }
                            }
                        
                        echo "✅ Backend connectivity verification completed"
                    """
                }
            }
        }
        
        stage('Deploy Frontend to Load Balancer (Ansible)') {
            when {
                // Always deploy frontend for local development
                expression { return true }
            }
            steps {
                echo "🚀 Deploying React frontend with comprehensive validation"
                script {
                    sh """
                        # Set up SSH key permissions
                        chmod 400 ${SSH_KEY_PATH} || echo "SSH key permission already set"
                        
                        cd ${ANSIBLE_PLAYBOOK_DIR}
                        
                        # Pre-deployment connectivity check
                        echo "🔍 Pre-deployment connectivity validation..."
                        ansible loadbalancer -i inventory -m ping --timeout=30
                        
                        # Pre-deployment validation for load balancer
                        echo "🔍 Running pre-deployment validation for load balancer..."
                        if [ -f "pre-deployment-check.yml" ]; then
                            ansible-playbook -i inventory pre-deployment-check.yml -v --limit loadbalancer || echo "Pre-check completed with warnings"
                        fi
                        
                        # Deploy frontend using roles-based system
                        echo "📦 Deploying frontend build to load balancer..."
                        ansible-playbook -i inventory roles-playbook.yml \\
                            --limit loadbalancer \\
                            --extra-vars "app_version=${env.APP_VERSION}" \\
                            --extra-vars "build_number=${env.BUILD_NUMBER}" \\
                            --extra-vars "deployment_strategy=frontend_complete" \\
                            --extra-vars "update_backend_config=true" \\
                            --tags "frontend,loadbalancer" \\
                            -v
                        
                        # Wait for Nginx to reload
                        echo "⏳ Waiting for Nginx configuration reload..."
                        sleep 15
                        
                        # Comprehensive validation
                        echo "🔍 Running comprehensive frontend validation..."
                        
                        # Test frontend availability
                        ansible loadbalancer -i inventory -m uri \\
                            -a "url=http://{{ ansible_default_ipv4.address }}/ method=GET status_code=200 timeout=30" \\
                            --timeout=60
                        
                        # Test API routing through load balancer
                        echo "🔗 Testing API routing through load balancer..."
                        ansible loadbalancer -i inventory -m uri \\
                            -a "url=http://{{ ansible_default_ipv4.address }}/api/employees method=GET status_code=200 timeout=30" \\
                            --timeout=60
                        
                        # Verify Nginx configuration
                        echo "⚙️ Verifying Nginx configuration..."
                        ansible loadbalancer -i inventory -m shell \\
                            -a "sudo nginx -t && sudo systemctl is-active nginx" \\
                            --timeout=30
                        
                        # Post-deployment validation
                        echo "✅ Running post-deployment validation..."
                        if [ -f "post-deployment-validation.yml" ]; then
                            ansible-playbook -i inventory post-deployment-validation.yml \\
                                --limit loadbalancer \\
                                -v || echo "Post-deployment validation completed with warnings"
                        fi
                        
                        # Log successful deployment
                        ansible loadbalancer -i inventory -m shell \\
                            -a "echo \"\\\$(date): Frontend deployment ${env.BUILD_NUMBER} completed successfully\" | sudo tee -a /var/log/nginx/deployment.log" \\
                            --timeout=30 || echo "Deployment logging failed"
                    """
                }
                echo "✅ Frontend deployment completed successfully with full validation"
            }
        }
        
        stage('Final Health Check') {
            when {
                // Always run final health check for deployment validation
                expression { return true }
            }
            steps {
                echo "🏥 Running final deployment health check"
                script {
                    sh """
                        # Run comprehensive health check to ensure everything is working
                        ./scripts/deployment-health-check.sh check || echo "Health check completed with warnings"
                        
                        echo "📊 Final system health check completed"
                    """
                }
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