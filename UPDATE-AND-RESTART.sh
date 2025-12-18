#!/bin/bash
# Script to pull latest changes and restart Jenkins on EC2 Ubuntu
# Run this on your EC2 instance

echo "=== Pulling Latest Changes from GitHub ==="

# Pull latest changes
git pull origin main
# Or if using master branch:
# git pull origin master

echo ""
echo "=== Verifying docker-compose.yml Configuration ==="

# Verify JENKINS_OPTS is correct
if grep -q "ajp13Port" docker-compose.yml; then
    echo "ERROR: docker-compose.yml still contains invalid --ajp13Port option"
    echo "Please check the file manually"
    exit 1
fi

if grep -q "JENKINS_OPTS=--httpPort=8080 --httpListenAddress=0.0.0.0" docker-compose.yml; then
    echo "✓ docker-compose.yml has correct JENKINS_OPTS"
else
    echo "WARNING: JENKINS_OPTS might not be correct"
    echo "Current JENKINS_OPTS:"
    grep JENKINS_OPTS docker-compose.yml
fi

echo ""
echo "=== Stopping Jenkins Container ==="
docker-compose stop jenkins
docker-compose rm -f jenkins

echo ""
echo "=== Starting Jenkins with Updated Configuration ==="
docker-compose up -d jenkins

echo ""
echo "=== Waiting 10 seconds for Jenkins to start ==="
sleep 10

echo ""
echo "=== Checking Jenkins Status ==="
docker ps | grep jenkins

echo ""
echo "=== Jenkins Logs (last 30 lines) ==="
docker logs jenkins-docker --tail 30

echo ""
echo "=== Next Steps ==="
echo "1. Monitor logs: docker-compose logs -f jenkins"
echo "2. Check status: docker ps | grep jenkins"
echo "3. Access Jenkins: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):8080"
echo "4. Get admin password: docker exec jenkins-docker cat /var/jenkins_home/secrets/initialAdminPassword"

