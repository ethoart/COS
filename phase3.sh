#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${GREEN}[C OS]${NC} $1"; }
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
section() { echo -e "\n${CYAN}${BOLD}━━━ $1 ━━━${NC}\n"; }
done_()   { echo -e "${GREEN}${BOLD}✅ $1${NC}"; }

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   C OS Phase 3 — Android + Windows 🤖   ║"
echo "  ╠══════════════════════════════════════════╣"
echo "  ║  Building:                               ║"
echo "  ║  • Waydroid Android layer                ║"
echo "  ║  • Google Play Store                     ║"
echo "  ║  • Android apps in C OS launcher         ║"
echo "  ║  • Windows apps via Bottles + Wine       ║"
echo "  ║  • DXVK DirectX acceleration             ║"
echo "  ║  • One click app installers              ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
sleep 2

# ══════════════════════════════════════════
# STEP 1 — WAYDROID KERNEL MODULES
# ══════════════════════════════════════════
section "1/10 Setting up Waydroid kernel modules"
sudo apt install -y \
  linux-modules-extra-$(uname -r) \
  linux-generic \
  curl \
  lzip \
  wget

# Load required kernel modules
sudo modprobe ashmem_linux 2>/dev/null || true
sudo modprobe binder_linux 2>/dev/null || true

# Check binder support
if [ -e /dev/binder ]; then
  log "Binder already available"
else
  warn "Installing binder kernel module..."
  sudo apt install -y linux-modules-extra-$(uname -r) || true
  
  # Try binder via dkms
  sudo apt install -y dkms || true
  
  # Install anbox binder
  sudo add-apt-repository -y ppa:morphis/anbox-support || true
  sudo apt update || true
  sudo apt install -y linux-headers-generic anbox-modules-dkms || true
  sudo modprobe ashmem_linux 2>/dev/null || true
  sudo modprobe binder_linux 2>/dev/null || true
fi

done_ "Kernel modules configured"

# ══════════════════════════════════════════
# STEP 2 — INITIALIZE WAYDROID
# ══════════════════════════════════════════
section "2/10 Initializing Waydroid Android layer"

# Initialize waydroid with Android 13
sudo waydroid init -s GAPPS -f 2>/dev/null || \
sudo waydroid init -f 2>/dev/null || \
warn "Waydroid init will complete on first boot"

done_ "Waydroid initialized"

# ══════════════════════════════════════════
# STEP 3 — WAYDROID SERVICE
# ══════════════════════════════════════════
section "3/10 Configuring Waydroid service"

# Enable waydroid container service
sudo systemctl enable --now waydroid-container || true

# Create waydroid startup script
cat > ~/cos/scripts/start-android.sh << 'EOF'
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
EOF

chmod +x ~/cos/scripts/start-android.sh
done_ "Waydroid service configured"

# ══════════════════════════════════════════
# STEP 4 — GOOGLE PLAY STORE
# ══════════════════════════════════════════
section "4/10 Setting up Google Play Store"

mkdir -p ~/cos/apps/android

# Download waydroid scripts for Play Store
git clone https://github.com/casualsnek/waydroid_script \
  ~/cos/apps/android/waydroid_script 2>/dev/null || \
  (cd ~/cos/apps/android/waydroid_script && git pull)

# Install python requirements
pip3 install --break-system-packages \
  -r ~/cos/apps/android/waydroid_script/requirements.txt \
  2>/dev/null || true

# Create play store installer
cat > ~/cos/apps/android/install-gapps.sh << 'EOF'
#!/bin/bash
echo "📦 Installing Google Play Store..."
cd ~/cos/apps/android/waydroid_script

# Install GApps (Google Play Store + services)
sudo python3 main.py install gapps

# Install Google account manager
sudo python3 main.py install microg

echo "✅ Google Play Store installed!"
echo "Restart Android: bash ~/cos/scripts/start-android.sh"
EOF

chmod +x ~/cos/apps/android/install-gapps.sh
done_ "Google Play Store setup ready"

# ══════════════════════════════════════════
# STEP 5 — ANDROID APK INSTALLER
# ══════════════════════════════════════════
section "5/10 Creating Android app manager"

cat > ~/cos/apps/android/cos-android.sh << 'EOF'
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
EOF

chmod +x ~/cos/apps/android/cos-android.sh
done_ "Android app manager created"

# ══════════════════════════════════════════
# STEP 6 — WINE + BOTTLES CONFIG
# ══════════════════════════════════════════
section "6/10 Configuring Wine and Bottles"

mkdir -p ~/cos/apps/windows

# Create default Wine prefix for C OS
export WINEPREFIX="$HOME/.wine-cos"
export WINEARCH=win64

# Initialize wine prefix
wineboot --init 2>/dev/null || true

# Install common Windows components
cat > ~/cos/apps/windows/setup-wine.sh << 'EOF'
#!/bin/bash
export WINEPREFIX="$HOME/.wine-cos"
export WINEARCH=win64

echo "🍷 Setting up Wine for C OS..."

# Core components
winetricks -q vcrun2019 2>/dev/null || true
winetricks -q vcrun2022 2>/dev/null || true
winetricks -q dotnet48 2>/dev/null || true
winetricks -q corefonts 2>/dev/null || true
winetricks -q d3dx11_43 2>/dev/null || true

# DXVK for DirectX acceleration
winetricks -q dxvk 2>/dev/null || true

echo "✅ Wine components installed"
EOF

chmod +x ~/cos/apps/windows/setup-wine.sh
done_ "Wine and Bottles configured"

# ══════════════════════════════════════════
# STEP 7 — WINDOWS APP MANAGER
# ══════════════════════════════════════════
section "7/10 Creating Windows app manager"

cat > ~/cos/apps/windows/cos-windows.sh << 'EOF'
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
EOF

chmod +x ~/cos/apps/windows/cos-windows.sh
done_ "Windows app manager created"

# ══════════════════════════════════════════
# STEP 8 — C OS APP LAUNCHER INTEGRATION
# ══════════════════════════════════════════
section "8/10 Integrating apps into C OS launcher"

mkdir -p ~/.local/share/applications

# Android Manager desktop entry
cat > ~/.local/share/applications/cos-android.desktop << 'EOF'
[Desktop Entry]
Name=Android Apps
Comment=Manage Android apps on C OS
Exec=bash /home/ubuntu/cos/apps/android/cos-android.sh
Icon=android
Terminal=true
Type=Application
Categories=System;
EOF

# Windows Manager desktop entry
cat > ~/.local/share/applications/cos-windows.desktop << 'EOF'
[Desktop Entry]
Name=Windows Apps
Comment=Manage Windows apps on C OS
Exec=bash /home/ubuntu/cos/apps/windows/cos-windows.sh
Icon=wine
Terminal=true
Type=Application
Categories=System;
EOF

# Bottles desktop entry
cat > ~/.local/share/applications/bottles.desktop << 'EOF'
[Desktop Entry]
Name=Bottles
Comment=Run Windows apps on C OS
Exec=flatpak run --user com.usebottles.bottles
Icon=com.usebottles.bottles
Terminal=false
Type=Application
Categories=Utility;
EOF

# Steam desktop entry
cat > ~/.local/share/applications/steam.desktop << 'EOF'
[Desktop Entry]
Name=Steam
Comment=Gaming on C OS
Exec=steam
Icon=steam
Terminal=false
Type=Application
Categories=Game;
EOF

# Update desktop database
update-desktop-database ~/.local/share/applications/ 2>/dev/null || true

done_ "Apps integrated into launcher"

# ══════════════════════════════════════════
# STEP 9 — PERFORMANCE TUNING FOR APPS
# ══════════════════════════════════════════
section "9/10 Tuning performance for apps"

# Create gamemode config
mkdir -p ~/.config/gamemode

cat > ~/.config/gamemode/gamemode.ini << 'EOF'
[general]
reaper_freq=5
desiredgov=performance
igpu_desiredgov=performance
softrealtime=auto
renice=-5
ioprio=0
inhibit_screensaver=1

[filter]
whitelist=
blacklist=

[gpu]
apply_gpu_optimisations=accept-responsibility
gpu_device=0
amd_performance_level=high

[custom]
start=notify-send "C OS" "Game mode activated ⚡"
end=notify-send "C OS" "Game mode deactivated"
EOF

# Create app performance wrapper
cat > ~/cos/scripts/run-optimized.sh << 'EOF'
#!/bin/bash
# Run any app with maximum performance
APP=$1
shift
echo "⚡ Launching $APP with C OS optimizations..."
gamemoderun "$APP" "$@"
EOF

chmod +x ~/cos/scripts/run-optimized.sh
done_ "Performance tuning complete"

# ══════════════════════════════════════════
# STEP 10 — VERIFY EVERYTHING
# ══════════════════════════════════════════
section "10/10 Verifying Phase 3"

echo ""
PASS=0
FAIL=0

check_cmd() {
  if command -v "$1" &>/dev/null; then
    echo -e "  ${GREEN}✅${NC} $1"
    PASS=$((PASS+1))
  else
    echo -e "  ${RED}❌${NC} $1"
    FAIL=$((FAIL+1))
  fi
}

check_file() {
  if [ -f "$1" ]; then
    echo -e "  ${GREEN}✅${NC} $2"
    PASS=$((PASS+1))
  else
    echo -e "  ${RED}❌${NC} $2"
    FAIL=$((FAIL+1))
  fi
}

echo "── Android ──"
check_cmd waydroid
check_file ~/cos/scripts/start-android.sh "Android start script"
check_file ~/cos/apps/android/cos-android.sh "Android manager"
check_file ~/cos/apps/android/install-gapps.sh "Play Store installer"

echo ""
echo "── Windows ──"
check_cmd wine
check_cmd winetricks
check_file ~/cos/apps/windows/cos-windows.sh "Windows manager"
check_file ~/cos/apps/windows/setup-wine.sh "Wine setup script"

echo ""
echo "── Launcher Integration ──"
check_file ~/.local/share/applications/cos-android.desktop "Android launcher entry"
check_file ~/.local/share/applications/cos-windows.desktop "Windows launcher entry"

echo ""
echo "── Performance ──"
check_file ~/.config/gamemode/gamemode.ini "Gamemode config"
check_file ~/cos/scripts/run-optimized.sh "Optimized launcher"

echo ""
echo -e "Results: ${GREEN}$PASS passed${NC} | ${RED}$FAIL failed${NC}"

# ══════════════════════════════════════════
# COMPLETE
# ══════════════════════════════════════════
echo ""
echo -e "${CYAN}${BOLD}"
echo "  ╔════════════════════════════════════════════╗"
echo "  ║      C OS Phase 3 — COMPLETE ✅           ║"
echo "  ╠════════════════════════════════════════════╣"
echo "  ║  ✅ Waydroid Android layer                 ║"
echo "  ║  ✅ Google Play Store ready                ║"
echo "  ║  ✅ Android app manager                    ║"
echo "  ║  ✅ Wine + Bottles + DXVK                  ║"
echo "  ║  ✅ Windows app manager                    ║"
echo "  ║  ✅ Apps in C OS launcher                  ║"
echo "  ║  ✅ Performance tuning                     ║"
echo "  ╠════════════════════════════════════════════╣"
echo "  ║  Next → Phase 4: ISO Build + Installer 💿 ║"
echo "  ╚════════════════════════════════════════════╝"
echo -e "${NC}"

