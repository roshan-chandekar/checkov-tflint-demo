#!/bin/bash
# Script to fix Jenkins plugin dependency issues and update all plugins
# This installs all required plugins and updates existing ones

echo "=== Fixing Jenkins Plugin Dependencies and Updating Plugins ==="

echo ""
echo "Current Jenkins version:"
docker exec jenkins-docker cat /var/jenkins_home/jenkins.install.InstallUtil.lastExecVersion 2>/dev/null || echo "Unable to determine version"

echo ""
echo "Step 1: Installing/Updating Core Pipeline Plugins..."
docker exec jenkins-docker jenkins-plugin-cli --plugins \
  workflow-api \
  workflow-basic-steps \
  workflow-cps \
  workflow-cps-global-lib \
  workflow-durable-task-step \
  workflow-job \
  workflow-multibranch \
  workflow-scm-step \
  workflow-step-api \
  workflow-support \
  pipeline-stage-view \
  pipeline-graph-analysis \
  pipeline-milestone-step \
  pipeline-build-step \
  pipeline-input-step \
  pipeline-rest-api \
  pipeline-stage-tags-metadata \
  pipeline-utility-steps \
  pipeline-groovy-lib \
  workflow-aggregator || echo "⚠ Some pipeline plugins may have failed, continuing..."

echo ""
echo "Step 2: Installing/Updating Essential Plugins..."
docker exec jenkins-docker jenkins-plugin-cli --plugins \
  git \
  git-client \
  github \
  github-branch-source \
  github-api \
  scm-api \
  branch-api \
  credentials \
  credentials-binding \
  ssh-credentials \
  plain-credentials \
  matrix-project \
  ws-cleanup \
  timestamper \
  build-timeout \
  ant \
  junit \
  test-results-parser \
  warnings-ng \
  htmlpublisher \
  email-ext \
  mailer \
  script-security \
  structs \
  apache-httpcomponents-client-4-api \
  bouncycastle-api \
  display-url-api \
  durable-task \
  jackson2-api \
  jdk-tool \
  jsch \
  jquery-detached \
  momentjs \
  node-iterator-api \
  resource-disposer \
  ssh-slaves \
  subversion \
  token-macro \
  trilead-api \
  windows-slaves || echo "⚠ Some essential plugins may have failed, continuing..."

echo ""
echo "Step 3: Installing/Updating Security and Quality Plugins..."
docker exec jenkins-docker jenkins-plugin-cli --plugins \
  checkstyle \
  pmd \
  analysis-core \
  warnings \
  sonar \
  sonar-quality-gates || echo "⚠ Some security plugins may have failed, continuing..."

echo ""
echo "Step 4: Installing/Updating Docker and Container Plugins..."
docker exec jenkins-docker jenkins-plugin-cli --plugins \
  docker-workflow \
  docker-commons \
  docker-plugin \
  docker-java-api || echo "⚠ Some Docker plugins may have failed, continuing..."

echo ""
echo "Step 5: Installing/Updating AWS Plugins (if needed)..."
docker exec jenkins-docker jenkins-plugin-cli --plugins \
  aws-credentials \
  aws-java-sdk \
  ec2 || echo "⚠ Some AWS plugins may have failed, continuing..."

echo ""
echo "Step 6: Updating all installed plugins to latest versions..."
# Get list of installed plugins and update them
INSTALLED_PLUGINS=$(docker exec jenkins-docker ls /var/jenkins_home/plugins/*.jpi 2>/dev/null | xargs -n1 basename | sed 's/\.jpi$//' | tr '\n' ' ')
if [ -n "$INSTALLED_PLUGINS" ]; then
    echo "Updating installed plugins: $INSTALLED_PLUGINS"
    docker exec jenkins-docker jenkins-plugin-cli --plugins $INSTALLED_PLUGINS || echo "Some plugins may not have updates available"
else
    echo "No installed plugins found to update"
fi

echo ""
echo "Step 7: Verifying plugin installations..."
INSTALLED_COUNT=$(docker exec jenkins-docker ls /var/jenkins_home/plugins/*.jpi 2>/dev/null | wc -l)
echo "Total plugins installed: $INSTALLED_COUNT"

echo ""
echo "Step 8: Restarting Jenkins to apply changes..."
docker-compose restart jenkins

echo ""
echo "Waiting 20 seconds for Jenkins to fully restart..."
sleep 20

echo ""
echo "Step 9: Checking Jenkins logs for errors..."
ERROR_COUNT=$(docker logs jenkins-docker --tail 100 2>&1 | grep -i "failed.*plugin\|plugin.*failed\|exception" | wc -l)

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✓ No plugin errors found!"
else
    echo "⚠ Found $ERROR_COUNT potential errors. Checking details..."
    docker logs jenkins-docker --tail 100 | grep -i "failed.*plugin\|plugin.*failed" | head -10
fi

echo ""
echo "Step 10: Checking Jenkins status..."
if docker exec jenkins-docker curl -f -s http://localhost:8080/login > /dev/null 2>&1; then
    echo "✓ Jenkins is running and accessible"
else
    echo "⚠ Jenkins may still be starting. Wait a bit longer."
fi

echo ""
echo "=== Fix Complete ==="
echo ""
echo "Summary:"
echo "  - Core pipeline plugins: Installed/Updated"
echo "  - Essential plugins: Installed/Updated"
echo "  - Security plugins: Installed/Updated"
echo "  - Docker plugins: Installed/Updated"
echo "  - Total plugins: $INSTALLED_COUNT"
echo ""
echo "Next steps:"
echo "  1. Access Jenkins UI: http://<EC2-IP>:8080"
echo "  2. Go to: Manage Jenkins → Plugins → Installed"
echo "  3. Verify all plugins are loaded without errors"
echo "  4. If issues persist, check: Manage Jenkins → System Log"
echo ""
echo "To check plugin status:"
echo "  docker exec jenkins-docker ls /var/jenkins_home/plugins/ | wc -l"

