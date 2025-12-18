#!/bin/bash
# Script to fix corrupted Jenkins job

echo "=== Fixing Corrupted Jenkins Job 'checkov' ==="

# Check if job exists
if docker exec jenkins-docker test -d /var/jenkins_home/jobs/checkov; then
    echo "Found corrupted job 'checkov'"
    
    # Backup before deletion
    echo "Creating backup..."
    docker exec jenkins-docker mkdir -p /var/jenkins_home/backups
    docker exec jenkins-docker tar -czf /var/jenkins_home/backups/checkov-job-backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /var/jenkins_home jobs/checkov 2>/dev/null || true
    
    # Delete corrupted job
    echo "Deleting corrupted job..."
    docker exec jenkins-docker rm -rf /var/jenkins_home/jobs/checkov
    
    echo "✓ Job deleted successfully"
    echo ""
    echo "Restarting Jenkins..."
    docker-compose restart jenkins
    
    echo ""
    echo "Waiting 10 seconds for Jenkins to restart..."
    sleep 10
    
    echo ""
    echo "Checking Jenkins logs..."
    docker logs jenkins-docker --tail 20 | grep -i "checkov\|error\|failed" || echo "No errors found"
    
    echo ""
    echo "=== Fix Complete ==="
    echo "The job 'checkov' has been removed."
    echo "You can recreate it via Jenkins UI or it will be created automatically if using Jenkinsfile."
    echo ""
    echo "Backup location: /var/jenkins_home/backups/"
else
    echo "Job 'checkov' not found. Nothing to fix."
fi

