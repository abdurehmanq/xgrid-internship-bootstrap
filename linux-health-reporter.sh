#!/bin/bash

# ==========================================
# 1. Gather Metrics
# ==========================================

# CPU Usage
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

# Memory Usage
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
MEM_FREE=$(free -m | awk '/Mem:/ {print $4}')

# Disk Usage (root partition)
DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
DISK_FREE=$(df -h / | awk 'NR==2 {print $4}')

# ==========================================
# 2. Process Data Handling
# ==========================================
# We still use jq here to safely build the array of processes. 
# This prevents manual awk loops from leaving a trailing comma or 
# breaking if a process name has a weird character.
TOP_PROCESSES=$(ps -eo pid,comm,%cpu --no-headers --sort=-%cpu | head -n 3 | jq -R -s '
  split("\n") | map(select(length > 0)) | map(
    gsub("^ +"; "") | gsub(" +"; " ") | split(" ") | {
      pid: (.[0] | tonumber),
      name: .[1],
      cpu: (.[2] + "%")
    }
  )
')

# ==========================================
# 3. JSON Output via EOF
# ==========================================
# The EOF block is fed directly into `jq '.'` which parses, validates, 
# and pretty-prints the final output.
jq '.' <<EOF
{
  "cpu_usage_percent": "$CPU_USAGE",
  "memory": {
    "total_mb": "$MEM_TOTAL",
    "used_mb": "$MEM_USED",
    "free_mb": "$MEM_FREE"
  },
  "disk": {
    "total": "$DISK_TOTAL",
    "used": "$DISK_USED",
    "free": "$DISK_FREE"
  },
  "top_processes": $TOP_PROCESSES
}
EOF
