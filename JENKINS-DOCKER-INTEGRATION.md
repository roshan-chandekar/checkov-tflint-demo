# How Jenkins Uses Docker Containers (Checkov & TFLint)

## Overview

When you run `docker-compose up`, you get containers running:
- **`checkov`** container (name: `checkov`)
- **`tflint`** container (name: `tflint`)

Jenkins can execute commands inside these containers using `docker exec`.

## How It Works

### 1. Docker Socket Access

The Jenkins container (or your existing Jenkins) needs access to Docker:

```yaml
# In docker-compose.yml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

This allows Jenkins to run `docker` commands.

### 2. Container Names

The containers have fixed names:
- `checkov` - Checkov container
- `tflint` - TFLint container

### 3. Volume Mounts

Both containers mount your project directory:
```yaml
volumes:
  - ./:/workspace:ro  # Your Terraform code is accessible inside container
```

### 4. How Jenkins Calls Them

Instead of running `checkov` directly, Jenkins runs:
```bash
docker exec checkov checkov [arguments]
```

This executes `checkov` command **inside** the `checkov` container.

## Current Jenkinsfile vs Docker-Based Approach

### Current Approach (Local Tools)
```groovy
CHECKOV_CMD=$(command -v checkov)  # Finds local checkov
$CHECKOV_CMD -d modules --framework terraform
```

### Docker-Based Approach
```groovy
docker exec -i -w /workspace checkov checkov -d modules --framework terraform
```

## Step-by-Step: How Jenkins Finds and Uses Checkov

1. **Jenkins runs a shell command** in the pipeline
2. **Jenkins checks if Docker is available** (via docker socket)
3. **Jenkins executes**: `docker exec checkov checkov [args]`
4. **Docker finds the container** named `checkov` (from docker-compose)
5. **Container runs checkov** with your Terraform code (mounted at `/workspace`)
6. **Results are written** to the mounted volume (your workspace)

## Example: Complete Flow

```bash
# 1. Start containers
docker-compose up -d

# 2. Jenkins pipeline stage runs:
docker exec -i -w /workspace checkov checkov -d modules --framework terraform --output json

# 3. What happens:
#    - Docker finds container "checkov"
#    - Executes "checkov" command inside it
#    - Container sees /workspace (your code mounted)
#    - Checkov scans /workspace/modules
#    - Output goes to Jenkins workspace
```

## Modifying Your Jenkinsfile

You have two options:

### Option A: Use Docker Containers (Recommended for Docker Setup)

Replace tool commands with `docker exec`:

```groovy
// Instead of: CHECKOV_CMD=$(command -v checkov)
// Use: docker exec checkov checkov

stage('Checkov - Modules') {
    steps {
        sh '''
            docker exec -i -w /workspace checkov checkov \
                -d modules \
                --framework terraform \
                --config-file .checkov.yaml \
                --skip-check CKV_AWS_18 \
                --skip-check CKV_AWS_19 \
                --skip-check CKV_AWS_144 \
                --output json \
                --soft-fail > checkov-modules-results.json 2>/dev/null || true
        '''
    }
}
```

### Option B: Hybrid (Try Docker, Fallback to Local)

```groovy
stage('Checkov - Modules') {
    steps {
        sh '''
            # Try Docker first, fallback to local
            if docker ps | grep -q checkov; then
                CHECKOV_CMD="docker exec -i -w /workspace checkov checkov"
            else
                CHECKOV_CMD=$(command -v checkov)
            fi
            $CHECKOV_CMD -d modules --framework terraform --output json
        '''
    }
}
```

## Requirements

### For Existing Jenkins (Not in Docker)

1. **Install Docker** on the Jenkins server
2. **Add Jenkins user to docker group**:
   ```bash
   sudo usermod -aG docker jenkins
   sudo systemctl restart jenkins
   ```
3. **Start containers**:
   ```bash
   docker-compose up -d
   ```
4. **Verify containers are running**:
   ```bash
   docker ps | grep -E "checkov|tflint"
   ```

### For Docker Jenkins Container

Already configured in docker-compose.yml:
- Docker socket mounted
- Containers on same network
- Ready to use!

## Testing the Connection

### From Jenkins Server (SSH/Shell)

```bash
# Test Checkov container
docker exec checkov checkov --version

# Test TFLint container  
docker exec tflint tflint --version

# Test scanning
docker exec -i -w /workspace checkov checkov -d . --framework terraform
```

### From Jenkins Pipeline

Add a test stage:
```groovy
stage('Test Docker Tools') {
    steps {
        sh '''
            echo "Testing Checkov container..."
            docker exec checkov checkov --version
            echo "Testing TFLint container..."
            docker exec tflint tflint --version
        '''
    }
}
```

## Common Issues

### Issue: "docker: command not found"
**Solution**: Install Docker on Jenkins server or use Docker Jenkins container

### Issue: "Cannot connect to the Docker daemon"
**Solution**: 
- Check Docker is running: `sudo systemctl status docker`
- Add Jenkins user to docker group
- Restart Jenkins

### Issue: "No such container: checkov"
**Solution**: 
- Start containers: `docker-compose up -d`
- Check container name: `docker ps`

### Issue: "Permission denied"
**Solution**: 
- Add user to docker group
- Or run Jenkins as root (not recommended for production)

## Summary

**How Jenkins knows about Checkov:**
- Jenkins doesn't "know" about it automatically
- You tell Jenkins to use `docker exec checkov checkov`
- Docker finds the container by name
- Container has your code mounted at `/workspace`

**How Terraform repository picks it up:**
- Your code is mounted into containers via volume: `./:/workspace`
- When Jenkins runs `docker exec checkov checkov -d /workspace`, it scans your code
- Results are written back to the mounted volume (your workspace)

