#!/bin/bash
# Quick fix script for Jenkins restart loop on EC2 Ubuntu
# Run this on your EC2 instance

echo "=== Fixing Jenkins Restart Loop ==="

# Stop Jenkins container
echo "1. Stopping Jenkins container..."
docker-compose stop jenkins
docker-compose rm -f jenkins

# Verify docker-compose.yml has correct JENKINS_OPTS
echo "2. Verifying docker-compose.yml configuration..."
if grep -q "ajp13Port" docker-compose.yml; then
    echo "ERROR: docker-compose.yml still contains invalid --ajp13Port option"
    echo "Please update docker-compose.yml to remove --ajp13Port and --prefix options"
    echo "JENKINS_OPTS should be: --httpPort=8080 --httpListenAddress=0.0.0.0"
    exit 1
fi

# Check if port is in use
echo "3. Checking if port 8080 is available..."
if sudo netstat -tlnp | grep -q ":8080 "; then
    echo "WARNING: Port 8080 is in use. Stopping existing Jenkins service..."
    sudo systemctl stop jenkins 2>/dev/null || true
fi

# Start Jenkins with fixed config
echo "4. Starting Jenkins with fixed configuration..."
docker-compose up -d jenkins

# Wait a moment
sleep 5

# Check status
echo "5. Checking Jenkins status..."
docker ps | grep jenkins

echo ""
echo "=== Monitoring Jenkins logs (Ctrl+C to exit) ==="
echo "If you see 'Unrecognized option: --ajp13Port', the config file needs updating"
echo ""
docker-compose logs -f jenkins

