# How Jenkins Uses Docker Containers - Simple Explanation

## The Big Picture

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Ubuntu Machine                      │
│                                                             │
│  ┌──────────────┐         ┌─────────────────────────────┐  │
│  │   Jenkins    │────────▶│  Docker Engine              │  │
│  │  (Pipeline)  │         │  (Manages Containers)       │  │
│  └──────────────┘         └─────────────────────────────┘  │
│         │                            │                        │
│         │ docker exec                │                        │
│         │                            │                        │
│         ▼                            ▼                        │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Docker Containers                       │   │
│  │                                                       │   │
│  │  ┌──────────────┐              ┌──────────────┐      │   │
│  │  │   checkov    │              │   tflint    │      │   │
│  │  │  container   │              │  container  │      │   │
│  │  └──────────────┘              └──────────────┘      │   │
│  │         │                              │              │   │
│  │         └──────────┬──────────────────┘              │   │
│  │                    │                                  │   │
│  │                    ▼                                  │   │
│  │         ┌─────────────────────┐                       │   │
│  │         │  /workspace         │                       │   │
│  │         │  (Your Terraform    │                       │   │
│  │         │   Code - Mounted)   │                       │   │
│  │         └─────────────────────┘                       │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Step-by-Step Flow

### 1. You Start Containers
```bash
docker-compose up -d
```
**Result**: Two containers start:
- Container named `checkov` (running Checkov tool)
- Container named `tflint` (running TFLint tool)

### 2. Containers Mount Your Code
```yaml
# In docker-compose.yml
volumes:
  - ./:/workspace:ro  # Your project → /workspace inside container
```
**Result**: Your Terraform code is accessible inside containers at `/workspace`

### 3. Jenkins Pipeline Runs
```groovy
stage('Checkov - Modules') {
    steps {
        sh 'docker exec checkov checkov -d modules --framework terraform'
    }
}
```

### 4. What Happens Inside

```
Jenkins executes: docker exec checkov checkov -d modules --framework terraform
         │
         ├─▶ Docker finds container named "checkov"
         │
         ├─▶ Docker executes "checkov" command inside that container
         │
         ├─▶ Container sees /workspace (your code mounted there)
         │
         ├─▶ Checkov scans /workspace/modules
         │
         └─▶ Results written to /workspace (which is your project directory)
```

## Key Concepts

### 1. Container Names
- Docker containers have **names** (set in docker-compose.yml)
- Jenkins uses the name to find the container: `docker exec checkov ...`
- Container name = `checkov` (from `container_name: checkov`)

### 2. Volume Mounts
- Your project directory is **mounted** into containers
- Mount point: `/workspace` (inside container)
- Your code at `./modules` → Container sees `/workspace/modules`

### 3. Docker Exec
- `docker exec` = "run a command inside a running container"
- `docker exec checkov checkov` = "run checkov command inside checkov container"
- `-w /workspace` = "set working directory to /workspace"

## Real Example

### Command Jenkins Runs:
```bash
docker exec -i -w /workspace checkov checkov -d modules --framework terraform --output json
```

### Breakdown:
- `docker exec` = Execute command in container
- `-i` = Interactive mode (for input)
- `-w /workspace` = Working directory inside container
- `checkov` = Container name
- `checkov` = Command to run (the tool itself)
- `-d modules` = Scan the modules directory
- `--framework terraform` = Use Terraform framework
- `--output json` = Output as JSON

### What Container Sees:
```
Container's view:
/workspace/
  ├── modules/
  │   ├── s3/
  │   ├── dynamodb/
  │   └── ...
  ├── projects/
  ├── .checkov.yaml
  └── ...

Checkov scans: /workspace/modules
Results saved to: /workspace/checkov-results.json
```

### What You See (on your machine):
```
Your project:
./
  ├── modules/
  ├── projects/
  ├── .checkov.yaml
  └── checkov-results.json  ← Results appear here!
```

## Why This Works

1. **Same Files**: Container `/workspace` = Your project directory (via mount)
2. **Same Network**: All containers can communicate
3. **Docker Socket**: Jenkins can run `docker` commands
4. **Container Names**: Fixed names make it easy to reference

## Quick Test

### From Command Line:
```bash
# Test if containers are running
docker ps | grep -E "checkov|tflint"

# Test Checkov container
docker exec checkov checkov --version

# Test scanning
docker exec -i -w /workspace checkov checkov -d . --framework terraform
```

### From Jenkins Pipeline:
```groovy
stage('Test') {
    steps {
        sh '''
            docker exec checkov checkov --version
            docker exec tflint tflint --version
        '''
    }
}
```

## Summary

**Q: How does Jenkins know Checkov is there?**
A: Jenkins doesn't "know" automatically. You tell Jenkins to use `docker exec checkov checkov`. Docker finds the container by name.

**Q: How does Terraform repository pick it up?**
A: Your code is mounted into containers. When Jenkins runs `docker exec checkov checkov -d /workspace`, Checkov scans your mounted code and writes results back to the same mount (your workspace).

**The Connection:**
- Jenkins → Docker → Container → Your Code (mounted) → Results → Your Workspace

