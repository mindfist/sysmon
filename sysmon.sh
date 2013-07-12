#!/bin/bash

printf $1 && awk '/^cpu / { printf " %d %d %d %d", $2, $3, $4, $5 }' < /proc/stat && awk '/MemTotal:/{ printf " %s", $2} /MemFree:/{printf " %s", $2} /Buffers: /{printf " %s", $2} /Cached:/{printf " %s ", $2}' < /proc/meminfo && awk -v interface="eth0" 'BEGIN { gsub(/\./, "\\.", interface) } $1 ~ "^" interface ":" { split($0, a, /: */); $0 = a[2]; printf "%d %d ",$1 ,$9 }' /proc/net/dev && awk '{printf "%2.2f ",$2}' < /proc/loadavg && iostat| awk '/xvda/{print $5 " " $6 " " $3 " " $4 " " $2}' | head -1

# EC2 machine
#printf $1 && awk '/^cpu / { printf " %d %d %d %d", $2, $3, $4, $5 }' < /proc/stat && awk '/MemTotal:/{ printf " %s", $2} /MemFree:/{printf " %s", $2} /Buffers: /{printf " %s", $2} /Cached:/{printf " %s ", $2}' < /proc/meminfo && awk -v interface="eth0" 'BEGIN { gsub(/\./, "\\.", interface) } $1 ~ "^" interface ":" { split($0, a, /: */); $0 = a[2]; printf "%d %d ",$1 ,$9 }' /proc/net/dev && awk '{printf "%2.2f ",$2}' < /proc/loadavg && iostat| awk '/sdb/{print $5 " " $6 " " $3 " " $4}' | head -1
