# Jenkins Performance Optimization Guide

## Performance Issues Fixed

The docker-compose.yml has been optimized to improve Jenkins performance:

### 1. **JVM Memory Settings**
```yaml
JAVA_OPTS=-Xmx2048m -Xms1024m -XX:+UseG1GC -XX:+UseContainerSupport
```
- **Xmx2048m**: Maximum heap size (2GB)
- **Xms1024m**: Initial heap size (1GB) - reduces dynamic allocation overhead
- **UseG1GC**: G1 garbage collector (better for large heaps)
- **UseContainerSupport**: Respects container memory limits

### 2. **Resource Limits**
```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 4G
    reservations:
      cpus: '1.0'
      memory: 2G
```
- Prevents Jenkins from consuming all system resources
- Ensures minimum resources are available
- Limits maximum usage

### 3. **Jenkins Options Optimization**
```yaml
JENKINS_OPTS=--httpPort=8080 --prefix=/ --ajp13Port=-1
```
- Disables AJP connector (not needed)
- Optimizes HTTP listener

### 4. **Health Check**
- Monitors Jenkins status
- Helps Docker restart unhealthy containers
- Provides visibility into container health

### 5. **Ulimits**
- Increased file descriptor limits
- Better handling of concurrent builds

## Additional Performance Tips

### 1. **Reduce Jenkins Plugins**
Too many plugins slow down Jenkins:
```bash
# Check installed plugins
docker exec jenkins-docker ls /var/jenkins_home/plugins

# Remove unused plugins via Jenkins UI:
# Manage Jenkins → Plugins → Installed → Uninstall
```

### 2. **Optimize Build History**
Limit build history retention:
- **Manage Jenkins → Configure System → Global Build Discarders**
- Set: Keep only last 10 builds
- Archive artifacts selectively

### 3. **Use Jenkinsfile Caching**
Cache dependencies and tools:
```groovy
stage('Cache Dependencies') {
    steps {
        sh '''
            if [ -d .terraform ]; then
                echo "Using cached .terraform"
            else
                terraform init
            fi
        '''
    }
}
```

### 4. **Parallel Stages**
Run independent stages in parallel:
```groovy
parallel {
    stage('Checkov') { ... }
    stage('TFLint') { ... }
    stage('Terraform Validate') { ... }
}
```

### 5. **Optimize Volume Mounts**

#### For macOS/Windows (Docker Desktop):
```yaml
volumes:
  - /var/lib/jenkins:/var/jenkins_home:rw,cached
  - ./:/workspace:ro,cached
```
The `:cached` flag improves performance on macOS/Windows.

#### For Linux:
```yaml
volumes:
  - /var/lib/jenkins:/var/jenkins_home:rw
  - ./:/workspace:ro
```

### 6. **Use Named Volumes for Jenkins Home** (Alternative)

For better performance, consider using a named volume instead of bind mount:

```yaml
volumes:
  - jenkins_home:/var/jenkins_home:rw
  # ... other volumes

volumes:
  jenkins_home:
    driver: local
```

**Note**: This means you'll need to migrate your existing Jenkins data.

### 7. **Disable Unnecessary Features**

In Jenkins UI:
- **Manage Jenkins → Configure System**
- Disable unused cloud providers
- Disable unused build tools
- Reduce log retention

### 8. **Monitor Resource Usage**

```bash
# Check container resource usage
docker stats jenkins-docker

# Check Jenkins memory usage
docker exec jenkins-docker free -h

# Check disk usage
docker exec jenkins-docker df -h
```

### 9. **Increase Docker Resources**

If using Docker Desktop:
- **Settings → Resources**
- Increase CPU: 4+ cores
- Increase Memory: 8GB+
- Increase Swap: 2GB+

### 10. **Use Jenkins Agent Nodes**

Instead of running builds on master:
- Set up agent nodes
- Distribute load
- Better resource utilization

## Performance Monitoring

### Check Jenkins Response Time
```bash
# Time Jenkins login page load
time curl -s http://localhost:8080/login > /dev/null

# Check Jenkins API response
time curl -s http://localhost:8080/api/json > /dev/null
```

### Monitor Container Performance
```bash
# Real-time stats
docker stats jenkins-docker

# Check logs for errors
docker logs jenkins-docker --tail 100

# Check health status
docker inspect jenkins-docker | grep -A 10 Health
```

## Troubleshooting Slow Performance

### Issue: Jenkins UI is slow
**Solutions:**
1. Increase JVM memory: `JAVA_OPTS=-Xmx4096m`
2. Reduce plugins
3. Clear browser cache
4. Check network latency

### Issue: Builds are slow
**Solutions:**
1. Use parallel stages
2. Cache dependencies
3. Use agent nodes
4. Optimize pipeline steps

### Issue: Container startup is slow
**Solutions:**
1. Reduce Jenkins home size
2. Remove old builds
3. Clean up plugins
4. Use SSD for volumes

### Issue: High CPU usage
**Solutions:**
1. Limit concurrent builds
2. Reduce resource-intensive plugins
3. Increase CPU limits in docker-compose
4. Use agent nodes

### Issue: High memory usage
**Solutions:**
1. Increase memory limit: `memory: 6G`
2. Reduce build history
3. Clean up old artifacts
4. Optimize JVM settings

## Quick Performance Checklist

- [ ] JVM memory settings configured
- [ ] Resource limits set
- [ ] Unused plugins removed
- [ ] Build history limited
- [ ] Volume mounts optimized
- [ ] Health checks enabled
- [ ] Docker resources increased (if Desktop)
- [ ] Parallel stages used in pipeline
- [ ] Caching implemented
- [ ] Monitoring in place

## Expected Performance

After optimizations:
- **Startup time**: 30-60 seconds (first time), 10-20 seconds (subsequent)
- **UI load time**: < 2 seconds
- **Build execution**: Depends on pipeline complexity
- **Memory usage**: 1-3GB typical, 4GB peak
- **CPU usage**: 10-30% idle, 50-80% during builds

## Further Optimization

For production environments:
1. Use Jenkins on Kubernetes
2. Implement horizontal pod autoscaling
3. Use persistent volumes (SSD)
4. Set up Jenkins backup/restore
5. Implement monitoring (Prometheus/Grafana)
6. Use CDN for static assets
7. Enable HTTP/2
8. Use reverse proxy (nginx) for SSL termination

