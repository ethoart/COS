#!/bin/bash
echo "🤖 Starting Android layer..."

# Start waydroid container
sudo systemctl start waydroid-container

# Wait for container
sleep 3

# Start waydroid session
waydroid session start &

# Wait for session
sleep 5

# Launch Android UI
waydroid show-full-ui &

echo "✅ Android started"
echo "Use: waydroid app install app.apk"
echo "Use: waydroid app list"
