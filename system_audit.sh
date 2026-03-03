#!/bin/bash

# ==========================================
# 1. Gather Audit Data
# ==========================================
CURRENT_DATE=$(date)

# Grab disk usage for the root partition
DISK_USAGE=$(df -h /)

# Grab listening ports (requires sudo for full process visibility)
OPEN_PORTS=$(sudo ss -tulpn | grep LISTEN)

# Grab running Docker containers safely
# -z checks if the output of 'docker ps -q' (which lists only IDs) is completely empty
if [ -z "$(docker ps -q 2>/dev/null)" ]; then
    DOCKER_CONTAINERS="No containers running."
else
    DOCKER_CONTAINERS=$(docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null)
fi

# ==========================================
# 2. Output Report via EOF (HereDoc)
# ==========================================
cat <<EOF
=======================================
       LINUX SYSTEM AUDIT REPORT       
=======================================
Date: $CURRENT_DATE

[1] DISK USAGE:
$DISK_USAGE

[2] OPEN LISTENING PORTS:
$OPEN_PORTS

[3] RUNNING DOCKER CONTAINERS:
$DOCKER_CONTAINERS

=======================================
            AUDIT COMPLETE             
=======================================
EOF