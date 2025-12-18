# CRITICAL: Disk Space at 99% - Immediate Action Required

## Current Status
- **Disk Usage**: 99% (19G used, 228MB free)
- **Status**: CRITICAL - Jenkins node offline due to disk space

## Immediate Actions (Run These Now!)

### 1. Quick Cleanup Script

```bash
# Make script executable
chmod +x EMERGENCY-DISK-CLEANUP.sh

# Run cleanup
./EMERGENCY-DISK-CLEANUP.sh
```

### 2. Manual Cleanup (If Script Doesn't Work)

```bash
# A. Clean Docker (usually frees most space)
docker system prune -a -f --volumes
docker volume prune -f

# B. Clean APT cache
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove -y

# C. Clean system logs
sudo journalctl --vacuum-time=3d
sudo find /var/log -type f -name "*.log" -mtime +7 -delete
sudo find /var/log -type f -name "*.gz" -delete

# D. Find what's using space
sudo du -h --max-depth=1 / | sort -rh | head -10

# E. Clean temporary files
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*
```

### 3. Check What's Using Space

```bash
# Find largest directories
sudo du -h --max-depth=1 / 2>/dev/null | sort -rh | head -20

# Find large files (>100MB)
sudo find / -type f -size +100M 2>/dev/null | head -20

# Check Docker usage
docker system df -v

# Check specific directories
sudo du -sh /var/lib/docker
sudo du -sh /var/lib/jenkins
sudo du -sh /var/log
sudo du -sh /usr
```

## After Cleanup

### 1. Restart Jenkins

```bash
docker-compose restart jenkins
```

### 2. Verify Disk Space

```bash
df -h
# Should show at least 1-2GB free
```

### 3. Bring Jenkins Node Online

- Go to Jenkins UI: http://<EC2-IP>:8080
- Manage Jenkins → Nodes
- Built-In Node → Configure
- Check "Temporarily take this node offline" is unchecked
- Or restart Jenkins container

## Long-Term Solutions

### Option 1: Resize EBS Volume (Recommended)

1. **In AWS Console:**
   - Go to EC2 → Volumes
   - Select your volume
   - Actions → Modify Volume
   - Increase size (e.g., 19GB → 30GB or 50GB)
   - Wait for optimization to complete

2. **On EC2 Instance:**
   ```bash
   # Check current partition
   lsblk
   
   # Resize filesystem (adjust /dev/xvda1 based on your setup)
   sudo growpart /dev/xvda 1
   sudo resize2fs /dev/xvda1
   
   # Verify
   df -h
   ```

### Option 2: Move Docker/Jenkins to Separate Volume

Create a new EBS volume and mount it:

```bash
# 1. Create and attach new EBS volume in AWS Console
# 2. Format and mount
sudo mkfs -t ext4 /dev/xvdf  # Adjust device name
sudo mkdir /mnt/docker
sudo mount /dev/xvdf /mnt/docker

# 3. Move Docker data
sudo systemctl stop docker
sudo mv /var/lib/docker /mnt/docker/
sudo ln -s /mnt/docker/docker /var/lib/docker
sudo systemctl start docker

# 4. Add to fstab for persistence
echo '/dev/xvdf /mnt/docker ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
```

### Option 3: Configure Automatic Cleanup

Add to crontab:

```bash
# Edit crontab
crontab -e

# Add daily cleanup
0 2 * * * docker system prune -a -f > /dev/null 2>&1
0 3 * * * journalctl --vacuum-time=7d > /dev/null 2>&1
```

## Prevention

1. **Monitor disk usage:**
   ```bash
   # Add to crontab
   0 * * * * df -h | grep "/$" | awk '{if($5+0 > 80) print "WARNING: Disk usage at "$5}'
   ```

2. **Set up CloudWatch alarms** for disk usage > 80%

3. **Use build discarders** (already added to Jenkinsfile)

4. **Regular cleanup:**
   - Weekly Docker cleanup
   - Monthly log rotation
   - Quarterly full system cleanup

## Quick Reference

```bash
# Check disk space
df -h

# Find large files
sudo find / -type f -size +100M 2>/dev/null

# Docker cleanup
docker system prune -a -f

# Log cleanup
sudo journalctl --vacuum-time=7d

# APT cleanup
sudo apt-get clean && sudo apt-get autoremove -y
```

## Expected Results

After cleanup, you should have:
- **At least 1-2GB free** (minimum for Jenkins to work)
- **3-5GB free** (recommended)
- **10GB+ free** (ideal)

## If Still Full After Cleanup

1. **Check for large files:**
   ```bash
   sudo find / -type f -size +500M 2>/dev/null
   ```

2. **Check Docker volumes:**
   ```bash
   docker volume ls
   docker volume inspect <volume-name>
   ```

3. **Consider resizing EBS volume** (see Option 1 above)

4. **Move data to S3** if it's old/archived data

## Emergency: If System Becomes Unresponsive

1. **Stop non-essential services:**
   ```bash
   docker-compose stop sonarqube postgres
   docker-compose stop jenkins
   ```

2. **Free up space quickly:**
   ```bash
   docker system prune -a -f --volumes
   sudo rm -rf /var/log/*.gz
   sudo rm -rf /tmp/*
   ```

3. **Then restart services:**
   ```bash
   docker-compose up -d
   ```

