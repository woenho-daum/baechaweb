#!/bin/bash

# 가상환경 및 경로 설정
GUNICORN_BIN="../.venv/bin/gunicorn"
CERT_FULLCHAIN="/etc/letsencrypt/live/baecha.duckdns.org/fullchain.pem"
CERT_PRIVKEY="/etc/letsencrypt/live/baecha.duckdns.org/privkey.pem"
ACCESS_LOG="gunicorn-access.log"
ERROR_LOG="gunicorn-error.log"

case "$1" in
    start)
        echo "Starting Gunicorn HTTPS Server..."
        $GUNICORN_BIN \
            --certfile=$CERT_FULLCHAIN \
            --keyfile=$CERT_PRIVKEY \
            --workers 2 --threads 2 \
            -b 0.0.0.0:443 \
            --access-logfile $ACCESS_LOG \
            --error-logfile $ERROR_LOG \
            app:app &
        echo "Gunicorn started successfully."
        ;;
    stop)
        echo "Stopping Gunicorn Server..."
        # gunicorn 프로세스들의 PID를 찾아 종료
        pkill -f "gunicorn.*app:app"
        echo "Gunicorn stopped."
        ;;
    status)
        $0 stat
        ;;
    stat)
        pstree -ap|grep guni|grep "baecha"
        ;;
    restart)
        $0 stop
        sleep 1
        $0 start
        ;;
    *)
        echo ""
        echo "Usage: $0 { start | stop | restart | stat | status }"
        echo ""
        exit 1
        ;;
esac
