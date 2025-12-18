# Docker Compose Setup for SonarQube, Jenkins, TFLint, and Checkov

This docker-compose file sets up:
- **SonarQube Community Edition** with PostgreSQL database
- **Jenkins** using your existing Jenkins configuration from Ubuntu
- **TFLint** container for Terraform linting
- **Checkov** container for security scanning

## Prerequisites

1. Docker and Docker Compose installed
2. Existing Jenkins installation on Ubuntu (typically at `/var/lib/jenkins`)
3. Adjust the Jenkins volume mount path if your Jenkins home is in a different location

## Important Configuration

### Jenkins Setup Options

**Option 1: Use Docker Jenkins Container (uses existing config)**
- The docker-compose.yml mounts your existing Jenkins home directory
- **⚠️ IMPORTANT:** Stop your existing Jenkins service first:
  ```bash
  sudo systemctl stop jenkins
  ```
- If your Jenkins uses port 8080, the container will use the same port
- To find your Jenkins home: `sudo cat /etc/default/jenkins | grep JENKINS_HOME` or check `/var/lib/jenkins`
- Update the volume mount path in docker-compose.yml if different

**Option 2: Keep Existing Jenkins, Use Containers for Tools**
- Comment out the `jenkins:` service in docker-compose.yml
- Your existing Jenkins can call TFLint and Checkov containers:
  ```groovy
  sh 'docker exec tflint tflint --version'
  sh 'docker exec checkov checkov --version'
  ```

### Workspace Mount

The current project directory is mounted as read-only:
```yaml
- ./:/workspace:ro
```

## Usage

### Start all services:
```bash
docker-compose up -d
```

### Check service status:
```bash
docker-compose ps
```

### View logs:
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f jenkins
docker-compose logs -f sonarqube
```

### Stop all services:
```bash
docker-compose down
```

### Stop and remove volumes (⚠️ deletes data):
```bash
docker-compose down -v
```

## Access Points

- **Jenkins**: http://localhost:8080
  - Initial admin password: Check Jenkins logs or `/var/lib/jenkins/secrets/initialAdminPassword`
  
- **SonarQube**: http://localhost:9000
  - Default credentials: `admin` / `admin` (change on first login)

## Using TFLint and Checkov from Jenkins

You can use the containers in your Jenkinsfile:

### Option 1: Use containers directly
```groovy
sh '''
  docker exec tflint tflint --version
  docker exec checkov checkov --version
'''
```

### Option 2: Install tools in Jenkins container
The Jenkins container can install tools, or you can create a custom Jenkins image with tools pre-installed.

### Option 3: Use Jenkins agents with tools
Configure Jenkins agents that have access to these containers.

## Customizing Jenkins

If you need to customize the Jenkins container (e.g., install additional tools), create a `Dockerfile`:

```dockerfile
FROM jenkins/jenkins:lts
USER root
RUN apt-get update && apt-get install -y \
    terraform \
    python3-pip \
    && pip3 install checkov
USER jenkins
```

Then update docker-compose.yml:
```yaml
jenkins:
  build: .
  # ... rest of config
```

## Troubleshooting

### Jenkins permission issues:
```bash
# Fix permissions if needed
sudo chown -R 1000:1000 /var/lib/jenkins
```

### SonarQube not starting:
- Check logs: `docker-compose logs sonarqube`
- Ensure PostgreSQL is healthy: `docker-compose ps postgres`
- Check system limits: `ulimit -a`

### Port conflicts:
- Change ports in docker-compose.yml if 8080 or 9000 are already in use

## Notes

- SonarQube data persists in Docker volumes
- Jenkins uses your existing configuration (jobs, plugins, etc.)
- TFLint and Checkov containers run continuously for easy access
- All services are on the same Docker network for communication

