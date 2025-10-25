#!/bin/bash

# System Health Monitoring Script for WiseCow Application
# Monitors CPU, memory, disk space, and running processes

LOG_FILE="/tmp/wisecow-health.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Thresholds
CPU_THRESHOLD=80
MEMORY_THRESHOLD=80
DISK_THRESHOLD=85
PROCESS_THRESHOLD=50

log_alert() {
    echo "[ALERT] $TIMESTAMP - $1" | tee -a "$LOG_FILE"
    echo "ALERT: $1"
}

log_info() {
    echo "[INFO] $TIMESTAMP - $1" | tee -a "$LOG_FILE"
}

check_cpu_usage() {
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    cpu_usage=${cpu_usage%.*}

    log_info "CPU Usage: ${cpu_usage}%"

    if [ "$cpu_usage" -gt "$CPU_THRESHOLD" ]; then
        log_alert "High CPU usage detected: ${cpu_usage}% (Threshold: ${CPU_THRESHOLD}%) - May affect WiseCow performance"
        return 1
    fi
    return 0
}

check_memory_usage() {
    local memory_info
    memory_info=$(free | grep Mem)
    local total_mem=$(echo "$memory_info" | awk '{print $2}')
    local used_mem=$(echo "$memory_info" | awk '{print $3}')
    local memory_percent=$(( used_mem * 100 / total_mem ))

    log_info "Memory Usage: ${memory_percent}%"

    if [ "$memory_percent" -gt "$MEMORY_THRESHOLD" ]; then
        log_alert "High memory usage detected: ${memory_percent}% (Threshold: ${MEMORY_THRESHOLD}%) - May impact WiseCow containers"
        return 1
    fi
    return 0
}

check_disk_usage() {
    local disk_usage
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

    log_info "Disk Usage: ${disk_usage}%"

    if [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        log_alert "High disk usage detected: ${disk_usage}% (Threshold: ${DISK_THRESHOLD}%) - Could affect WiseCow storage"
        return 1
    fi
    return 0
}

check_running_processes() {
    local total_processes
    total_processes=$(ps aux | wc -l)
    total_processes=$((total_processes - 1))

    log_info "Running Processes: ${total_processes}"

    if [ "$total_processes" -gt "$PROCESS_THRESHOLD" ]; then
        log_alert "High number of running processes: ${total_processes} (Threshold: ${PROCESS_THRESHOLD}) - System may be overloaded"
        return 1
    fi
    return 0
}

check_wisecow_containers() {
    local wisecow_containers
    wisecow_containers=$(docker ps --filter "name=wisecow" --format "{{.Names}}" | wc -l)

    log_info "WiseCow containers running: ${wisecow_containers}"

    if [ "$wisecow_containers" -eq 0 ]; then
        log_alert "No WiseCow containers running - Application may be down"
        return 1
    elif [ "$wisecow_containers" -lt 3 ]; then
        log_alert "Only ${wisecow_containers} WiseCow containers running - Expected 3 replicas"
        return 1
    fi
    return 0
}

check_kubernetes_pods() {
    if command -v kubectl >/dev/null 2>&1; then
        local wisecow_pods
        wisecow_pods=$(kubectl get pods -l app=wisecow --no-headers 2>/dev/null | grep Running | wc -l)

        if [ "$wisecow_pods" -eq 0 ]; then
            log_info "WiseCow Kubernetes pods: 0 (Kubernetes may not be available)"
            return 0
        fi

        log_info "WiseCow Kubernetes pods running: ${wisecow_pods}"

        if [ "$wisecow_pods" -lt 3 ]; then
            log_alert "Only ${wisecow_pods} WiseCow pods running - Expected 3 replicas"
            return 1
        fi
    else
        log_info "kubectl not available - skipping Kubernetes checks"
    fi
    return 0
}

generate_report() {
    echo "=========================================="
    echo "   WISECOW SYSTEM HEALTH MONITORING REPORT"
    echo "=========================================="
    echo "Timestamp: $TIMESTAMP"
    echo "Log File: $LOG_FILE"
    echo "Application: WiseCow"
    echo "Thresholds:"
    echo "  CPU: ${CPU_THRESHOLD}%"
    echo "  Memory: ${MEMORY_THRESHOLD}%"
    echo "  Disk: ${DISK_THRESHOLD}%"
    echo "  Processes: ${PROCESS_THRESHOLD}"
    echo "=========================================="
    
    if [ -f "$LOG_FILE" ]; then
        echo "Recent alerts:"
        grep "ALERT" "$LOG_FILE" | tail -5
    fi
}

main() {
    echo "Starting WiseCow System Health Monitoring..."
    echo "Application: WiseCow"
    echo "Monitoring thresholds:"
    echo "  CPU: ${CPU_THRESHOLD}%"
    echo "  Memory: ${MEMORY_THRESHOLD}%"
    echo "  Disk: ${DISK_THRESHOLD}%"
    echo "  Processes: ${PROCESS_THRESHOLD}"
    echo ""

    log_info "=== WISECOW SYSTEM HEALTH CHECK STARTED ==="

    local alerts=0

    check_cpu_usage || alerts=$((alerts + 1))
    check_memory_usage || alerts=$((alerts + 1))
    check_disk_usage || alerts=$((alerts + 1))
    check_running_processes || alerts=$((alerts + 1))
    check_wisecow_containers || alerts=$((alerts + 1))
    check_kubernetes_pods || alerts=$((alerts + 1))

    log_info "=== WISECOW SYSTEM HEALTH CHECK COMPLETED ==="

    generate_report

    if [ "$alerts" -eq 0 ]; then
        echo "WISECOW SYSTEM STATUS: HEALTHY - No alerts generated"
        exit 0
    else
        echo "WISECOW SYSTEM STATUS: NEEDS ATTENTION - $alerts alert(s) generated"
        exit 1
    fi
}

main

chmod +x scripts/system-health-monitor.sh
