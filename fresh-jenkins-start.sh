#!/bin/bash
# Script to start fresh Jenkins instance - removes old data and starts clean

echo "=== Starting Fresh Jenkins Instance ==="
echo ""
echo "⚠ WARNING: This will DELETE all existing Jenkins data!"
echo "This includes:"
echo "  - All jobs"
echo "  - All plugins"
echo "  - All configurations"
echo "  - All build history"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted. No changes made."
    exit 0
fi

echo ""
echo "Step 1: Stopping Jenkins container..."
docker-compose stop jenkins
docker-compose rm -f jenkins

echo ""
echo "Step 2: Backing up old Jenkins data (just in case)..."
BACKUP_DIR="/tmp/jenkins-backup-$(date +%Y%m%d-%H%M%S)"
if [ -d "/var/lib/jenkins" ]; then
    echo "Creating backup at: $BACKUP_DIR"
    sudo mkdir -p "$BACKUP_DIR"
    sudo cp -r /var/lib/jenkins "$BACKUP_DIR/" 2>/dev/null || echo "Backup created (some files may be locked)"
    echo "Backup location: $BACKUP_DIR"
fi

echo ""
echo "Step 3: Removing old Jenkins data..."
if [ -d "/var/lib/jenkins" ]; then
    echo "Removing /var/lib/jenkins..."
    sudo rm -rf /var/lib/jenkins
    echo "✓ Old Jenkins data removed"
else
    echo "No existing Jenkins data found at /var/lib/jenkins"
fi

echo ""
echo "Step 4: Removing Jenkins Docker volumes (if any)..."
docker volume ls | grep jenkins | awk '{print $2}' | xargs -r docker volume rm 2>/dev/null || echo "No Jenkins volumes found"

echo ""
echo "Step 5: Pulling fresh Jenkins image..."
docker-compose pull jenkins

echo ""
echo "Step 6: Starting fresh Jenkins instance..."
docker-compose up -d jenkins

echo ""
echo "Step 7: Waiting for Jenkins to start (this may take 1-2 minutes)..."
sleep 30

# Wait for Jenkins to be ready
MAX_WAIT=120
WAIT_TIME=0
while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    if docker exec jenkins-docker curl -f -s http://localhost:8080/login > /dev/null 2>&1; then
        echo "✓ Jenkins is ready!"
        break
    fi
    echo "Waiting for Jenkins to start... ($WAIT_TIME/$MAX_WAIT seconds)"
    sleep 5
    WAIT_TIME=$((WAIT_TIME + 5))
done

echo ""
echo "Step 8: Getting initial admin password..."
INITIAL_PASSWORD=$(docker exec jenkins-docker cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null)
if [ -n "$INITIAL_PASSWORD" ]; then
    echo "Initial admin password: $INITIAL_PASSWORD"
    echo ""
    echo "⚠ IMPORTANT: Save this password! You'll need it to unlock Jenkins."
else
    echo "⚠ Could not retrieve initial password. Check logs:"
    echo "  docker logs jenkins-docker"
fi

echo ""
echo "=== Fresh Jenkins Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Access Jenkins: http://<EC2-IP>:8080"
echo "  2. Enter initial admin password: $INITIAL_PASSWORD"
echo "  3. Install suggested plugins (or select plugins to install)"
echo "  4. Create admin user"
echo "  5. Configure Jenkins"
echo ""
echo "To install all required plugins automatically, run:"
echo "  ./fix-jenkins-plugins.sh"
echo ""
echo "Backup location (if created): $BACKUP_DIR"
echo ""
echo "To check Jenkins status:"
echo "  docker logs jenkins-docker --tail 50"

