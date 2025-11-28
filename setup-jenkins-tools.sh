#!/bin/bash

echo "🔧 Setting up Jenkins Tool Configuration"
echo "======================================="

# Create Jenkins configuration directory
sudo mkdir -p /var/lib/jenkins/tools

# Create tool configurations for Jenkins
cat > /tmp/jenkins-tools-config.xml << 'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<hudson>
  <tool>
    <maven>
      <installations>
        <hudson.tasks.Maven_-MavenInstallation>
          <name>maven</name>
          <home>/usr/share/maven</home>
          <properties/>
        </hudson.tasks.Maven_-MavenInstallation>
      </installations>
    </maven>
  </tool>
  <tool>
    <jdk>
      <installations>
        <hudson.model.JDK>
          <name>java</name>
          <home>/usr/lib/jvm/java-21-openjdk-amd64</home>
          <properties/>
        </hudson.model.JDK>
      </installations>
    </jdk>
  </tool>
  <tool>
    <nodejs>
      <installations>
        <jenkins.plugins.nodejs.tools.NodeJSInstallation>
          <name>nodejs</name>
          <home>/usr/bin</home>
          <properties/>
        </jenkins.plugins.nodejs.tools.NodeJSInstallation>
      </installations>
    </nodejs>
  </tool>
</hudson>
EOF

echo "✅ Jenkins tool configuration created"
echo ""
echo "📋 Manual Configuration Required:"
echo "1. Open Jenkins: http://localhost:8080"
echo "2. Go to: Manage Jenkins → Global Tool Configuration"
echo "3. Configure the following tools:"
echo ""
echo "   📦 Maven:"
echo "   - Name: maven"
echo "   - MAVEN_HOME: /usr/share/maven"
echo ""
echo "   ☕ JDK:"
echo "   - Name: java"
echo "   - JAVA_HOME: /usr/lib/jvm/java-21-openjdk-amd64"
echo ""
echo "   📱 Node.js:"
echo "   - Name: nodejs"
echo "   - Installation directory: /usr/bin"
echo ""
echo "🎯 After configuration, your pipelines will work correctly!"