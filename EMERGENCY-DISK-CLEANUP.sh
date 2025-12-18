#!/bin/bash
# Emergency Disk Cleanup Script for EC2 Ubuntu
# Run this immediately to free up disk space

echo "=== EMERGENCY DISK CLEANUP ==="
echo "Current disk usage:"
df -h | grep "/$"

echo ""
echo "=== Step 1: Finding Largest Directories ==="
echo "Top 10 largest directories:"
sudo du -h --max-depth=1 / 2>/dev/null | sort -rh | head -10

echo ""
echo "=== Step 2: Cleaning Docker ==="
echo "Docker disk usage before:"
docker system df

echo "Cleaning Docker..."
docker system prune -a -f --volumes

echo "Docker disk usage after:"
docker system df

echo ""
echo "=== Step 3: Cleaning APT Cache ==="
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove -y

echo ""
echo "=== Step 4: Cleaning Logs ==="
# Clean system logs older than 7 days
sudo journalctl --vacuum-time=7d

# Clean old log files
sudo find /var/log -type f -name "*.log" -mtime +7 -delete
sudo find /var/log -type f -name "*.gz" -delete

echo ""
echo "=== Step 5: Cleaning Jenkins (if exists) ==="
if [ -d /var/lib/jenkins ]; then
    echo "Jenkins home size before:"
    sudo du -sh /var/lib/jenkins
    
    # Clean old Jenkins logs
    sudo find /var/lib/jenkins/logs -type f -mtime +7 -delete 2>/dev/null
    
    # Clean workspace (be careful!)
    echo "Cleaning Jenkins workspaces older than 30 days..."
    sudo find /var/lib/jenkins/workspace -type d -mtime +30 -exec rm -rf {} \; 2>/dev/null
    
    echo "Jenkins home size after:"
    sudo du -sh /var/lib/jenkins
fi

echo ""
echo "=== Step 6: Cleaning Temporary Files ==="
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

echo ""
echo "=== Step 7: Final Disk Usage ==="
df -h | grep "/$"

echo ""
echo "=== Cleanup Complete ==="
echo "If disk is still full, check:"
echo "  - Docker volumes: docker volume ls"
echo "  - Large files: sudo find / -type f -size +100M 2>/dev/null"
echo "  - Consider resizing EBS volume if needed"

