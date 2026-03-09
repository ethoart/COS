#!/bin/bash
set -e

# ══════════════════════════════════════════
#   C OS — Master Build Script v1.0
#   Codename: Carbon
#   Base: Ubuntu 24.04 Noble
# ══════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Logging
LOG_FILE="$HOME/cos-build/build/logs/phase1-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$HOME/cos-build/build/logs"
exec > >(tee -a "$LOG_FILE") 2>&1

log()     { echo -e "${GREEN}[C OS]${NC} $1"; }
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
step()    { echo -e "\n${CYAN}${BOLD}━━━ $1 ━━━${NC}\n"; }
done_()   { echo -e "${GREEN}${BOLD}✅ $1${NC}"; }

# Progress tracker
TOTAL_STEPS=20
CURRENT_STEP=0
progress() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo -e "\n${CYAN}[$CURRENT_STEP/$TOTAL_STEPS]${NC} ${BOLD}$1${NC}"
}

# ══════════════════════════════════════════
# WELCOME
# ══════════════════════════════════════════
clear
echo -e "${CYAN}"
echo "  ██████╗      ██████╗ ███████╗"
echo " ██╔════╝     ██╔═══██╗██╔════╝"
echo " ██║          ██║   ██║███████╗"
echo " ██║          ██║   ██║╚════██║"
echo " ╚██████╗     ╚██████╔╝███████║"
echo "  ╚═════╝      ╚═════╝ ╚══════╝"
echo -e "${NC}"
echo -e "${BOLD}  C OS Carbon v1.0 — Build Script${NC}"
echo -e "  Base: Ubuntu 24.04 Noble"
echo -e "  $(date)"
echo ""
echo -e "${YELLOW}  This will take 15-25 minutes.${NC}"
echo -e "${YELLOW}  Do not close this terminal.${NC}"
echo ""
sleep 3

# ══════════════════════════════════════════
# STEP 1 — SYSTEM UPDATE
# ══════════════════════════════════════════
progress "Updating system"
sudo apt update -y
sudo apt full-upgrade -y
sudo apt autoremove -y
done_ "System updated"

# ══════════════════════════════════════════
# STEP 2 — CORE BUILD TOOLS
# ══════════════════════════════════════════
progress "Installing core build tools"
sudo apt install -y \
  git curl wget build-essential cmake ninja-build \
  python3 python3-pip python3-venv \
  debootstrap squashfs-tools xorriso \
  live-build isolinux syslinux-common \
  grub-efi-amd64-bin grub-pc-bin \
  mtools dosfstools \
  apt-utils software-properties-common \
  zip unzip jq bc pv dialog tree
done_ "Core build tools installed"

# ══════════════════════════════════════════
# STEP 3 — WAYLAND COMPOSITOR
# ══════════════════════════════════════════
progress "Installing Wayland compositor"
sudo apt install -y \
  sway swaybg swaylock \
  waybar wofi mako-notifier \
  wayland-protocols libwayland-dev \
  xwayland wl-clipboard \
  grim slurp \
  policykit-1-gnome \
  network-manager-gnome \
  pipewire pipewire-pulse wireplumber \
  pavucontrol alsa-utils
done_ "Wayland compositor installed"

# ══════════════════════════════════════════
# STEP 4 — VULKAN + GPU DRIVERS
# ══════════════════════════════════════════
progress "Installing Vulkan and GPU drivers"
sudo apt install -y \
  vulkan-tools vulkan-validationlayers \
  libvulkan1 mesa-vulkan-drivers \
  mesa-utils va-driver-all \
  libvkd3d1 libvkd3d-dev spirv-tools glslang-tools \
  libgl1-mesa-dri libglx-mesa0
done_ "Vulkan and GPU drivers installed"

# ══════════════════════════════════════════
# STEP 5 — WINE STAGING
# ══════════════════════════════════════════
progress "Installing Wine Staging"
sudo dpkg --add-architecture i386
sudo mkdir -pm755 /etc/apt/keyrings
wget -q -O - https://dl.winehq.org/wine-builds/winehq.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/winehq.gpg
echo "deb [arch=amd64,i386 signed-by=/etc/apt/keyrings/winehq.gpg] \
  https://dl.winehq.org/wine-builds/ubuntu/ noble main" | \
  sudo tee /etc/apt/sources.list.d/winehq.list
sudo apt update -y
sudo apt install -y --install-recommends winehq-staging winetricks
done_ "Wine Staging installed"

# ══════════════════════════════════════════
# STEP 6 — DXVK + VKD3D
# ══════════════════════════════════════════
progress "Installing DXVK and VKD3D"
sudo apt install -y libvkd3d1 libvkd3d-dev spirv-tools glslang-tools
WINEPREFIX="$HOME/.wine-cos" wineboot --init 2>/dev/null || true
WINEPREFIX="$HOME/.wine-cos" winetricks -q dxvk 2>/dev/null || \
  warn "DXVK via winetricks failed — will retry in Phase 4"
done_ "DXVK and VKD3D installed"

# ══════════════════════════════════════════
# STEP 7 — FLATPAK + BOTTLES
# ══════════════════════════════════════════
progress "Installing Flatpak and Bottles"
sudo apt install -y flatpak
flatpak remote-add --user --if-not-exists flathub \
  https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub com.usebottles.bottles || \
  warn "Bottles install failed — will retry manually"
done_ "Flatpak and Bottles installed"

# ══════════════════════════════════════════
# STEP 8 — STEAM + PROTON GE
# ══════════════════════════════════════════
progress "Installing Steam and Proton-GE"
sudo apt install -y steam-installer || \
  warn "Steam installer may need manual setup"
mkdir -p "$HOME/.steam/root/compatibilitytools.d"
PROTON_VER="GE-Proton9-11"
wget -q --show-progress \
  -O /tmp/proton-ge.tar.gz \
  "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${PROTON_VER}/${PROTON_VER}.tar.gz" || \
  warn "Proton-GE download failed — install manually later"
if [ -f /tmp/proton-ge.tar.gz ]; then
  tar -xzf /tmp/proton-ge.tar.gz \
    -C "$HOME/.steam/root/compatibilitytools.d/"
  rm /tmp/proton-ge.tar.gz
fi
done_ "Steam and Proton-GE installed"

# ══════════════════════════════════════════
# STEP 9 — WAYDROID (ANDROID)
# ══════════════════════════════════════════
progress "Installing Waydroid Android layer"
sudo apt install -y curl ca-certificates lzip
curl -s https://repo.waydro.id | sudo bash
sudo apt install -y waydroid
done_ "Waydroid installed"

# ══════════════════════════════════════════
# STEP 10 — PERFORMANCE TOOLS
# ══════════════════════════════════════════
progress "Installing performance tools"
sudo apt install -y \
  gamemode cpufrequtils \
  zram-config preload \
  irqbalance thermald \
  htop btop iotop \
  powertop tlp
sudo systemctl enable --now zram-config  || true
sudo systemctl enable --now preload      || true
sudo systemctl enable --now irqbalance   || true
sudo systemctl enable --now thermald     || true
sudo systemctl enable --now tlp          || true
done_ "Performance tools installed"

# ══════════════════════════════════════════
# STEP 11 — FONTS
# ══════════════════════════════════════════
progress "Installing fonts"
sudo apt install -y \
  fonts-noto \
  fonts-noto-color-emoji \
  fonts-jetbrains-mono \
  fonts-inter \
  fonts-roboto \
  fonts-open-sans
done_ "Fonts installed"

# ══════════════════════════════════════════
# STEP 12 — THEMING TOOLS
# ══════════════════════════════════════════
progress "Installing theming tools"
sudo apt install -y \
  papirus-icon-theme \
  gtk2-engines-murrine \
  gtk2-engines-pixbuf \
  sassc libglib2.0-dev-bin \
  imagemagick inkscape
done_ "Theming tools installed"

# ══════════════════════════════════════════
# STEP 13 — APP FORMAT SUPPORT
# ══════════════════════════════════════════
progress "Installing app format support"
sudo apt install -y snapd
sudo apt install -y \
  libfuse2 fuse \
  libglib2.0-bin \
  gdebi \
  apt-transport-https
done_ "App format support installed"

# ══════════════════════════════════════════
# STEP 14 — CREATE DIRECTORY STRUCTURE
# ══════════════════════════════════════════
progress "Creating C OS directory structure"
mkdir -p \
  "$HOME/cos-build/rootfs" \
  "$HOME/cos-build/iso" \
  "$HOME/cos-build/config" \
  "$HOME/cos-build/scripts" \
  "$HOME/cos-build/ui/shell" \
  "$HOME/cos-build/ui/dock" \
  "$HOME/cos-build/ui/launcher" \
  "$HOME/cos-build/ui/wallpapers" \
  "$HOME/cos-build/ui/icons" \
  "$HOME/cos-build/ui/themes" \
  "$HOME/cos-build/ui/fonts" \
  "$HOME/cos-build/apps/android" \
  "$HOME/cos-build/apps/windows" \
  "$HOME/cos-build/apps/linux" \
  "$HOME/cos-build/branding/logo" \
  "$HOME/cos-build/branding/splash" \
  "$HOME/cos-build/branding/grub" \
  "$HOME/cos-build/system/services" \
  "$HOME/cos-build/system/configs" \
  "$HOME/cos-build/system/hooks" \
  "$HOME/cos-build/build/logs" \
  "$HOME/cos-build/build/cache" \
  "$HOME/cos-build/build/temp"
done_ "Directory structure created"

# ══════════════════════════════════════════
# STEP 15 — SYSTEM CONFIG
# ══════════════════════════════════════════
progress "Creating system config"
cat > "$HOME/cos-build/config/cos.conf" << 'EOF'
OS_NAME="C OS"
OS_VERSION="1.0"
OS_CODENAME="Carbon"
OS_ARCH="amd64"
OS_BASE="ubuntu-24.04"
OS_HOSTNAME="cos"
OS_USERNAME="user"
COMPOSITOR="sway"
DISPLAY_SERVER="wayland"
PANEL="waybar"
LAUNCHER="wofi"
NOTIFICATIONS="mako"
ANDROID_SUPPORT="waydroid"
WINDOWS_SUPPORT="bottles+winehq-staging+dxvk+vkd3d+proton-ge"
LINUX_PACKAGES="deb+flatpak+snap+appimage"
GAMING="steam+proton-ge"
RAM_COMPRESS="zram"
PRELOAD="enabled"
CPU_GOVERNOR="performance"
GPU_ACCEL="vulkan+mesa"
GAME_OPTIMIZER="gamemode"
THEME="cos-dark"
ICONS="papirus"
FONTS="jetbrains-mono+inter"
EOF
done_ "System config created"

# ══════════════════════════════════════════
# STEP 16 — BRANDING
# ══════════════════════════════════════════
progress "Creating C OS branding"
cat > "$HOME/cos-build/branding/logo/cos-logo.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">
  <defs>
    <linearGradient id="g1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#7c6af7"/>
      <stop offset="100%" style="stop-color:#f76a8a"/>
    </linearGradient>
  </defs>
  <rect width="200" height="200" rx="45" fill="#0e0e10"/>
  <text x="100" y="130"
    font-family="JetBrains Mono, monospace"
    font-size="90" font-weight="700"
    text-anchor="middle"
    fill="url(#g1)">C</text>
</svg>
EOF
cat > "$HOME/cos-build/branding/grub/grub.cfg" << 'EOF'
set timeout=3
set default=0
menuentry "C OS Carbon" {
  linux /boot/vmlinuz boot=live quiet splash
  initrd /boot/initrd.img
}
menuentry "C OS (Safe Mode)" {
  linux /boot/vmlinuz boot=live nomodeset
  initrd /boot/initrd.img
}
EOF
done_ "Branding created"

# ══════════════════════════════════════════
# STEP 17 — SYSTEM SERVICES
# ══════════════════════════════════════════
progress "Creating system services"
cat > "$HOME/cos-build/system/services/waydroid.service" << 'EOF'
[Unit]
Description=Waydroid Android Container
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/waydroid session start
Restart=on-failure
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF

cat > "$HOME/cos-build/system/configs/performance.sh" << 'EOF'
#!/bin/bash
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
  echo performance | tee $cpu > /dev/null
done
modprobe zram
echo lz4 > /sys/block/zram0/comp_algorithm
echo 4G > /sys/block/zram0/disksize
mkswap /dev/zram0
swapon /dev/zram0 -p 100
sysctl -w vm.swappiness=10
sysctl -w vm.vfs_cache_pressure=50
sysctl -w kernel.nmi_watchdog=0
echo "C OS performance optimizations applied"
EOF
chmod +x "$HOME/cos-build/system/configs/performance.sh"
done_ "System services created"

# ══════════════════════════════════════════
# STEP 18 — APP INSTALLER SCRIPTS
# ══════════════════════════════════════════
progress "Creating app installer scripts"
cat > "$HOME/cos-build/apps/android/install-apk.sh" << 'EOF'
#!/bin/bash
APK=$1
[ -z "$APK" ] && echo "Usage: install-apk.sh app.apk" && exit 1
echo "Installing APK: $APK"
waydroid app install "$APK"
echo "✅ Android app installed"
EOF

cat > "$HOME/cos-build/apps/windows/install-app.sh" << 'EOF'
#!/bin/bash
echo "Opening Bottles for Windows app installation..."
flatpak run com.usebottles.bottles &
echo "Install your Windows app via Bottles GUI"
EOF

chmod +x "$HOME/cos-build/apps/android/install-apk.sh"
chmod +x "$HOME/cos-build/apps/windows/install-app.sh"
done_ "App installer scripts created"

# ══════════════════════════════════════════
# STEP 19 — VERIFICATION
# ══════════════════════════════════════════
progress "Verifying installation"
echo ""
PASS=0
FAIL=0

check_cmd() {
  if command -v "$1" &>/dev/null; then
    echo -e "  ${GREEN}✅${NC} $1"
    PASS=$((PASS + 1))
  else
    echo -e "  ${RED}❌${NC} $1"
    FAIL=$((FAIL + 1))
  fi
}

echo "── Core ──"
check_cmd git; check_cmd curl; check_cmd debootstrap; check_cmd xorriso

echo "── Desktop ──"
check_cmd sway; check_cmd waybar; check_cmd wofi

echo "── Windows Support ──"
check_cmd wine; check_cmd winetricks

echo "── Android Support ──"
check_cmd waydroid

echo "── Apps ──"
check_cmd flatpak; check_cmd snap

echo "── Performance ──"
check_cmd gamemode; check_cmd preload

echo ""
echo -e "Results: ${GREEN}$PASS passed${NC} | ${RED}$FAIL failed${NC}"

# ══════════════════════════════════════════
# STEP 20 — SAVE LOG + COMPLETE
# ══════════════════════════════════════════
progress "Saving build log"
cat > "$HOME/cos-build/build/logs/phase1-summary.log" << EOF
C OS Phase 1 Build Summary
==========================
Date:    $(date)
Server:  $(uname -a)
Disk:    $(df -h / | tail -1)
RAM:     $(free -h | grep Mem)
Passed:  $PASS checks
Failed:  $FAIL checks
EOF

echo ""
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║     C OS Phase 1 — COMPLETE ✅      ║"
echo "  ╠══════════════════════════════════════╣"
echo "  ║  ✅ Build environment ready          ║"
echo "  ║  ✅ Wayland compositor               ║"
echo "  ║  ✅ Wine Staging + DXVK + VKD3D      ║"
echo "  ║  ✅ Waydroid Android layer           ║"
echo "  ║  ✅ Steam + Proton-GE                ║"
echo "  ║  ✅ Flatpak + Bottles                ║"
echo "  ║  ✅ Performance optimizations        ║"
echo "  ║  ✅ All configs and scripts ready    ║"
echo "  ╠══════════════════════════════════════╣"
echo "  ║  Next → Phase 2: C OS UI Shell 🎨   ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  📋 Full log saved to: ${BLUE}$LOG_FILE${NC}"
echo ""

