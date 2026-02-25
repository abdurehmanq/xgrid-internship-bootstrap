#!/bin/bash

# CPU usage
cpu=$(top -bn1 | awk -F',' '/Cpu/ {print $1}' | awk '{print $2}')

# Memory usage %
memory=$(free | awk '/Mem/ {printf("%.2f"), $3/$2 * 100.0}')

# Disk usage %
disk=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

# Top process by CPU
process=$(ps -eo comm,%cpu --sort=-%cpu | awk 'NR==2 {print $1}')

# Safely construct and pretty-print JSON using jq
jq -n \
  --arg cpu "${cpu}%" \
  --arg memory "${memory}%" \
  --arg disk "${disk}%" \
  --arg process "${process}" \
  '{
    cpu_usage: $cpu, 
    memory_usage: $memory, 
    disk_usage: $disk, 
    top_process: $process
  }'
