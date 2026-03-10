#!/bin/bash
# C OS Windows App Manager

CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${CYAN}C OS Windows App Manager${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1) Open Bottles (install Windows apps)"
echo "2) Run .exe file"
echo "3) Install Wine components"
echo "4) Open Steam (Windows games)"
echo "5) Configure DXVK"
echo "6) Wine settings"
echo ""
read -p "Choose option: " OPT

case $OPT in
  1)
    flatpak run --user com.usebottles.bottles &
    echo -e "${GREEN}✅ Bottles opened${NC}"
    ;;
  2)
    read -p "EXE path: " EXE
    WINEPREFIX="$HOME/.wine-cos" wine "$EXE"
    ;;
  3)
    bash ~/cos/apps/windows/setup-wine.sh
    ;;
  4)
    steam &
    echo -e "${GREEN}✅ Steam opened${NC}"
    ;;
  5)
    WINEPREFIX="$HOME/.wine-cos" winetricks dxvk
    echo -e "${GREEN}✅ DXVK configured${NC}"
    ;;
  6)
    WINEPREFIX="$HOME/.wine-cos" winecfg
    ;;
  *)
    echo "Invalid option"
    ;;
esac
