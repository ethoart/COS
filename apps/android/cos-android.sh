#!/bin/bash
# C OS Android App Manager

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}C OS Android Manager${NC}"
echo "━━━━━━━━━━━━━━━━━━━━"
echo "1) Start Android"
echo "2) Install APK"
echo "3) List apps"
echo "4) Remove app"
echo "5) Open Play Store"
echo "6) Stop Android"
echo ""
read -p "Choose option: " OPT

case $OPT in
  1)
    bash ~/cos/scripts/start-android.sh
    ;;
  2)
    read -p "APK path: " APK
    waydroid app install "$APK"
    echo -e "${GREEN}✅ App installed${NC}"
    ;;
  3)
    waydroid app list
    ;;
  4)
    read -p "Package name: " PKG
    waydroid app remove "$PKG"
    echo -e "${GREEN}✅ App removed${NC}"
    ;;
  5)
    waydroid session start &
    sleep 3
    waydroid app launch com.android.vending
    ;;
  6)
    waydroid session stop
    sudo systemctl stop waydroid-container
    echo -e "${GREEN}✅ Android stopped${NC}"
    ;;
  *)
    echo "Invalid option"
    ;;
esac
