#!/bin/bash

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
LOG_FILE=/var/log/nginx/health-check.log

echo "[$TIMESTAMP] Starting health checks" >> $LOG_FILE

# Check backend servers using API endpoints
BACKEND1="18.207.116.100:8080"
BACKEND2="100.27.215.37:8080"

for backend in $BACKEND1 $BACKEND2; do
    # Try API endpoint since actuator is not available
    if curl -f -s --max-time 10 "http://$backend/api/employees" > /dev/null; then
        echo "[$TIMESTAMP] Backend $backend: HEALTHY (API responding)" >> $LOG_FILE
    else
        echo "[$TIMESTAMP] Backend $backend: UNHEALTHY" >> $LOG_FILE
        logger "Backend server $backend is unhealthy"
    fi
done

# Check local services
if systemctl is-active --quiet nginx; then
    echo "[$TIMESTAMP] Nginx: RUNNING" >> $LOG_FILE
else
    echo "[$TIMESTAMP] Nginx: STOPPED" >> $LOG_FILE
    logger "Nginx service is down"
fi