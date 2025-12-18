#!/bin/bash
# Script to verify Jenkins plugins are installed correctly

echo "=== Jenkins Plugin Verification ==="
echo ""

echo "Step 1: Checking Jenkins Status..."
if docker exec jenkins-docker curl -f -s http://localhost:8080/login > /dev/null 2>&1; then
    echo "✓ Jenkins is running and accessible"
else
    echo "⚠ Jenkins is not responding. It may still be starting."
    exit 1
fi

echo ""
echo "Step 2: Counting Installed Plugins..."
PLUGIN_COUNT=$(docker exec jenkins-docker ls /var/jenkins_home/plugins/*.jpi 2>/dev/null | wc -l)
echo "Total plugins installed: $PLUGIN_COUNT"

echo ""
echo "Step 3: Checking Critical Plugins..."
CRITICAL_PLUGINS=(
    "workflow-aggregator"
    "workflow-api"
    "pipeline-groovy-lib"
    "git"
    "matrix-project"
    "ws-cleanup"
    "credentials"
    "scm-api"
)

MISSING_PLUGINS=()
for plugin in "${CRITICAL_PLUGINS[@]}"; do
    if docker exec jenkins-docker test -f "/var/jenkins_home/plugins/${plugin}.jpi" 2>/dev/null; then
        echo "  ✓ $plugin - Installed"
    else
        echo "  ✗ $plugin - MISSING"
        MISSING_PLUGINS+=("$plugin")
    fi
done

echo ""
echo "Step 4: Checking Jenkins Logs for Plugin Errors..."
ERROR_COUNT=$(docker logs jenkins-docker --tail 200 2>&1 | grep -i "failed.*plugin\|plugin.*failed\|CannotResolveClassException.*plugin" | wc -l)

if [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✓ No plugin errors found in recent logs"
else
    echo "⚠ Found $ERROR_COUNT plugin-related errors:"
    docker logs jenkins-docker --tail 200 2>&1 | grep -i "failed.*plugin\|plugin.*failed\|CannotResolveClassException.*plugin" | head -5
fi

echo ""
echo "Step 5: Checking for Dependency Issues..."
DEPENDENCY_ERRORS=$(docker logs jenkins-docker --tail 200 2>&1 | grep -i "dependency\|missing.*plugin\|required.*plugin" | wc -l)

if [ "$DEPENDENCY_ERRORS" -eq 0 ]; then
    echo "✓ No dependency errors found"
else
    echo "⚠ Found $DEPENDENCY_ERRORS dependency-related messages:"
    docker logs jenkins-docker --tail 200 2>&1 | grep -i "dependency\|missing.*plugin\|required.*plugin" | head -5
fi

echo ""
echo "Step 6: Listing All Installed Plugins..."
echo "Installed plugins (first 20):"
docker exec jenkins-docker ls /var/jenkins_home/plugins/*.jpi 2>/dev/null | xargs -n1 basename | sed 's/\.jpi$//' | head -20
TOTAL=$(docker exec jenkins-docker ls /var/jenkins_home/plugins/*.jpi 2>/dev/null | wc -l)
if [ "$TOTAL" -gt 20 ]; then
    echo "... and $((TOTAL - 20)) more plugins"
fi

echo ""
echo "=== Verification Summary ==="
echo ""
if [ ${#MISSING_PLUGINS[@]} -eq 0 ] && [ "$ERROR_COUNT" -eq 0 ]; then
    echo "✓ SUCCESS: All critical plugins are installed and no errors found!"
    echo ""
    echo "Jenkins is ready to use. You can:"
    echo "  1. Access Jenkins UI: http://<EC2-IP>:8080"
    echo "  2. Create/run your pipeline jobs"
    echo "  3. Check plugin status: Manage Jenkins → Plugins → Installed"
    exit 0
else
    echo "⚠ WARNING: Some issues found:"
    if [ ${#MISSING_PLUGINS[@]} -gt 0 ]; then
        echo "  - Missing plugins: ${MISSING_PLUGINS[*]}"
        echo "    Run: ./fix-jenkins-plugins.sh to install missing plugins"
    fi
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "  - Plugin errors found in logs"
        echo "    Check: docker logs jenkins-docker --tail 100"
    fi
    exit 1
fi

