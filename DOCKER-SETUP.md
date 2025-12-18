# Docker Compose Setup Guide

This setup provides SonarQube, Jenkins, TFLint, and Checkov in Docker containers.

## Quick Start

### 1. Find Your Jenkins Home Directory

```bash
# Check where Jenkins is installed
sudo cat /etc/default/jenkins | grep JENKINS_HOME
# Or check common locations
ls -la /var/lib/jenkins
```

### 2. Update docker-compose.yml

Edit `docker-compose.yml` and update the Jenkins volume mount if needed:
```yaml
volumes:
  - /var/lib/jenkins:/var/jenkins_home:rw  # Update this path if different
```

### 3. Stop Existing Jenkins (if using Docker Jenkins)

If you want to use the Docker Jenkins container:
```bash
sudo systemctl stop jenkins
sudo systemctl disable jenkins  # Optional: prevent auto-start
```

**OR** if you want to keep your existing Jenkins running:
- Comment out the `jenkins:` service in docker-compose.yml
- Change the port mapping to avoid conflicts (e.g., `"8081:8080"`)

### 4. Start Services

```bash
# Start all services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 5. Access Services

- **SonarQube**: http://localhost:9000 (admin/admin)
- **Jenkins**: http://localhost:8080 (or your existing Jenkins URL)

## Using Tools from Existing Jenkins

If you're keeping your existing Jenkins installation, you can use the containers:

### In Jenkinsfile:

```groovy
stage('TFLint') {
    steps {
        sh '''
            docker exec -i -w /workspace tflint tflint --init
            docker exec -i -w /workspace tflint tflint
        '''
    }
}

stage('Checkov') {
    steps {
        sh '''
            docker exec -i -w /workspace checkov checkov -d . --framework terraform --output json
        '''
    }
}
```

### Or use helper scripts:

```groovy
sh './scripts/run-tflint-docker.sh --init'
sh './scripts/run-checkov-docker.sh -d . --framework terraform'
```

## Service Details

### SonarQube
- **Image**: `sonarqube:community`
- **Port**: 9000
- **Database**: PostgreSQL (internal)
- **Data**: Persisted in Docker volumes

### Jenkins
- **Image**: `jenkins/jenkins:lts`
- **Port**: 8080
- **Config**: Uses your existing `/var/lib/jenkins`
- **Docker**: Has access to Docker socket

### TFLint
- **Image**: `ghcr.io/terraform-linters/tflint:latest`
- **Usage**: `docker exec tflint tflint [args]`
- **Cache**: Persisted in volume

### Checkov
- **Image**: `bridgecrew/checkov:latest`
- **Usage**: `docker exec checkov checkov [args]`
- **Cache**: Persisted in volume

## Troubleshooting

### Port Conflicts
```bash
# Check what's using port 8080
sudo lsof -i :8080
# Check what's using port 9000
sudo lsof -i :9000
```

### Jenkins Permission Issues
```bash
# Fix permissions
sudo chown -R 1000:1000 /var/lib/jenkins
# Or if using different user
sudo chown -R $(id -u):$(id -g) /var/lib/jenkins
```

### SonarQube Memory Issues
```bash
# Check system limits
ulimit -a
# Increase if needed (add to /etc/security/limits.conf)
```

### Container Not Found
```bash
# List running containers
docker ps
# Check if containers are running
docker-compose ps
```

## Maintenance

### Backup Jenkins
```bash
# Backup before starting Docker Jenkins
sudo tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /var/lib/jenkins
```

### Update Images
```bash
docker-compose pull
docker-compose up -d
```

### Clean Up
```bash
# Stop and remove containers
docker-compose down

# Remove containers and volumes (⚠️ deletes data)
docker-compose down -v
```

