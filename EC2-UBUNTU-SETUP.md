# AWS EC2 Ubuntu Setup Guide

## Prerequisites on EC2 Ubuntu

### 1. Install Docker and Docker Compose

```bash
# Update system
sudo apt-get update

# Install Docker
sudo apt-get install -y docker.io docker-compose

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add your user to docker group (if not root)
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

### 2. Stop Existing Jenkins (if running)

```bash
# Check if Jenkins service is running
sudo systemctl status jenkins

# Stop Jenkins service
sudo systemctl stop jenkins
sudo systemctl disable jenkins

# Check if port 8080 is free
sudo netstat -tlnp | grep 8080
```

### 3. Fix Permissions

```bash
# Ensure Jenkins home directory has correct permissions
sudo chown -R 1000:1000 /var/lib/jenkins

# Or if using different path
sudo chown -R 1000:1000 /opt/jenkins
```

### 4. Check System Resources

```bash
# Check available memory (should be at least 4GB)
free -h

# Check disk space (should have at least 10GB free)
df -h

# Check CPU
nproc
```

## Fixing Jenkins Restart Loop

### Step 1: Check What's Wrong

```bash
# Check container status
docker ps -a | grep jenkins

# Check logs for errors
docker logs jenkins-docker --tail 100

# Check if port is in use
sudo lsof -i :8080
```

### Step 2: Stop and Clean Up

```bash
# Stop Jenkins container
docker-compose stop jenkins

# Remove container (keeps data)
docker-compose rm -f jenkins

# If needed, check Docker logs
sudo journalctl -u docker --no-pager | tail -50
```

### Step 3: Apply Fixed Configuration

The updated `docker-compose.yml` includes:
- ✅ Simplified health check (no pid file check)
- ✅ Removed problematic `JENKINS_JAVA_OPTIONS`
- ✅ Increased health check start period (240s)
- ✅ Removed `depends_on sonarqube` (not needed)
- ✅ More lenient health check retries (5 instead of 3)

### Step 4: Start Jenkins

```bash
# Start Jenkins with new config
docker-compose up -d jenkins

# Watch logs in real-time
docker-compose logs -f jenkins

# In another terminal, check status
docker ps | grep jenkins
```

### Step 5: Verify It's Working

```bash
# Check container is running (not restarting)
docker ps | grep jenkins
# Should show "Up" status, not "Restarting"

# Check health status
docker inspect jenkins-docker | grep -A 15 Health

# Test Jenkins is accessible
curl -I http://localhost:8080

# Or from your local machine (if security group allows)
curl -I http://<EC2-IP>:8080
```

## EC2 Security Group Configuration

Ensure your EC2 security group allows:
- **Port 8080** (Jenkins HTTP) - from your IP or 0.0.0.0/0
- **Port 50000** (Jenkins agent) - from your IP or 0.0.0.0/0
- **Port 9000** (SonarQube) - from your IP or 0.0.0.0/0

```bash
# Example: Allow port 8080 from anywhere (adjust as needed)
# Do this via AWS Console or CLI
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxx \
  --protocol tcp \
  --port 8080 \
  --cidr 0.0.0.0/0
```

## Common Issues on EC2 Ubuntu

### Issue 1: Port Already in Use

```bash
# Find what's using port 8080
sudo lsof -i :8080

# Kill the process or stop the service
sudo systemctl stop jenkins
# Or
sudo kill -9 <PID>
```

### Issue 2: Permission Denied

```bash
# Fix Jenkins home permissions
sudo chown -R 1000:1000 /var/lib/jenkins

# Fix Docker socket permissions
sudo chmod 666 /var/run/docker.sock
# Or add user to docker group
sudo usermod -aG docker $USER
```

### Issue 3: Out of Memory

```bash
# Check memory
free -h

# If low, reduce JVM memory in docker-compose.yml:
# JAVA_OPTS=-Xmx1024m -Xms512m
```

### Issue 4: Disk Space Full

```bash
# Check disk space
df -h

# Clean up Docker
docker system prune -a

# Clean up old Jenkins builds (via Jenkins UI)
```

### Issue 5: Health Check Failing

If health check keeps failing, temporarily disable it:

```yaml
# Comment out healthcheck in docker-compose.yml
# healthcheck:
#   test: ...
```

Then restart:
```bash
docker-compose up -d jenkins
```

## Monitoring on EC2

### Check Resource Usage

```bash
# Container stats
docker stats jenkins-docker

# System resources
htop
# Or
top

# Disk I/O
iostat -x 1
```

### Check Logs

```bash
# Jenkins container logs
docker logs jenkins-docker --tail 100 -f

# Docker daemon logs
sudo journalctl -u docker -f

# System logs
sudo tail -f /var/log/syslog
```

## Accessing Jenkins from Your Machine

1. **Get EC2 Public IP:**
   ```bash
   curl http://169.254.169.254/latest/meta-data/public-ipv4
   ```

2. **Configure Security Group** (as shown above)

3. **Access Jenkins:**
   ```
   http://<EC2-PUBLIC-IP>:8080
   ```

4. **Get Initial Admin Password:**
   ```bash
   docker exec jenkins-docker cat /var/jenkins_home/secrets/initialAdminPassword
   ```

## Performance Tips for EC2

1. **Use appropriate instance type:**
   - Minimum: `t3.medium` (2 vCPU, 4GB RAM)
   - Recommended: `t3.large` (2 vCPU, 8GB RAM)
   - For production: `t3.xlarge` (4 vCPU, 16GB RAM)

2. **Use EBS GP3 volumes** for better I/O performance

3. **Enable CloudWatch monitoring** to track resource usage

4. **Set up auto-scaling** if using multiple agents

## Troubleshooting Commands

```bash
# Full diagnostic
docker ps -a
docker logs jenkins-docker --tail 200
docker inspect jenkins-docker
free -h
df -h
sudo netstat -tlnp | grep -E "8080|50000|9000"

# Restart everything
docker-compose down
docker-compose up -d

# Clean restart (removes containers, keeps volumes)
docker-compose down
docker-compose up -d --force-recreate
```

