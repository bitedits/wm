#!/bin/bash
# run_wm.sh - Script to launch the Erlang Window Manager in Xephyr on macOS

echo "Starting XQuartz (if not already running)..."
open -a XQuartz
sleep 1

echo "Starting Xephyr on Display :1 (inside XQuartz :0)..."
# Launch Xephyr inside the host X server (:0) and export its own display as :1
DISPLAY=:0 Xephyr -ac -screen 1024x768 -br -reset -terminate 2> /dev/null :1 &
XEPHYR_PID=$!

# Wait a moment for Xephyr to initialize
sleep 1

echo "Opening two test terminal windows (xterm) in 6 seconds (waiting for Erlang to boot)..."
# Wait 1 seconds for Erlang to compile and boot so it catches the MapRequests!
# Use white and gray backgrounds so they don't blend into Xephyr's black screen
(sleep 1; DISPLAY=:1 xterm -bg white -fg black -geometry 60x30+50+50 & DISPLAY=:1 xterm -bg gray -fg black -geometry 60x30+450+50) &

echo ""
echo "========================================================="
echo "The Window Manager is now starting inside the Xephyr window!"
echo "Type 'q().' or press Ctrl+C twice in the Erlang shell to stop."
echo "========================================================="

# Launch the Erlang app in the FOREGROUND so it doesn't instantly die from EOF on stdin
DISPLAY=:1 rebar3 shell --eval "application:start(wm)."

echo "Cleaning up..."
kill $XEPHYR_PID 2>/dev/null
