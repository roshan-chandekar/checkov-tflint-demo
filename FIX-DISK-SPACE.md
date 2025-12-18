# Fix Jenkins Disk Space Warning

## Issue
Jenkins is marking the node offline due to lack of disk space:
```
WARNING: Making Built-In Node offline temporarily due to the lack of disk space
```

## Quick Fix Steps

### 1. Check Disk Space on EC2

```bash
# Check overall disk usage
df -h

# Check Docker disk usage
docker system df

# Check Jenkins home directory size
du -sh /var/lib/jenkins
```

### 2. Clean Up Docker

```bash
# Remove unused containers, networks, images
docker system prune -a

# Remove unused volumes (be careful - this removes unused volumes)
docker volume prune
```

### 3. Clean Up Jenkins

#### Option A: Via Jenkins UI (Recommended)
1. Go to: **Manage Jenkins → System**
2. Find **Global Build Discarders** or **Discard Old Builds**
3. Configure:
   - Keep only last 10 builds
   - Discard artifacts older than 7 days
   - Discard builds older than 30 days

#### Option B: Via Command Line

```bash
# Clean up old build artifacts (keep last 10)
# This requires Jenkins CLI or manual cleanup

# Check build directories size
du -sh /var/lib/jenkins/jobs/*/builds

# Remove old builds manually (keep last 10)
# Be careful - backup first!
```

### 4. Increase Disk Space Threshold in Jenkins

If you have enough space but Jenkins threshold is too strict:

1. Go to: **Manage Jenkins → Configure System**
2. Find **Disk Space Monitor** or **Temporary Directory**
3. Adjust the threshold:
   - Default: 1GB free space required
   - Increase to: 500MB or 2GB (depending on your needs)

### 5. Clean Up Logs

```bash
# Clean Jenkins logs (keep last 7 days)
find /var/lib/jenkins/logs -type f -mtime +7 -delete

# Clean Docker logs
sudo journalctl --vacuum-time=7d
```

### 6. Clean Up Workspace

```bash
# Clean up workspace directories (be careful!)
# Only if you're sure you don't need old workspaces
find /var/lib/jenkins/workspace -type d -mtime +30 -exec rm -rf {} \;
```

## Permanent Solution: Configure Build Discarders

### In Jenkinsfile (Recommended)

Add to your pipeline:

```groovy
options {
    // Discard old builds
    buildDiscarder(logRotator(
        numToKeepStr: '10',
        daysToKeepStr: '7',
        artifactNumToKeepStr: '5',
        artifactDaysToKeepStr: '3'
    ))
}
```

### Or in Job Configuration

1. Open your job
2. Go to **Configure**
3. Check **Discard old builds**
4. Set:
   - **Days to keep builds**: 7
   - **Max # of builds to keep**: 10
   - **Days to keep artifacts**: 3
   - **Max # of builds to keep with artifacts**: 5

## Check EC2 Instance Disk

```bash
# Check if you need to resize EBS volume
df -h

# If / is full, you may need to:
# 1. Resize EBS volume in AWS Console
# 2. Resize filesystem: sudo resize2fs /dev/xvda1
```

## Monitor Disk Usage

```bash
# Create a monitoring script
cat > /usr/local/bin/check-disk.sh << 'EOF'
#!/bin/bash
echo "=== Disk Usage ==="
df -h | grep -E "Filesystem|/$"
echo ""
echo "=== Docker Usage ==="
docker system df
echo ""
echo "=== Jenkins Home Size ==="
du -sh /var/lib/jenkins 2>/dev/null || echo "Jenkins home not found"
EOF

chmod +x /usr/local/bin/check-disk.sh

# Run it
/usr/local/bin/check-disk.sh
```

## Quick Commands Summary

```bash
# Full cleanup (run these one by one, check after each)

# 1. Docker cleanup
docker system prune -a -f

# 2. Check disk space
df -h

# 3. Check Jenkins size
du -sh /var/lib/jenkins

# 4. If still low, clean old Jenkins builds (backup first!)
# This is destructive - be careful!
```

## After Cleanup

1. **Restart Jenkins** (if needed):
   ```bash
   docker-compose restart jenkins
   ```

2. **Verify node is online**:
   - Go to: **Manage Jenkins → Nodes**
   - Built-In Node should show "Online"

3. **Monitor**:
   - Check disk space regularly
   - Set up build discarders
   - Monitor with the script above

## Prevention

1. **Always configure build discarders** in Jenkinsfiles
2. **Set up automated cleanup** via cron job
3. **Monitor disk usage** regularly
4. **Use appropriate EBS volume size** (at least 20GB for Jenkins)

