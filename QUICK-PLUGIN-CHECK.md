# Quick Plugin Verification Guide

## Verify Plugins Are Installed

### Option 1: Use Verification Script (Recommended)

```bash
# On your EC2 instance
./verify-jenkins-plugins.sh
```

This will check:
- ✓ Jenkins is running
- ✓ Critical plugins are installed
- ✓ No plugin errors in logs
- ✓ No dependency issues

### Option 2: Manual Verification

```bash
# 1. Check plugin count
docker exec jenkins-docker ls /var/jenkins_home/plugins/*.jpi | wc -l
# Should show 50+ plugins

# 2. Check for critical plugins
docker exec jenkins-docker ls /var/jenkins_home/plugins/ | grep -E "workflow-aggregator|pipeline-groovy-lib|git|matrix-project"

# 3. Check for errors
docker logs jenkins-docker --tail 100 | grep -i "failed.*plugin"

# 4. Check Jenkins UI
# Go to: Manage Jenkins → Plugins → Installed
# Should show all plugins without errors
```

### Option 3: Via Jenkins UI

1. **Access Jenkins**: http://<EC2-IP>:8080
2. **Go to**: Manage Jenkins → Plugins → Installed
3. **Check**:
   - All plugins show "Enabled" status
   - No red error indicators
   - Pipeline plugin is installed
   - Git plugin is installed

## Expected Results

After running `fix-jenkins-plugins.sh`, you should see:

- **50+ plugins installed** (minimum)
- **No "Failed Loading plugin" errors** in logs
- **All critical plugins present**:
  - workflow-aggregator (Pipeline)
  - workflow-api
  - pipeline-groovy-lib
  - git
  - matrix-project
  - ws-cleanup

## If Plugins Are Missing

If verification shows missing plugins:

```bash
# Re-run the fix script
./fix-jenkins-plugins.sh

# Or install specific plugin
docker exec jenkins-docker jenkins-plugin-cli --plugins <plugin-name>

# Restart Jenkins
docker-compose restart jenkins
```

## If Errors Persist

1. **Check logs**:
   ```bash
   docker logs jenkins-docker --tail 200
   ```

2. **Check plugin compatibility**:
   - Some plugins may not be compatible with your Jenkins version
   - Check: Manage Jenkins → System Information → Plugin Versions

3. **Remove problematic plugins**:
   ```bash
   docker exec jenkins-docker rm -rf /var/jenkins_home/plugins/<problematic-plugin>*
   docker-compose restart jenkins
   ```

## Quick Status Check

```bash
# One-liner to check everything
echo "Plugins: $(docker exec jenkins-docker ls /var/jenkins_home/plugins/*.jpi 2>/dev/null | wc -l)" && \
echo "Errors: $(docker logs jenkins-docker --tail 100 2>&1 | grep -i 'failed.*plugin' | wc -l)" && \
docker exec jenkins-docker curl -f -s http://localhost:8080/login > /dev/null && echo "Jenkins: Running" || echo "Jenkins: Not responding"
```

