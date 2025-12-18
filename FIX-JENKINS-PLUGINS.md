# Fix Jenkins Plugin Dependency Errors

## Current Issues

Jenkins is running but these plugins failed to load:
1. **Pipeline Plugin** - Missing dependencies: `workflow-api`, `pipeline-groovy-lib`
2. **Workspace Cleanup Plugin** - Missing dependency: `matrix-project`

## Why This Happened

- Plugins installed but dependencies missing
- Plugin versions incompatible with Jenkins version
- Plugin installation incomplete

## Fix Options

### Option 1: Fix via Jenkins UI (Recommended)

1. **Access Jenkins**: http://<EC2-IP>:8080
2. **Go to**: Manage Jenkins → Plugins
3. **Available** tab → Search and install:
   - `workflow-api`
   - `pipeline-groovy-lib`
   - `matrix-project`
4. **Installed** tab → Check for updates
5. **Restart Jenkins** when prompted

### Option 2: Fix via Jenkins CLI

```bash
# Install missing dependencies
docker exec jenkins-docker jenkins-plugin-cli --plugins \
  workflow-api:latest \
  pipeline-groovy-lib:latest \
  matrix-project:latest

# Restart Jenkins
docker-compose restart jenkins
```

### Option 3: Update All Plugins

```bash
# Update all plugins via CLI
docker exec jenkins-docker jenkins-plugin-cli --available-updates

# Or update specific plugins
docker exec jenkins-docker jenkins-plugin-cli --plugins \
  workflow-aggregator:latest \
  ws-cleanup:latest \
  matrix-project:latest
```

### Option 4: Reinstall Plugins

If plugins are corrupted:

```bash
# Remove plugin directories
docker exec jenkins-docker rm -rf /var/jenkins_home/plugins/workflow-aggregator*
docker exec jenkins-docker rm -rf /var/jenkins_home/plugins/ws-cleanup*
docker exec jenkins-docker rm -rf /var/jenkins_home/plugins/matrix-project*

# Restart Jenkins (will reinstall on startup if configured)
docker-compose restart jenkins

# Then install via UI or CLI
```

## Quick Fix Script

```bash
# On your EC2 instance, run:
docker exec jenkins-docker jenkins-plugin-cli --plugins \
  workflow-api \
  pipeline-groovy-lib \
  matrix-project \
  workflow-aggregator \
  ws-cleanup

docker-compose restart jenkins
```

## Verify Fix

After fixing, check logs:

```bash
docker logs jenkins-docker --tail 100 | grep -i "failed\|error\|plugin"
# Should NOT see "Failed Loading plugin" errors
```

## If Still Failing

### Check Plugin Compatibility

```bash
# Check Jenkins version
docker exec jenkins-docker cat /var/jenkins_home/jenkins.install.InstallUtil.lastExecVersion

# Check installed plugins
docker exec jenkins-docker ls -la /var/jenkins_home/plugins/ | grep -E "workflow|pipeline|matrix"
```

### Manual Plugin Installation

1. **Download plugins manually**:
   - Go to: https://plugins.jenkins.io/
   - Download: workflow-api, pipeline-groovy-lib, matrix-project
   - Upload via: Manage Jenkins → Plugins → Advanced → Upload Plugin

2. **Or use wget**:
   ```bash
   docker exec jenkins-docker wget -P /var/jenkins_home/plugins/ \
     https://updates.jenkins.io/download/plugins/workflow-api/latest/workflow-api.hpi \
     https://updates.jenkins.io/download/plugins/pipeline-groovy-lib/latest/pipeline-groovy-lib.hpi \
     https://updates.jenkins.io/download/plugins/matrix-project/latest/matrix-project.hpi
   
   docker-compose restart jenkins
   ```

## Prevention

1. **Always install plugins via UI** - ensures dependencies are installed
2. **Use plugin manager** - automatically resolves dependencies
3. **Keep plugins updated** - check for updates regularly
4. **Test after updates** - verify plugins work after updates

## Impact

- **Current Impact**: Pipeline jobs may not work properly
- **Jenkins Status**: Still running, but some features unavailable
- **Fix Priority**: Medium (functionality limited but not critical)

## Required Plugins for Your Pipeline

Based on your Jenkinsfile, you need:
- ✅ Pipeline plugin (workflow-aggregator)
- ✅ Git plugin (for checkout)
- ✅ Workspace cleanup (optional but recommended)

Make sure these are installed with all dependencies.

