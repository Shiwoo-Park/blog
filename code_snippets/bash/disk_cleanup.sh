#!/bin/bash

# Disk cleanup script for Linux servers
# Removes unused Docker resources, old system logs, and YUM cache to free up disk space

echo "====== Start Clean Disk ======"
df -h

# Docker Cleanup
docker container prune -f
docker image prune -f
docker volume prune -f
docker network prune -f
docker system prune -a --volumes -f

# Jenkins Cleanup
#sudo rm -rf /var/lib/jenkins/workspace/*
#sudo rm -rf /var/lib/jenkins/jobs/*/builds/*
#sudo rm -rf /var/lib/jenkins/.cache/*

# System Logs Cleanup
sudo journalctl --vacuum-time=7d
#sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# YUM Package Cleanup
sudo yum clean all

echo "====== Clean Disk complete!!! ======"
df -h