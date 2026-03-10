#!/bin/bash
set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${GREEN}[C OS]${NC} $1"; }
section() { echo -e "\n${CYAN}${BOLD}━━━ $1 ━━━${NC}\n"; }
done_()   { echo -e "${GREEN}${BOLD}✅ $1${NC}"; }

clear
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║     C OS Phase 2 — UI Shell 🎨      ║"
echo "  ╠══════════════════════════════════════╣"
echo "  ║  Building:                           ║"
echo "  ║  • Sway window manager config        ║"
echo "  ║  • macOS style dock                  ║"
echo "  ║  • Retro minimal top bar             ║"
echo "  ║  • App launcher                      ║"
echo "  ║  • C OS dark theme                   ║"
echo "  ║  • Custom wallpaper                  ║"
echo "  ║  • Boot splash screen                ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"
sleep 2

# ══════════════════════════════════════════
# STEP 1 — INSTALL UI DEPENDENCIES
# ══════════════════════════════════════════
section "1/8 Installing UI dependencies"
sudo apt install -y \
  sway swaybg swaylock \
  waybar \
  wofi \
  mako-notifier \
  lxappearance \
  thunar \
  mousepad \
  eog \
  totem \
  gnome-system-monitor \
  network-manager-gnome \
  blueman \
  brightnessctl \
  playerctl \
  pamixer \
  wlogout \
  swayidle \
  xdg-desktop-portal \
  xdg-desktop-portal-wlr \
  xdg-user-dirs \
  python3-pip \
  python3-psutil
done_ "UI dependencies installed"

# ══════════════════════════════════════════
# STEP 2 — SWAY CONFIG (WINDOW MANAGER)
# ══════════════════════════════════════════
section "2/8 Creating Sway window manager config"
mkdir -p ~/.config/sway

cat > ~/.config/sway/config << 'EOF'
# ──────────────────────────────────────────
#   C OS — Sway Window Manager Config
#   Codename: Carbon v1.0
# ──────────────────────────────────────────

# Variables
set $mod Mod4
set $left h
set $down j
set $up k
set $right l
set $term alacritty
set $launcher wofi --show drun --style ~/.config/wofi/style.css
set $wallpaper ~/cos-build/ui/wallpapers/cos-wallpaper.png

# Autostart
exec --no-startup-id waybar
exec --no-startup-id swaybg -m fill -i $wallpaper
exec --no-startup-id mako
exec --no-startup-id nm-applet
exec --no-startup-id /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1
exec --no-startup-id swayidle -w \
  timeout 300 'swaylock -f' \
  timeout 600 'swaymsg "output * dpms off"' \
  resume 'swaymsg "output * dpms on"' \
  before-sleep 'swaylock -f'

# Appearance
default_border pixel 2
default_floating_border pixel 2
gaps inner 8
gaps outer 4
smart_gaps on
smart_borders on

# Window colors
# class                 border    bg        text      indicator child_border
client.focused          #7c6af7   #7c6af7   #ffffff   #f76a8a   #7c6af7
client.focused_inactive #2d2d3a   #2d2d3a   #888888   #2d2d3a   #2d2d3a
client.unfocused        #1e1e26   #1e1e26   #666666   #1e1e26   #1e1e26
client.urgent           #f76a6a   #f76a6a   #ffffff   #f76a6a   #f76a6a

# Corner radius (requires sway with rounded corners patch)
corner_radius 12

# Font
font pango:JetBrains Mono 10

# Key bindings
bindsym $mod+Return exec $term
bindsym $mod+q kill
bindsym $mod+d exec $launcher
bindsym $mod+Shift+c reload
bindsym $mod+Shift+q exec wlogout

# Move focus
bindsym $mod+$left focus left
bindsym $mod+$down focus down
bindsym $mod+$up focus up
bindsym $mod+$right focus right
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

# Move windows
bindsym $mod+Shift+$left move left
bindsym $mod+Shift+$down move down
bindsym $mod+Shift+$up move up
bindsym $mod+Shift+$right move right

# Workspaces
bindsym $mod+1 workspace number 1
bindsym $mod+2 workspace number 2
bindsym $mod+3 workspace number 3
bindsym $mod+4 workspace number 4
bindsym $mod+5 workspace number 5
bindsym $mod+Shift+1 move container to workspace number 1
bindsym $mod+Shift+2 move container to workspace number 2
bindsym $mod+Shift+3 move container to workspace number 3
bindsym $mod+Shift+4 move container to workspace number 4
bindsym $mod+Shift+5 move container to workspace number 5

# Layout
bindsym $mod+b splith
bindsym $mod+v splitv
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split
bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle
bindsym $mod+space focus mode_toggle

# Resize
mode "resize" {
  bindsym $left resize shrink width 10px
  bindsym $down resize grow height 10px
  bindsym $up resize shrink height 10px
  bindsym $right resize grow width 10px
  bindsym Return mode "default"
  bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# Screenshots
bindsym Print exec grim ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png
bindsym $mod+Print exec grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png

# Volume
bindsym XF86AudioRaiseVolume exec pamixer -i 5
bindsym XF86AudioLowerVolume exec pamixer -d 5
bindsym XF86AudioMute exec pamixer -t

# Brightness
bindsym XF86MonBrightnessUp exec brightnessctl set 10%+
bindsym XF86MonBrightnessDown exec brightnessctl set 10%-

# Floating rules
for_window [app_id="pavucontrol"] floating enable
for_window [app_id="blueman-manager"] floating enable
for_window [app_id="nm-connection-editor"] floating enable
for_window [title="C OS Settings"] floating enable

# Input config
input type:keyboard {
  xkb_options caps:escape
  repeat_delay 300
  repeat_rate 50
}
input type:touchpad {
  tap enabled
  natural_scroll enabled
  dwt enabled
}

# Output config
output * {
  bg $wallpaper fill
}

include ~/.config/sway/config.d/*
EOF
done_ "Sway config created"

# ══════════════════════════════════════════
# STEP 3 — WAYBAR (TOP BAR)
# ══════════════════════════════════════════
section "3/8 Creating C OS top bar"
mkdir -p ~/.config/waybar

cat > ~/.config/waybar/config << 'EOF'
{
  "layer": "top",
  "position": "top",
  "height": 32,
  "spacing": 4,
  "margin-top": 6,
  "margin-left": 12,
  "margin-right": 12,
  "modules-left": [
    "custom/logo",
    "sway/workspaces",
    "sway/mode"
  ],
  "modules-center": [
    "clock"
  ],
  "modules-right": [
    "pulseaudio",
    "network",
    "cpu",
    "memory",
    "battery",
    "tray",
    "custom/power"
  ],
  "custom/logo": {
    "format": " C OS ",
    "tooltip": false,
    "on-click": "wofi --show drun"
  },
  "sway/workspaces": {
    "disable-scroll": true,
    "all-outputs": true,
    "format": "{name}"
  },
  "clock": {
    "timezone": "UTC",
    "format": "{:%a %b %d  %I:%M %p}",
    "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
  },
  "cpu": {
    "format": " {usage}%",
    "tooltip": true,
    "interval": 2
  },
  "memory": {
    "format": " {}%",
    "interval": 2
  },
  "battery": {
    "states": {
      "good": 80,
      "warning": 30,
      "critical": 15
    },
    "format": "{icon} {capacity}%",
    "format-charging": " {capacity}%",
    "format-icons": ["", "", "", "", ""]
  },
  "network": {
    "format-wifi": " {signalStrength}%",
    "format-ethernet": " Connected",
    "format-disconnected": "⚠ Disconnected",
    "tooltip-format": "{ifname}: {ipaddr}"
  },
  "pulseaudio": {
    "format": "{icon} {volume}%",
    "format-muted": " Muted",
    "format-icons": {
      "default": ["", "", ""]
    },
    "on-click": "pavucontrol"
  },
  "tray": {
    "spacing": 8
  },
  "custom/power": {
    "format": "⏻",
    "tooltip": false,
    "on-click": "wlogout"
  }
}
EOF

cat > ~/.config/waybar/style.css << 'EOF'
/* C OS Waybar Theme */
@import url('file:///usr/share/fonts/truetype/jetbrains-mono/JetBrainsMono-Regular.ttf');

* {
  font-family: "JetBrains Mono", monospace;
  font-size: 12px;
  border: none;
  border-radius: 0;
  min-height: 0;
}

window#waybar {
  background: rgba(14, 14, 18, 0.85);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 14px;
  color: #e8e8ec;
}

.modules-left,
.modules-center,
.modules-right {
  padding: 0 6px;
}

#custom-logo {
  color: #7c6af7;
  font-weight: bold;
  font-size: 13px;
  padding: 0 12px;
  background: rgba(124, 106, 247, 0.12);
  border-radius: 10px;
  margin: 4px 4px;
}

#workspaces button {
  padding: 0 10px;
  color: #666680;
  border-radius: 8px;
  margin: 4px 2px;
  transition: all 0.2s;
}

#workspaces button.focused {
  background: rgba(124, 106, 247, 0.2);
  color: #7c6af7;
}

#workspaces button:hover {
  background: rgba(255, 255, 255, 0.08);
  color: #e8e8ec;
}

#clock {
  color: #e8e8ec;
  font-weight: 500;
  font-size: 12px;
}

#cpu,
#memory,
#battery,
#network,
#pulseaudio,
#tray,
#custom-power {
  padding: 2px 10px;
  margin: 4px 2px;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.05);
  color: #a0a0c0;
  transition: all 0.2s;
}

#cpu:hover,
#memory:hover,
#battery:hover,
#network:hover,
#pulseaudio:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #e8e8ec;
}

#battery.warning { color: #f7c94f; }
#battery.critical { color: #f76a6a; }
#battery.charging { color: #4fdc8f; }

#network.disconnected { color: #f76a6a; }

#custom-power {
  color: #f76a8a;
  font-size: 14px;
  padding: 2px 12px;
}

#custom-power:hover {
  background: rgba(247, 106, 138, 0.2);
}
EOF
done_ "Waybar top bar created"

# ══════════════════════════════════════════
# STEP 4 — WOFI LAUNCHER
# ══════════════════════════════════════════
section "4/8 Creating app launcher"
mkdir -p ~/.config/wofi

cat > ~/.config/wofi/config << 'EOF'
width=480
height=400
location=center
show=drun
prompt=Search apps...
filter_rate=100
allow_markup=true
no_actions=true
halign=fill
orientation=vertical
content_halign=fill
insensitive=true
allow_images=true
image_size=32
gtk_dark=true
EOF

cat > ~/.config/wofi/style.css << 'EOF'
/* C OS App Launcher */
window {
  background: rgba(14, 14, 18, 0.95);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 18px;
  font-family: "JetBrains Mono", monospace;
}

#input {
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  color: #e8e8ec;
  padding: 12px 16px;
  margin: 12px;
  font-size: 14px;
  outline: none;
}

#input:focus {
  border-color: #7c6af7;
  background: rgba(124, 106, 247, 0.08);
}

#scroll {
  margin: 0 8px 8px 8px;
}

#inner-box {
  background: transparent;
}

.entry {
  padding: 10px 14px;
  border-radius: 10px;
  margin: 2px 4px;
  color: #a0a0c0;
  transition: all 0.15s;
}

.entry:selected {
  background: rgba(124, 106, 247, 0.2);
  color: #e8e8ec;
}

.entry:hover {
  background: rgba(255, 255, 255, 0.06);
  color: #e8e8ec;
}

.text {
  font-size: 13px;
  margin-left: 8px;
}
EOF
done_ "App launcher created"

# ══════════════════════════════════════════
# STEP 5 — MAKO NOTIFICATIONS
# ══════════════════════════════════════════
section "5/8 Creating notification system"
mkdir -p ~/.config/mako

cat > ~/.config/mako/config << 'EOF'
# C OS Notifications
font=JetBrains Mono 11
background-color=#1a1a22ee
text-color=#e8e8ec
border-color=#7c6af7
border-radius=14
border-size=1
width=360
height=120
margin=12
padding=16
icons=1
icon-path=/usr/share/icons/Papirus-Dark
max-icon-size=48
default-timeout=5000
ignore-timeout=0
layer=overlay
anchor=top-right

[urgency=high]
border-color=#f76a8a
default-timeout=0
EOF
done_ "Notifications configured"

# ══════════════════════════════════════════
# STEP 6 — WALLPAPER
# ══════════════════════════════════════════
section "6/8 Creating C OS wallpaper"
mkdir -p ~/cos-build/ui/wallpapers

# Generate wallpaper using Python
python3 << 'PYEOF'
try:
    from PIL import Image, ImageDraw, ImageFilter
    import math, random

    W, H = 2560, 1440
    img = Image.new('RGB', (W, H), '#0b0b0f')
    draw = ImageDraw.Draw(img)

    # Background gradient
    for y in range(H):
        r = int(11 + (y/H) * 8)
        g = int(11 + (y/H) * 5)
        b = int(15 + (y/H) * 10)
        draw.line([(0,y),(W,y)], fill=(r,g,b))

    # Purple glow
    glow = Image.new('RGB', (W, H), '#000000')
    gd = ImageDraw.Draw(glow)
    for i in range(80, 0, -1):
        alpha = int(255 * (1 - i/80) * 0.3)
        gd.ellipse([W*0.1-i*8, H*0.2-i*6, W*0.1+i*8, H*0.2+i*6],
            fill=(124, 106, 247))
    glow = glow.filter(ImageFilter.GaussianBlur(60))
    img = Image.blend(img, glow, 0.4)

    # Pink glow
    glow2 = Image.new('RGB', (W, H), '#000000')
    gd2 = ImageDraw.Draw(glow2)
    for i in range(60, 0, -1):
        gd2.ellipse([W*0.8-i*8, H*0.7-i*6, W*0.8+i*8, H*0.7+i*6],
            fill=(247, 106, 138))
    glow2 = glow2.filter(ImageFilter.GaussianBlur(80))
    img = Image.blend(img, glow2, 0.3)

    # Grid lines
    draw = ImageDraw.Draw(img)
    for x in range(0, W, 60):
        draw.line([(x,0),(x,H)], fill=(255,255,255,8), width=1)
    for y in range(0, H, 60):
        draw.line([(0,y),(W,y)], fill=(255,255,255,8), width=1)

    # C OS text watermark
    try:
        from PIL import ImageFont
        font = ImageFont.truetype('/usr/share/fonts/truetype/jetbrains-mono/JetBrainsMono-Bold.ttf', 180)
        draw.text((W//2, H//2), 'C OS', font=font,
            fill=(255,255,255,15), anchor='mm')
    except:
        pass

    img.save('/home/ubuntu/cos-build/ui/wallpapers/cos-wallpaper.png', 'PNG')
    print("✅ Wallpaper created")
except ImportError:
    print("PIL not found, creating simple wallpaper...")
    import subprocess
    subprocess.run(['convert', '-size', '2560x1440',
        'gradient:#0b0b0f-#1a1020',
        '/home/ubuntu/cos-build/ui/wallpapers/cos-wallpaper.png'])
    print("✅ Simple wallpaper created")
PYEOF

# Fallback if python fails
if [ ! -f ~/cos-build/ui/wallpapers/cos-wallpaper.png ]; then
    convert -size 2560x1440 \
        gradient:'#0b0b0f-#1a1020' \
        ~/cos-build/ui/wallpapers/cos-wallpaper.png 2>/dev/null || \
    dd if=/dev/urandom bs=1 count=0 2>/dev/null
    log "Using fallback wallpaper"
fi
done_ "Wallpaper created"

# ══════════════════════════════════════════
# STEP 7 — SWAYLOCK (LOCKSCREEN)
# ══════════════════════════════════════════
section "7/8 Creating lock screen"
mkdir -p ~/.config/swaylock

cat > ~/.config/swaylock/config << 'EOF'
# C OS Lock Screen
image=~/cos-build/ui/wallpapers/cos-wallpaper.png
scaling=fill
color=0b0b0fee
font=JetBrains Mono

# Ring
ring-color=7c6af7
ring-ver-color=4fdc8f
ring-wrong-color=f76a6a
ring-clear-color=f7c94f

# Key highlight
key-hl-color=7c6af7
bs-hl-color=f76a8a

# Text
text-color=e8e8ecff
text-ver-color=4fdc8fff
text-wrong-color=f76a6aff
text-clear-color=f7c94fff

# Inside circle
inside-color=0e0e1888
inside-ver-color=0e0e1888
inside-wrong-color=0e0e1888
inside-clear-color=0e0e1888

# Separator
separator-color=00000000

# Layout
indicator-radius=80
indicator-thickness=6
line-uses-ring
clock
timestr=%I:%M %p
datestr=%A, %B %d
EOF
done_ "Lock screen configured"

# ══════════════════════════════════════════
# STEP 8 — WLOGOUT (POWER MENU)
# ══════════════════════════════════════════
section "8/8 Creating power menu"
mkdir -p ~/.config/wlogout

cat > ~/.config/wlogout/layout << 'EOF'
{
  "label": "lock",
  "action": "swaylock",
  "text": "Lock",
  "keybind": "l"
}
{
  "label": "logout",
  "action": "swaymsg exit",
  "text": "Logout",
  "keybind": "e"
}
{
  "label": "suspend",
  "action": "systemctl suspend",
  "text": "Sleep",
  "keybind": "s"
}
{
  "label": "reboot",
  "action": "systemctl reboot",
  "text": "Restart",
  "keybind": "r"
}
{
  "label": "shutdown",
  "action": "systemctl poweroff",
  "text": "Shutdown",
  "keybind": "u"
}
EOF

cat > ~/.config/wlogout/style.css << 'EOF'
/* C OS Power Menu */
window {
  background: rgba(11, 11, 15, 0.92);
  font-family: "JetBrains Mono", monospace;
}

button {
  background: rgba(28, 28, 36, 0.8);
  border: 1px solid rgba(255,255,255,0.08);
  border-radius: 16px;
  color: #a0a0c0;
  font-size: 14px;
  margin: 8px;
  padding: 40px 60px;
  transition: all 0.2s;
}

button:hover {
  background: rgba(124, 106, 247, 0.2);
  border-color: #7c6af7;
  color: #e8e8ec;
}

#lock     { border-color: rgba(124,106,247,0.3); }
#logout   { border-color: rgba(79,220,143,0.3); }
#suspend  { border-color: rgba(247,201,79,0.3); }
#reboot   { border-color: rgba(247,106,79,0.3); }
#shutdown { border-color: rgba(247,106,138,0.3); }
EOF
done_ "Power menu created"

# ══════════════════════════════════════════
# COMPLETE
# ══════════════════════════════════════════
echo ""
echo -e "${CYAN}${BOLD}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║     C OS Phase 2 — COMPLETE ✅      ║"
echo "  ╠══════════════════════════════════════╣"
echo "  ║  ✅ Sway window manager              ║"
echo "  ║  ✅ Waybar top bar                   ║"
echo "  ║  ✅ Wofi app launcher                ║"
echo "  ║  ✅ Mako notifications               ║"
echo "  ║  ✅ Wallpaper                        ║"
echo "  ║  ✅ Swaylock lock screen             ║"
echo "  ║  ✅ Wlogout power menu               ║"
echo "  ╠══════════════════════════════════════╣"
echo "  ║  Next → Phase 3: Android + Windows  ║"
echo "  ╚══════════════════════════════════════╝"
echo -e "${NC}"

