# SonarQube Integration Setup

This guide explains how to set up and use SonarQube scanning in your Jenkins pipeline.

## Prerequisites

1. **SonarQube Server Running**
   ```bash
   docker-compose up -d sonarqube
   ```

2. **Access SonarQube UI**
   - URL: http://localhost:9000
   - Default credentials: `admin` / `admin` (change on first login)

3. **SonarQube Scanner**
   - Available via Docker container (included in docker-compose.yml)
   - Or install locally if not using Docker

## Configuration Files

### sonar-project.properties

This file configures what SonarQube scans:

```properties
sonar.projectKey=checkov-tflint-demo
sonar.projectName=Checkov TFLint Demo - Terraform Project
sonar.sources=.
sonar.exclusions=**/.terraform/**,**/*.tfvars**,**/terraform.tfstate**
sonar.inclusions=**/*.tf,**/*.hcl,**/*.py,**/*.sh
```

**Key Settings:**
- `sonar.projectKey`: Unique identifier for your project in SonarQube
- `sonar.sources`: Root directory to scan (`.` = current directory)
- `sonar.exclusions`: Files/directories to ignore
- `sonar.inclusions`: File patterns to include
- `sonar.host.url`: SonarQube server URL (auto-updated by Jenkinsfile)

## Jenkins Pipeline Integration

The Jenkinsfile includes a **SonarQube Scan** stage that:

1. **Detects scanner availability** (Docker container or local)
2. **Configures SonarQube URL** automatically
3. **Runs the scan** using sonar-project.properties
4. **Handles authentication** (token or default)

### Stage Location

The SonarQube scan runs **after** all security scans (Checkov, TFLint) and Terraform validation, but before the pipeline completes.

## Authentication Setup

### Option 1: Using SonarQube Token (Recommended)

1. **Generate Token in SonarQube:**
   - Login to http://localhost:9000
   - Go to: My Account → Security → Generate Token
   - Copy the token

2. **Add to Jenkins:**
   - Jenkins → Manage Jenkins → Credentials
   - Add Secret Text credential
   - ID: `SONAR_TOKEN`
   - Secret: Your generated token

3. **Use in Pipeline:**
   ```groovy
   environment {
       SONAR_TOKEN = credentials('SONAR_TOKEN')
   }
   ```

### Option 2: Default Authentication

If no token is set, the pipeline uses default `admin/admin` credentials (not recommended for production).

## Running the Scan

### From Jenkins Pipeline

The scan runs automatically when the pipeline executes. The stage:
- Uses Docker container if available (`sonar-scanner` container)
- Falls back to local installation if Docker not available
- Skips gracefully if neither is found

### Manual Testing

```bash
# Test SonarQube connection
curl http://localhost:9000/api/system/status

# Run scanner manually (if using Docker)
docker exec -i -w /workspace sonar-scanner sonar-scanner \
    -Dsonar.host.url=http://sonarqube:9000 \
    -Dproject.settings=sonar-project.properties

# Or with token
docker exec -i -w /workspace sonar-scanner sonar-scanner \
    -Dsonar.host.url=http://sonarqube:9000 \
    -Dsonar.login=YOUR_TOKEN \
    -Dproject.settings=sonar-project.properties
```

## Viewing Results

After the scan completes:

1. **Open SonarQube UI**: http://localhost:9000
2. **Navigate to Projects**: Find your project (`checkov-tflint-demo`)
3. **View Issues**: See code quality issues, security vulnerabilities, code smells
4. **View Metrics**: Code coverage, duplication, complexity

## Troubleshooting

### Issue: "SonarQube scanner not found"

**Solution:**
```bash
# Start SonarQube scanner container
docker-compose up -d sonar-scanner

# Verify it's running
docker ps | grep sonar-scanner
```

### Issue: "Unable to connect to SonarQube server"

**Solution:**
1. Check SonarQube is running: `docker ps | grep sonarqube`
2. Check URL in sonar-project.properties matches your setup
3. For Jenkins in Docker: Use `http://sonarqube:9000`
4. For Jenkins on host: Use `http://localhost:9000`

### Issue: "Authentication failed"

**Solution:**
1. Generate a new token in SonarQube UI
2. Add it to Jenkins credentials as `SONAR_TOKEN`
3. Or update default admin password in SonarQube

### Issue: "Project not found in SonarQube"

**Solution:**
- SonarQube creates projects automatically on first scan
- Ensure `sonar.projectKey` in sonar-project.properties is unique
- Check project appears in SonarQube UI after first scan

## Customizing the Scan

### Exclude More Files

Edit `sonar-project.properties`:
```properties
sonar.exclusions+=**/build/**,**/dist/**,**/vendor/**
```

### Include Additional File Types

```properties
sonar.inclusions=**/*.tf,**/*.hcl,**/*.py,**/*.sh,**/*.yaml,**/*.yml
```

### Change Project Key/Name

```properties
sonar.projectKey=my-terraform-project
sonar.projectName=My Terraform Project
```

## Integration with Other Tools

The SonarQube scan complements:
- **Checkov**: Security policy violations
- **TFLint**: Terraform best practices
- **Terraform Validate**: Syntax validation
- **SonarQube**: Code quality, maintainability, technical debt

All results are available in their respective UIs and Jenkins artifacts.

## Best Practices

1. **Use Token Authentication**: Never hardcode credentials
2. **Set Unique Project Keys**: Avoid conflicts between projects
3. **Exclude Build Artifacts**: Don't scan generated files
4. **Review Exclusions**: Ensure important files aren't ignored
5. **Monitor Quality Gates**: Set up quality gates in SonarQube
6. **Regular Scans**: Run scans on every commit/PR

## Next Steps

1. **Set up Quality Gates**: Define pass/fail criteria in SonarQube
2. **Configure Notifications**: Get alerts for new issues
3. **Add Terraform Plugin**: Install SonarQube Terraform plugin for better analysis
4. **Integrate with PRs**: Add SonarQube comments to pull requests

