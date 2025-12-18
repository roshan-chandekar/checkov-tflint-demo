# Quick Performance Fix for Slow Jenkins

## Immediate Actions

### 1. Restart Jenkins with Optimized Settings

```bash
# Stop current Jenkins
docker-compose stop jenkins

# Start with new optimized configuration
docker-compose up -d jenkins

# Check if it's running
docker-compose ps jenkins

# Monitor startup
docker-compose logs -f jenkins
```

### 2. Verify Resource Allocation

```bash
# Check current resource usage
docker stats jenkins-docker

# If memory is maxed out, increase in docker-compose.yml:
# memory: 6G (instead of 4G)
```

### 3. Check Jenkins Health

```bash
# Check container health
docker inspect jenkins-docker | grep -A 10 Health

# Check if Jenkins is responding
curl -I http://localhost:8080
```

## Key Optimizations Applied

✅ **JVM Memory**: Set to 2GB max, 1GB initial (prevents memory allocation overhead)  
✅ **Resource Limits**: CPU (2 cores max) and Memory (4GB max)  
✅ **G1 Garbage Collector**: Better for large heaps  
✅ **Health Checks**: Monitor container status  
✅ **Ulimits**: Increased file descriptor limits  

## If Still Slow

### Option 1: Increase Memory
Edit `docker-compose.yml`:
```yaml
JAVA_OPTS=-Xmx4096m -Xms2048m  # Increase to 4GB
memory: 6G  # Increase limit
```

### Option 2: Use Your Existing Jenkins
Comment out Jenkins service in docker-compose.yml and use your Ubuntu Jenkins instead.

### Option 3: Check System Resources
```bash
# Check available memory
free -h

# Check CPU
nproc

# Check disk I/O
iostat -x 1
```

## Performance Comparison

**Before:**
- Startup: 2-5 minutes
- UI load: 5-10 seconds
- Memory: Unbounded

**After:**
- Startup: 30-60 seconds
- UI load: 1-2 seconds  
- Memory: 2-4GB controlled

## Need More Help?

See `JENKINS-PERFORMANCE.md` for detailed optimization guide.

