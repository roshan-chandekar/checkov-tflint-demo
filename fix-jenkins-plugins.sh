#!/bin/bash
# Script to fix Jenkins plugin dependency issues

echo "=== Fixing Jenkins Plugin Dependencies ==="

echo ""
echo "Current Jenkins version:"
docker exec jenkins-docker cat /var/jenkins_home/jenkins.install.InstallUtil.lastExecVersion 2>/dev/null || echo "Unable to determine version"

echo ""
echo "Installing missing plugin dependencies..."

# Install missing dependencies
docker exec jenkins-docker jenkins-plugin-cli --plugins \
  workflow-api \
  pipeline-groovy-lib \
  matrix-project \
  workflow-aggregator \
  ws-cleanup 2>&1 | tee /tmp/plugin-install.log

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Plugins installed successfully"
else
    echo ""
    echo "⚠ Some plugins may have failed. Check /tmp/plugin-install.log"
fi

echo ""
echo "Restarting Jenkins..."
docker-compose restart jenkins

echo ""
echo "Waiting 15 seconds for Jenkins to restart..."
sleep 15

echo ""
echo "Checking Jenkins logs for plugin errors..."
docker logs jenkins-docker --tail 50 | grep -i "failed.*plugin\|plugin.*failed" || echo "No plugin errors found"

echo ""
echo "=== Fix Complete ==="
echo "Check Jenkins UI to verify plugins are loaded:"
echo "  Manage Jenkins → Plugins → Installed"
echo ""
echo "If errors persist, install plugins manually via Jenkins UI"

