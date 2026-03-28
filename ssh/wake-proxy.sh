#!/bin/bash
HOST="$1"
PORT="$2"
MAC="xx:xx:xx:xx:xx:xx"  # Replace with your server's MAC
# Try immediate connection first
if nc -z "$HOST" "$PORT" 2>/dev/null; then
    exec nc "$HOST" "$PORT"
fi
# Send wake-on-LAN packet
wakeonlan "$MAC" >/dev/null 2>&1
# Wait and retry
for i in $(seq 1 15); do
    sleep 3
    if nc -z "$HOST" "$PORT" 2>/dev/null; then
        exec nc "$HOST" "$PORT"
    fi
done
echo "Failed to connect to $HOST:$PORT after wake attempt" >&2
exit 1
