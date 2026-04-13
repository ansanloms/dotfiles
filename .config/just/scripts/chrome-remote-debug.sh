#!/bin/bash

# Chrome をリモートデバッグモードで起動し、socat で外部からアクセス可能にする。
# Usage: chrome-remote-debug.bash [CHROME_PORT] [SOCAT_PORT]
CHROME_PORT=${1:-9223}
SOCAT_PORT=${2:-9222}

cleanup() {
  echo "Shutting down..."
  kill $CHROME_PID $SOCAT_PID 2>/dev/null
  wait
  exit 0
}

trap cleanup SIGINT SIGTERM

rm -rf /tmp/chrome-remote-debug

socat TCP-LISTEN:$SOCAT_PORT,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:$CHROME_PORT &
SOCAT_PID=$!

google-chrome \
  --remote-debugging-port=$CHROME_PORT \
  --user-data-dir=/tmp/chrome-remote-debug \
  --no-first-run \
  --disable-extensions &
CHROME_PID=$!

echo "Chrome PID: $CHROME_PID"
echo "Socat PID: $SOCAT_PID"
echo "Listening on 0.0.0.0:$SOCAT_PORT -> 127.0.0.1:$CHROME_PORT"
echo "Press Ctrl+C to stop"

wait
