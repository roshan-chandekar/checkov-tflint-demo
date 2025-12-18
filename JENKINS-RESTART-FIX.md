# Fix Jenkins Restart Loop on AWS EC2 Ubuntu

## Common Causes of Restart Loop

1. **Health check failing** - Health check runs before Jenkins is ready
2. **Port conflicts** - Port 8080 already in use
3. **Permission issues** - Jenkins can't write to mounted volumes
4. **Memory issues** - Container runs out of memory
5. **Invalid JVM options** - JVM crashes on startup

## Quick Fix Steps

### 1. Check Current Status
```bash
# Check if Jenkins is restarting
docker ps -a | grep jenkins

# Check logs for errors
docker logs jenkins-docker --tail 100

# Check if port is in use
sudo netstat -tlnp | grep 8080
```

### 2. Stop and Remove Container
```bash
# Stop Jenkins
docker-compose stop jenkins

# Remove container (keeps volumes)
docker-compose rm -f jenkins
```

### 3. Fix Common Issues

#### Issue A: Health Check Too Aggressive
The health check might be running before Jenkins is ready. Solution: Increase `start_period` or disable temporarily.

#### Issue B: Port Conflict
If port 8080 is already in use by another Jenkins:
```bash
# Check what's using port 8080
sudo lsof -i :8080

# Stop existing Jenkins service
sudo systemctl stop jenkins
```

#### Issue C: Permission Issues
```bash
# Fix permissions on Jenkins home
sudo chown -R 1000:1000 /var/lib/jenkins
# Or if using different path
sudo chown -R 1000:1000 /opt/jenkins
```

#### Issue D: Memory Issues
Check available memory:
```bash
free -h
# If low, reduce JVM memory in docker-compose.yml
```

### 4. Temporarily Disable Health Check

Edit `docker-compose.yml` and comment out healthcheck:
```yaml
# healthcheck:
#   test: ["CMD-SHELL", "..."]
```

### 5. Start Jenkins Again
```bash
docker-compose up -d jenkins

# Watch logs
docker-compose logs -f jenkins
```

## Permanent Fix

The updated docker-compose.yml includes:
- More lenient health check (180s start period)
- Proper curl-based health check
- Removed problematic JENKINS_JAVA_OPTIONS
- Simplified JENKINS_OPTS

## Verify Fix

```bash
# Check container status
docker ps | grep jenkins

# Should show "Up" not "Restarting"
# Check health status
docker inspect jenkins-docker | grep -A 10 Health

# Access Jenkins
curl http://localhost:8080
```

## If Still Restarting

1. **Check full logs:**
   ```bash
   docker logs jenkins-docker 2>&1 | tail -200
   ```

2. **Check system resources:**
   ```bash
   docker stats jenkins-docker
   free -h
   df -h
   ```

3. **Try minimal config:**
   - Remove health check
   - Reduce JVM memory
   - Remove depends_on sonarqube (if not needed)

4. **Check EC2 instance resources:**
   - Minimum: 2 vCPU, 4GB RAM
   - Recommended: 4 vCPU, 8GB RAM

