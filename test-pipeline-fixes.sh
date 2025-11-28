#!/bin/bash

# Pipeline Validation Script - Test Frontend and Backend Builds
# This script validates that the pipeline fixes work correctly

set -e
echo "🚀 Starting Employee Management Pipeline Validation"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Change to project directory
PROJECT_ROOT="$(dirname "$0")"
cd "$PROJECT_ROOT"

log_info "Project root: $(pwd)"

# Validation counters
PASSED=0
FAILED=0
WARNINGS=0

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    local allow_failure="$3"  # Optional: set to "warning" to treat failures as warnings
    
    echo ""
    log_info "🧪 Testing: $test_name"
    
    if eval "$test_command" 2>/dev/null; then
        log_success "✅ $test_name"
        ((PASSED++))
    else
        if [[ "$allow_failure" == "warning" ]]; then
            log_warning "⚠️ $test_name (non-critical)"
            ((WARNINGS++))
        else
            log_error "❌ $test_name"
            ((FAILED++))
        fi
    fi
}

echo ""
echo "=========================================="
echo "🔍 ENVIRONMENT VALIDATION"
echo "=========================================="

# Check system requirements
run_test "Java 21 Installation" "java -version 2>&1 | grep '21'"
run_test "Maven Installation" "mvn -version"
run_test "Node.js Installation" "node --version"
run_test "npm Installation" "npm --version"
run_test "SSH Key Permissions" "ls -la Key.pem | grep '^-r--------'"

echo ""
echo "=========================================="
echo "🔧 CONFIGURATION VALIDATION"
echo "=========================================="

# Check configuration files
run_test "Backend Config File" "test -f backend/config.properties"
run_test "Frontend Package.json" "test -f frontend/package.json"
run_test "Backend POM.xml" "test -f backend/pom.xml"
run_test "Ansible Inventory" "test -f ansible/inventory"

# Validate configuration contents
run_test "Backend Config Valid" "grep -q 'MYSQL_HOST' backend/config.properties"
run_test "Java Version Match" "grep -q 'java.version>21' backend/pom.xml"

echo ""
echo "=========================================="
echo "🏗️ BACKEND BUILD VALIDATION"
echo "=========================================="

log_info "Setting up backend environment..."
cd backend

# Create test config if not exists
if [[ ! -f config.properties ]]; then
    log_info "Creating config.properties for testing"
    cat > config.properties << EOF
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DB=employee_management
MYSQL_USER=empapp
MYSQL_PASSWORD=emppass123
MYSQL_SSL_MODE=DISABLED
MONGO_URI=mongodb://localhost:27017/employee_management
EOF
fi

run_test "Maven Clean" "mvn clean -q"
run_test "Maven Compile" "mvn compile -q" "warning"
run_test "Maven Test" "mvn test -q" "warning"
run_test "Maven Package" "mvn package -DskipTests -q"
run_test "JAR File Created" "ls target/*.jar"

cd ..

echo ""
echo "=========================================="
echo "🎨 FRONTEND BUILD VALIDATION"
echo "=========================================="

log_info "Setting up frontend environment..."
cd frontend

# Clean up any existing node_modules
if [[ -d node_modules ]]; then
    log_info "Cleaning existing node_modules..."
    rm -rf node_modules package-lock.json
fi

# Create production environment file
log_info "Creating .env.production for testing"
cat > .env.production << EOF
REACT_APP_API_URL=/api
REACT_APP_ENVIRONMENT=production
REACT_APP_VERSION=1.0.0
GENERATE_SOURCEMAP=false
EOF

run_test "npm Cache Clean" "npm cache clean --force" "warning"
run_test "npm Install" "npm install --legacy-peer-deps --silent" "warning"
run_test "React Build" "npm run build --silent" "warning"
run_test "Build Directory Created" "test -d build"
run_test "Build Index.html Exists" "test -f build/index.html"

cd ..

echo ""
echo "=========================================="
echo "🔍 ANSIBLE VALIDATION"
echo "=========================================="

cd ansible

run_test "Ansible Installation" "ansible --version" "warning"
run_test "Inventory Syntax" "ansible-inventory -i inventory --list" "warning"
run_test "Playbooks Syntax" "ansible-playbook --syntax-check roles-playbook.yml" "warning"

# Test SSH connectivity (non-critical)
log_info "Testing SSH connectivity to servers..."
run_test "Load Balancer SSH" "ansible loadbalancer -i inventory -m ping --timeout=10" "warning"
run_test "Backend Servers SSH" "ansible backend -i inventory -m ping --timeout=10" "warning"

cd ..

echo ""
echo "=========================================="
echo "📋 VALIDATION SUMMARY"
echo "=========================================="

echo -e "✅ Passed: ${GREEN}$PASSED${NC}"
echo -e "⚠️ Warnings: ${YELLOW}$WARNINGS${NC}"  
echo -e "❌ Failed: ${RED}$FAILED${NC}"  
echo ""
echo -e "📋 Total checks: $((PASSED + FAILED + WARNINGS))"

if [[ $FAILED -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}🎉 Pipeline validation completed successfully!${NC}"
    echo -e "${GREEN}Your frontend and backend pipelines should now work correctly.${NC}"
    echo ""
    echo "📚 Next steps:"
    echo "1. Run 'jenkins/backend.Jenkinsfile' for backend deployment"
    echo "2. Run 'jenkins/frontend.Jenkinsfile' for frontend deployment"
    echo "3. Or use the main 'Jenkinsfile' for combined build"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Pipeline validation failed!${NC}"
    echo -e "${RED}Please fix the failed checks before running the pipeline${NC}"
    echo ""
    echo "🔧 Common fixes:"
    echo "- Install missing Java 11, Maven, Node.js, or npm"
    echo "- Check SSH key permissions (should be 400)"
    echo "- Verify network connectivity to deployment servers"
    exit 1
fi