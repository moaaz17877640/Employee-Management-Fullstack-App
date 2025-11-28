pipeline {
    agent any
    
    environment {
        APP_NAME = 'employee-management'
        APP_VERSION = "${env.BUILD_NUMBER}"
        
        // Java Configuration for Backend
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
        MAVEN_HOME = '/usr/share/maven'
        
        // Node.js Configuration for Frontend
        NODE_VERSION = '18'
        
        // Database Configuration
        MYSQL_HOST = 'localhost'
        MYSQL_PORT = '3306'
        MYSQL_DB = 'employee_management'
        MYSQL_USER = 'empapp'
        MYSQL_PASSWORD = 'emppass123'
        MYSQL_SSL_MODE = 'DISABLED'
        MONGO_URI = 'mongodb://localhost:27017/employee_management'
        
        PATH = "/usr/bin:/usr/local/bin:${JAVA_HOME}/bin:${env.PATH}"
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "🔄 Checking out repository"
                checkout scm
            }
        }
        
        stage('Setup Environment') {
            steps {
                echo "⚙️ Setting up build environment"
                script {
                    sh '''
                        echo "Java Version:"
                        java -version || echo "Java not found"
                        echo "Maven Version:"
                        mvn -version || echo "Maven not found"
                        echo "Node Version:"
                        node --version || echo "Node.js not found"
                        echo "NPM Version:"
                        npm --version || echo "npm not found"
                    '''
                }
            }
        }
        
        stage('Build Backend') {
            steps {
                dir('backend') {
                    echo "🏗️ Building Spring Boot backend"
                    script {
                        // Create config.properties
                        writeFile(
                            file: 'config.properties',
                            text: """
                                MYSQL_HOST=${env.MYSQL_HOST}
                                MYSQL_PORT=${env.MYSQL_PORT}
                                MYSQL_DB=${env.MYSQL_DB}
                                MYSQL_USER=${env.MYSQL_USER}
                                MYSQL_PASSWORD=${env.MYSQL_PASSWORD}
                                MYSQL_SSL_MODE=${env.MYSQL_SSL_MODE}
                                MONGO_URI=${env.MONGO_URI}
                            """.stripIndent()
                        )
                    }
                    sh '''
                        mvn clean compile
                        mvn test -Dmaven.test.failure.ignore=true
                        mvn package -DskipTests
                    '''
                }
            }
        }
        
        stage('Build Frontend') {
            steps {
                dir('frontend') {
                    echo "🎨 Building React frontend"
                    script {
                        // Create environment file for frontend
                        writeFile(
                            file: '.env.production',
                            text: """
                                REACT_APP_API_URL=/api
                                REACT_APP_ENVIRONMENT=production
                                REACT_APP_VERSION=${env.APP_VERSION}
                                GENERATE_SOURCEMAP=false
                            """.stripIndent()
                        )
                    }
                    sh '''
                        # Clear npm cache and remove existing dependencies
                        npm cache clean --force || true
                        rm -rf node_modules package-lock.json || true
                        
                        # Install dependencies
                        npm install --legacy-peer-deps --timeout=300000
                        
                        # Build production bundle
                        npm run build
                    '''
                }
            }
        }
        
        stage('Archive Artifacts') {
            parallel {
                stage('Archive Backend JAR') {
                    steps {
                        dir('backend') {
                            archiveArtifacts(
                                artifacts: 'target/*.jar',
                                fingerprint: true,
                                allowEmptyArchive: false
                            )
                        }
                    }
                }
                stage('Archive Frontend Build') {
                    steps {
                        dir('frontend') {
                            script {
                                sh "tar -czf build-${env.BUILD_NUMBER}.tar.gz -C build ."
                                archiveArtifacts(
                                    artifacts: "build-${env.BUILD_NUMBER}.tar.gz",
                                    fingerprint: true,
                                    allowEmptyArchive: false
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    post {
        success {
            echo "✅ Build completed successfully!"
        }
        failure {
            echo "❌ Build failed!"
        }
        always {
            echo "🧹 Cleaning up workspace"
            cleanWs()
        }
    }
}
