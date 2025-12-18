# Fresh Jenkins Setup Guide

## Overview

This guide helps you start with a completely fresh Jenkins instance, removing all old data, plugins, and configurations.

## Quick Start

### Option 1: Use the Automated Script (Recommended)

```bash
# On your EC2 instance
./fresh-jenkins-start.sh
```

The script will:
1. Stop and remove Jenkins container
2. Backup old data (just in case)
3. Remove old Jenkins data
4. Pull fresh Jenkins image
5. Start new Jenkins instance
6. Show initial admin password

### Option 2: Manual Steps

```bash
# 1. Stop Jenkins
docker-compose stop jenkins
docker-compose rm -f jenkins

# 2. Backup old data (optional but recommended)
sudo cp -r /var/lib/jenkins /tmp/jenkins-backup-$(date +%Y%m%d)

# 3. Remove old Jenkins data
sudo rm -rf /var/lib/jenkins

# 4. Remove Jenkins Docker volume (if using volume)
docker volume rm checkov-tflint-demo_jenkins_data 2>/dev/null || true

# 5. Pull fresh image
docker-compose pull jenkins

# 6. Start fresh Jenkins
docker-compose up -d jenkins

# 7. Get initial password
docker exec jenkins-docker cat /var/jenkins_home/secrets/initialAdminPassword
```

## What Changed

### docker-compose.yml Updates

- **Before**: Mounted `/var/lib/jenkins` from host (used old data)
- **After**: Uses Docker volume `jenkins_data` (fresh data, isolated)

### Benefits

- ✅ Clean start - no corrupted plugins or jobs
- ✅ Isolated data - Jenkins data in Docker volume
- ✅ Easy cleanup - just remove volume to start over
- ✅ No host file conflicts

## Initial Setup

After starting fresh Jenkins:

1. **Access Jenkins**: http://<EC2-IP>:8080

2. **Unlock Jenkins**:
   - Enter initial admin password (shown by script)
   - Or get it: `docker exec jenkins-docker cat /var/jenkins_home/secrets/initialAdminPassword`

3. **Install Plugins**:
   - Choose "Install suggested plugins" (recommended)
   - Or "Select plugins to install" (custom)
   - Wait for installation to complete

4. **Create Admin User**:
   - Enter username, password, email
   - Or skip to continue as admin

5. **Configure Jenkins**:
   - Jenkins URL: http://<EC2-IP>:8080
   - Save and Finish

## Install Required Plugins

After initial setup, install all required plugins:

```bash
# Run the plugin installation script
./fix-jenkins-plugins.sh
```

Or install via Jenkins UI:
- Manage Jenkins → Plugins → Available
- Search and install: Pipeline, Git, etc.

## Create Your First Job

1. **New Item** → **Pipeline**
2. **Pipeline** → **Definition**: Pipeline script from SCM
3. **SCM**: Git
4. **Repository URL**: Your GitHub repo
5. **Script Path**: `Jenkinsfile`
6. **Save** and **Build Now**

## Managing Jenkins Data

### View Jenkins Data Location

```bash
# Check volume location
docker volume inspect checkov-tflint-demo_jenkins_data

# Access Jenkins data
docker exec -it jenkins-docker ls -la /var/jenkins_home
```

### Backup Jenkins Data

```bash
# Backup to host
docker run --rm -v checkov-tflint-demo_jenkins_data:/data -v $(pwd):/backup \
  ubuntu tar czf /backup/jenkins-backup-$(date +%Y%m%d).tar.gz -C /data .
```

### Restore Jenkins Data

```bash
# Stop Jenkins
docker-compose stop jenkins

# Restore from backup
docker run --rm -v checkov-tflint-demo_jenkins_data:/data -v $(pwd):/backup \
  ubuntu tar xzf /backup/jenkins-backup-YYYYMMDD.tar.gz -C /data

# Start Jenkins
docker-compose up -d jenkins
```

### Remove Jenkins Data (Start Over)

```bash
# Stop Jenkins
docker-compose stop jenkins
docker-compose rm -f jenkins

# Remove volume (deletes all data)
docker volume rm checkov-tflint-demo_jenkins_data

# Start fresh
docker-compose up -d jenkins
```

## Troubleshooting

### Jenkins Won't Start

```bash
# Check logs
docker logs jenkins-docker --tail 100

# Check if port is in use
sudo netstat -tlnp | grep 8080

# Check disk space
df -h
```

### Can't Access Jenkins

1. **Check security group** - Port 8080 must be open
2. **Check Jenkins is running**: `docker ps | grep jenkins`
3. **Check logs**: `docker logs jenkins-docker`
4. **Get IP**: `curl http://169.254.169.254/latest/meta-data/public-ipv4`

### Forgot Admin Password

```bash
# Get initial password
docker exec jenkins-docker cat /var/jenkins_home/secrets/initialAdminPassword

# Or reset admin password via script console
# Manage Jenkins → Script Console → Run:
# hudson.model.User.get('admin').setPassword('newpassword')
```

## Migration from Old Setup

If you want to use your old Jenkins data:

1. **Update docker-compose.yml**:
   ```yaml
   volumes:
     - /var/lib/jenkins:/var/jenkins_home:rw  # Use old data
   ```

2. **Remove volume mount** (comment out jenkins_data)

3. **Restart**: `docker-compose up -d jenkins`

## Best Practices

1. **Regular Backups**: Backup Jenkins data weekly
2. **Version Control**: Store Jenkinsfiles in Git
3. **Plugin Management**: Keep plugins updated
4. **Monitor Disk**: Watch disk usage
5. **Security**: Change default password, use tokens

## Next Steps

After fresh setup:

1. ✅ Install required plugins
2. ✅ Configure Git credentials
3. ✅ Create pipeline job
4. ✅ Test pipeline execution
5. ✅ Set up build triggers
6. ✅ Configure notifications

