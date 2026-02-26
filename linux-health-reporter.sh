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
# Instead of using awk to manually build a JSON string, we pass the raw text 
# to jq. This safely handles quotes, escapes characters, and builds a strict JSON array.
TOP_PROCESSES_JSON=$(ps -eo pid,comm,%cpu --no-headers --sort=-%cpu | head -n 3 | jq -R -s '
  split("\n") | map(select(length > 0)) | map(
    gsub("^ +"; "") | gsub(" +"; " ") | split(" ") | {
      pid: (.[0] | tonumber),
      name: .[1],
      cpu: (.[2] + "%")
    }
  )
')

# ==========================================
# 3. Safe JSON Construction & Pretty Printing
# ==========================================
# --arg passes shell variables as safe JSON strings.
# --argjson passes our process variable as an actual JSON array, not a string.
jq -n \
  --arg cpu "$CPU_USAGE" \
  --arg mt "$MEM_TOTAL" \
  --arg mu "$MEM_USED" \
  --arg mf "$MEM_FREE" \
  --arg dt "$DISK_TOTAL" \
  --arg du "$DISK_USED" \
  --arg df "$DISK_FREE" \
  --argjson procs "$TOP_PROCESSES_JSON" \
  '{
    cpu_usage_percent: $cpu,
    memory: {
      total_mb: $mt,
      used_mb: $mu,
      free_mb: $mf
    },
    disk: {
      total: $dt,
      used: $du,
      free: $df
    },
    top_processes: $procs
  }'
