#!/bin/bash
APK=$1
[ -z "$APK" ] && echo "Usage: install-apk.sh app.apk" && exit 1
echo "Installing APK: $APK"
waydroid app install "$APK"
echo "✅ Android app installed"
