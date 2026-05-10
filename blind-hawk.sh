#!/bin/bash

# blind-hawk.sh - Enhanced VAPT Scanner
# Usage: ./blind-hawk.sh <target> [output_file]

TARGET=$1
OUTPUT_FILE=${2:-"full_vapt_report.txt"}
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="scan_${TIMESTAMP}.log"

if [ -z "$TARGET" ]; then
    echo "Usage: $0 <target> [output_file]"
    exit 1
fi

# Create output directory if needed
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Function to run Nmap with proper flags
run_nmap() {
    local args="$1"
    local output="$2"
    echo "Running: nmap $args $TARGET" | tee -a $LOG_FILE
    nmap $args $TARGET 2>>$LOG_FILE | tee -a $OUTPUT_FILE
}

# Start scan
echo "Starting VAPT scan for $TARGET" > $OUTPUT_FILE
echo "----------------------------------------" >> $OUTPUT_FILE
echo "Target: $TARGET" >> $OUTPUT_FILE
echo "Scan Date: $(date)" >> $OUTPUT_FILE
echo "Log File: $LOG_FILE" >> $OUTPUT_FILE
echo "----------------------------------------" >> $OUTPUT_FILE

# Step 1: Basic port scan (fast)
echo "Running basic port scan..." >> $OUTPUT_FILE
run_nmap "-p- --max-rate 5000 --min-rate 1000" $OUTPUT_FILE

# Step 2: Service version detection
echo "Running service version detection..." >> $OUTPUT_FILE
run_nmap "-sV --version-intensity 9" $OUTPUT_FILE

# Step 3: Vulnerability scanning
echo "Running vulnerability scanning..." >> $OUTPUT_FILE
run_nmap "-sV --script=vuln --script-timeout 60s" $OUTPUT_FILE

# Step 4: Additional scans
echo "Running additional scans..." >> $OUTPUT_FILE

# OS detection
echo "OS Detection:" >> $OUTPUT_FILE
run_nmap "-O" $OUTPUT_FILE

# HTTP-specific scans
if grep -q "80/tcp\|443/tcp" $OUTPUT_FILE; then
    echo "HTTP/HTTPS scans:" >> $OUTPUT_FILE
    run_nmap "-sV --script=http-*" $OUTPUT_FILE
fi

# FTP scans
if grep -q "21/tcp" $OUTPUT_FILE; then
    echo "FTP scans:" >> $OUTPUT_FILE
    run_nmap "-sV --script=ftp-*" $OUTPUT_FILE
fi

echo "----------------------------------------" >> $OUTPUT_FILE
echo "Scan completed successfully" >> $OUTPUT_FILE
echo "----------------------------------------" >> $OUTPUT_FILE

echo "VAPT report generated at $OUTPUT_FILE"
