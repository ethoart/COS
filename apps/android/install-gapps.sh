#!/bin/bash
echo "📦 Installing Google Play Store..."
cd ~/cos/apps/android/waydroid_script

# Install GApps (Google Play Store + services)
sudo python3 main.py install gapps

# Install Google account manager
sudo python3 main.py install microg

echo "✅ Google Play Store installed!"
echo "Restart Android: bash ~/cos/scripts/start-android.sh"
