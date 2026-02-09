#!/bin/bash

cleanup() {
  echo "Shutting down..."
  kill $CHROME_PID $SOCAT_PID 2>/dev/null
  wait
  exit 0
}

trap cleanup SIGINT SIGTERM

rm -rf /tmp/chrome-remote-debug

# chrome
google-chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-remote-debug \
  --no-first-run \
  --disable-extensions &
CHROME_PID=$!

# Chromeが起動するのを待つ
sleep 2

# socat
socat TCP-LISTEN:9223,fork,reuseaddr,bind=0.0.0.0 TCP:127.0.0.1:9222 &
SOCAT_PID=$!

echo "Chrome PID: $CHROME_PID"
echo "Socat PID: $SOCAT_PID"
echo "Listening on 0.0.0.0:9223 -> 127.0.0.1:9222"
echo "Press Ctrl+C to stop"

wait
